import Foundation

struct Pack: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var description: String
    var emoji: String
    var language: Language
    var isPremium: Bool
    var isUserCreated: Bool
    var cards: [Card]

    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        emoji: String = "📦",
        language: Language = .english,
        isPremium: Bool = false,
        isUserCreated: Bool = false,
        cards: [Card] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.emoji = emoji
        self.language = language
        self.isPremium = isPremium
        self.isUserCreated = isUserCreated
        self.cards = cards
    }

    enum Language: String, Codable, CaseIterable {
        case english = "en"
        case spanish = "es"
        case french  = "fr"

        var displayName: String {
            switch self {
            case .english: return "English"
            case .spanish: return "Español"
            case .french:  return "Français"
            }
        }

        var flag: String {
            switch self {
            case .english: return "🇺🇸"
            case .spanish: return "🇲🇽"
            case .french:  return "🇫🇷"
            }
        }
    }

    var totalCards: Int { cards.count }

    var progress: Double {
        let shown = cards.filter { $0.timesShown > 0 }
        guard !shown.isEmpty else { return 0 }
        return Double(shown.count) / Double(cards.count)
    }
}
