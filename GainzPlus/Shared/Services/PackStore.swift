import Foundation
import Combine

@MainActor
final class PackStore: ObservableObject {
    static let shared = PackStore()

    @Published var packs: [Pack] = []
    @Published var activePack: Pack?

    // MARK: - Sync state
    enum SyncState: Equatable {
        case idle
        case loading
        case success(Date)
        case error(String)
    }
    @Published var syncState: SyncState = .idle

    private var shownCardIDs: Set<UUID> = []
    private let userDefaultsKey = "gainzplus.packs"
    private let activePackKey   = "gainzplus.activePack"

    init() {
        loadFromDisk()
        if packs.isEmpty {
            packs = DefaultPacks.all
        }
        if activePack == nil {
            activePack = packs.first
        }
        
        #if os(iOS)
        Task { await loadFromSupabase() }
        #endif
    }

    // MARK: - Card vending

    func nextCard(alternateType: Card.CardType? = nil) -> Card? {
        guard let pack = activePack, !pack.cards.isEmpty else { return nil }

        var candidates = pack.cards.filter { !shownCardIDs.contains($0.id) }

        // Alterna tipo para que no salgan dos iguales seguidas
        if let alt = alternateType {
            let opposite = candidates.filter { $0.type != alt }
            if !opposite.isEmpty { candidates = opposite }
        }

        // Si ya se mostraron todas, reinicia el ciclo
        if candidates.isEmpty {
            shownCardIDs.removeAll()
            candidates = pack.cards
        }

        guard let card = candidates.randomElement() else { return nil }
        shownCardIDs.insert(card.id)
        return card
    }

    // MARK: - Results

    func recordResult(cardID: UUID, knew: Bool) {
        guard
            let packIdx = packs.firstIndex(where: { $0.id == activePack?.id }),
            let cardIdx = packs[packIdx].cards.firstIndex(where: { $0.id == cardID })
        else { return }

        packs[packIdx].cards[cardIdx].timesShown += 1
        if knew { packs[packIdx].cards[cardIdx].timesKnown += 1 }

        // Refleja cambio en activePack también
        activePack = packs[packIdx]
        saveToDisk()
    }

    // MARK: - CRUD

    func setActivePack(_ pack: Pack) {
        activePack = pack
        shownCardIDs.removeAll()
        UserDefaults.standard.set(pack.id.uuidString, forKey: activePackKey)
    }

    func addUserPack(_ pack: Pack) {
        packs.append(pack)
        saveToDisk()
    }

    func updatePack(_ pack: Pack) {
        guard let idx = packs.firstIndex(where: { $0.id == pack.id }) else { return }
        packs[idx] = pack
        if activePack?.id == pack.id { activePack = pack }
        saveToDisk()
    }

    func deletePack(_ pack: Pack) {
        packs.removeAll { $0.id == pack.id }
        if activePack?.id == pack.id { activePack = packs.first }
        saveToDisk()
    }

    // MARK: - Persistence

     func saveToDisk() {
        if let data = try? JSONEncoder().encode(packs) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    private func loadFromDisk() {
        guard
            let data = UserDefaults.standard.data(forKey: userDefaultsKey),
            let saved = try? JSONDecoder().decode([Pack].self, from: data)
        else { return }

        packs = saved

        if let activeID = UserDefaults.standard.string(forKey: activePackKey),
           let uuid = UUID(uuidString: activeID),
           let found = packs.first(where: { $0.id == uuid }) {
            activePack = found
        }
    }
}
