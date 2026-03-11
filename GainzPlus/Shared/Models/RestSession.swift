import Foundation

struct CardResult: Codable, Identifiable {
    let id: UUID
    let cardID: UUID
    let phrase: String
    let knew: Bool
    let timestamp: Date

    init(cardID: UUID, phrase: String, knew: Bool) {
        self.id = UUID()
        self.cardID = cardID
        self.phrase = phrase
        self.knew = knew
        self.timestamp = Date()
    }
}

struct RestSession: Identifiable, Codable {
    let id: UUID
    let date: Date
    let restDuration: Int       // segundos elegidos
    let packID: UUID?
    var cardResults: [CardResult]

    init(restDuration: Int, packID: UUID?, cardResults: [CardResult] = []) {
        self.id = UUID()
        self.date = Date()
        self.restDuration = restDuration
        self.packID = packID
        self.cardResults = cardResults
    }

    var knownCount: Int { cardResults.filter(\.knew).count }
    var seenCount: Int  { cardResults.count }

    var knowledgeRate: Double {
        guard seenCount > 0 else { return 0 }
        return Double(knownCount) / Double(seenCount)
    }
}
