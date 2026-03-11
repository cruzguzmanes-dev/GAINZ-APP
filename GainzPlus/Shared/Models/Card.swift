import Foundation

struct Card: Identifiable, Codable, Hashable {
    let id: UUID
    var phrase: String
    var type: CardType
    var meaningEN: String
    var meaningES: String
    var exampleEN: String
    var exampleES: String
    var timesShown: Int
    var timesKnown: Int

    init(
        id: UUID = UUID(),
        phrase: String,
        type: CardType,
        meaningEN: String,
        meaningES: String,
        exampleEN: String,
        exampleES: String,
        timesShown: Int = 0,
        timesKnown: Int = 0
    ) {
        self.id = id
        self.phrase = phrase
        self.type = type
        self.meaningEN = meaningEN
        self.meaningES = meaningES
        self.exampleEN = exampleEN
        self.exampleES = exampleES
        self.timesShown = timesShown
        self.timesKnown = timesKnown
    }

    enum CardType: String, Codable, CaseIterable {
        case phrasalVerb = "phrasal"
        case idiom       = "idiom"
        case custom      = "custom"
        case fact        = "fact"

        var badgeLabel: String {
            switch self {
            case .phrasalVerb: return "PHRASAL VERB"
            case .idiom:       return "IDIOM"
            case .custom:      return "CUSTOM"
            case .fact:        return "FACT"
            }
        }

        var badgeColor: String {
            switch self {
            case .phrasalVerb: return "teal"
            case .idiom:       return "green"
            case .custom:      return "purple"
            case .fact:        return "orange"
            }
        }
    }

    var knowledgeRate: Double {
        guard timesShown > 0 else { return 0 }
        return Double(timesKnown) / Double(timesShown)
    }
}
