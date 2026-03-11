import Foundation
import SwiftUI
import Combine
import WatchKit

@MainActor
final class SessionViewModel: ObservableObject {

    // MARK: - State machine
    enum AppState: Equatable {
        case picker
        case timer
        case card
        case timeout    // timer llegó a 0 de forma natural
        case summary
    }

    @Published var appState: AppState = .picker

    // Timer
    @Published var timeRemaining: Int = 90
    @Published var totalTime: Int = 90

    // Card
    @Published var currentCard: Card?
    @Published var isTranslationRevealed: Bool = false

    // Summary
    private(set) var cardResults: [CardResult] = []
    private var cardsSeen: Int = 0

    // Task-based timer — sigue corriendo aunque se pase a CardView
    private var timerTask: Task<Void, Never>?

    private let packStore: PackStore
    private let sessionStore: SessionStore

    // MARK: - Init
    init(packStore: PackStore = .shared, sessionStore: SessionStore = .shared) {
        self.packStore = packStore
        self.sessionStore = sessionStore
    }

    // MARK: - Timer

    func startRest(seconds: Int) {
        totalTime     = seconds
        timeRemaining = seconds
        cardResults   = []
        cardsSeen     = 0
        currentCard   = packStore.nextCard()
        appState      = .timer

        timerTask?.cancel()
        timerTask = Task {
            do {
                repeat {
                    try await Task.sleep(for: .seconds(1))
                    timeRemaining -= 1
                } while timeRemaining > 0

                // Llegó a 0 — solo actuar si aún estamos en timer o card
                guard appState == .timer || appState == .card else { return }
                WKInterfaceDevice.current().play(.notification)
                appState = .timeout
                try await Task.sleep(for: .seconds(2.5))
                appState = .picker

            } catch {
                // Cancelado por reset() o al llegar a summary — no hacer nada
            }
        }
    }

    // El timer sigue corriendo en background para que el progress bar
    // de CardView esté sincronizado y el timeout dispare correctamente.
    func skipToCard() {
        revealCard()
    }

    // MARK: - Card

    private func revealCard() {
        isTranslationRevealed = false
        cardsSeen += 1
        appState = .card
    }

    func toggleTranslation() {
        isTranslationRevealed.toggle()
    }

    func submitResult(knew: Bool) {
        guard let card = currentCard else { return }

        cardResults.append(CardResult(
            cardID: card.id,
            phrase: card.phrase,
            knew: knew
        ))
        packStore.recordResult(cardID: card.id, knew: knew)

        if cardsSeen >= 3 {
            timerTask?.cancel()     // ya terminó la sesión, cancelar timer
            timerTask = nil
            saveSession()
            appState = .summary
        } else {
            currentCard = packStore.nextCard(alternateType: card.type)
            isTranslationRevealed = false
            appState = .card
        }
    }

    func reset() {
        timerTask?.cancel()
        timerTask = nil
        cardResults   = []
        cardsSeen     = 0
        currentCard   = nil
        appState      = .picker
    }

    // MARK: - Computed

    var ringProgress: Double {
        guard totalTime > 0 else { return 1 }
        return Double(timeRemaining) / Double(totalTime)
    }

    var ringColor: Color {
        ringProgress < 0.3 ? .pink : Color(red: 0.78, green: 0.96, blue: 0.35)
    }

    var knownCount: Int  { cardResults.filter(\.knew).count }
    var seenCount: Int   { cardResults.count }

    // MARK: - Persist

    private func saveSession() {
        let session = RestSession(
            restDuration: totalTime,
            packID: packStore.activePack?.id,
            cardResults: cardResults
        )
        sessionStore.save(session)

        if let data = try? JSONEncoder().encode(session) {
            ConnectivityService.shared.sendSessionToPhone(data)
        }
    }
}
