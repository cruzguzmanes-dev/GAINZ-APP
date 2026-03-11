import Foundation
import Combine
@MainActor
final class SessionStore: ObservableObject {
    static let shared = SessionStore()

    @Published var sessions: [RestSession] = []

    private let key = "gainzplus.sessions"

    init() { load() }

    func save(_ session: RestSession) {
        sessions.insert(session, at: 0)   // más reciente primero
        persist()
    }

    // MARK: - Stats helpers

    var totalCardsToday: Int {
        sessionsToday.reduce(0) { $0 + $1.seenCount }
    }

    var streakDays: Int {
        var streak = 0
        var date = Calendar.current.startOfDay(for: Date())
        for _ in 0..<365 {
            let hasSession = sessions.contains {
                Calendar.current.isDate($0.date, inSameDayAs: date)
            }
            if hasSession {
                streak += 1
                date = Calendar.current.date(byAdding: .day, value: -1, to: date)!
            } else {
                break
            }
        }
        return streak
    }

    var sessionsThisWeek: [RestSession] {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return sessions.filter { $0.date >= start }
    }

    private var sessionsToday: [RestSession] {
        sessions.filter { Calendar.current.isDateInToday($0.date) }
    }

    // MARK: - Persistence

    private func persist() {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let saved = try? JSONDecoder().decode([RestSession].self, from: data)
        else { return }
        sessions = saved
    }
}
