import Foundation
import Combine

// MARK: - CardDailyStat

struct CardDailyStat: Identifiable {
    let id: UUID          // cardID
    let phrase: String
    let results: [CardResult]   // todas las veces vista hoy

    var timesShown: Int    { results.count }
    var timesKnown: Int    { results.filter(\.knew).count }
    var isRepeated: Bool   { timesShown > 1 }
    var accuracy: Double   {
        guard timesShown > 0 else { return 0 }
        return Double(timesKnown) / Double(timesShown)
    }
    // true si la ÚLTIMA respuesta fue correcta
    var lastKnew: Bool     { results.last?.knew ?? false }
}

// MARK: - SessionStore

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

    // MARK: - Stats: hoy

    var totalCardsToday: Int {
        sessionsToday.reduce(0) { $0 + $1.seenCount }
    }

    /// Palabras únicas vistas hoy, con su historial del día
    var cardStatsToday: [CardDailyStat] {
        let allResults = sessionsToday.flatMap(\.cardResults)
        // Agrupa por cardID preservando orden de primera aparición
        var seen: [UUID: [CardResult]] = [:]
        var order: [UUID] = []
        for result in allResults {
            if seen[result.cardID] == nil { order.append(result.cardID) }
            seen[result.cardID, default: []].append(result)
        }
        return order.compactMap { id in
            guard let results = seen[id], let first = results.first else { return nil }
            return CardDailyStat(id: id, phrase: first.phrase, results: results)
        }
    }

    /// Solo las palabras vistas más de una vez hoy
    var repeatedCardsToday: [CardDailyStat] {
        cardStatsToday.filter(\.isRepeated)
    }

    /// Precisión global del día (0–1)
    var accuracyToday: Double {
        let all = sessionsToday.flatMap(\.cardResults)
        guard !all.isEmpty else { return 0 }
        return Double(all.filter(\.knew).count) / Double(all.count)
    }

    // MARK: - Stats: racha y semana

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
