import Foundation

// MARK: - Supabase DTOs (lo que llega del servidor)

fileprivate struct SupabaseCategory: Decodable {
    let id: String
    let name: String
    let emoji: String?
}

fileprivate struct SupabaseWord: Decodable {
    let id: String
    let category_id: String
    let word_en: String
    let definition_en: String?
    let examples_en: [String]?
    let meaning_es: String?
    let uses_es: [String]?
}

// MARK: - SupabaseService

final class SupabaseService {
    static let shared = SupabaseService()

    private let baseURL = Config.supabaseURL
    private let anonKey = Config.supabaseAnon

    private var headers: [String: String] {
        [
            "apikey": anonKey,
            "Authorization": "Bearer \(anonKey)"
        ]
    }

    // MARK: - Fetch all categories

    private func fetchCategories() async throws -> [SupabaseCategory] {
        let url = URL(string: "\(baseURL)/rest/v1/categories?select=*&order=created_at.asc")!
        var request = URLRequest(url: url)
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw SupabaseError.badResponse
        }
        return try JSONDecoder().decode([SupabaseCategory].self, from: data)
    }

    // MARK: - Fetch words by category

    private func fetchWords(categoryID: String) async throws -> [SupabaseWord] {
        let encoded = categoryID.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? categoryID
        let url = URL(string: "\(baseURL)/rest/v1/words?category_id=eq.\(encoded)&select=*&order=created_at.asc")!
        var request = URLRequest(url: url)
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw SupabaseError.badResponse
        }
        return try JSONDecoder().decode([SupabaseWord].self, from: data)
    }

    // MARK: - Fetch full pack (category + words → Pack)

    func fetchPack(categoryID: String) async throws -> Pack {
        let encoded = categoryID.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? categoryID
        let url = URL(string: "\(baseURL)/rest/v1/categories?id=eq.\(encoded)&select=*")!
        var request = URLRequest(url: url)
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw SupabaseError.badResponse
        }
        let cats = try JSONDecoder().decode([SupabaseCategory].self, from: data)

        guard let cat = cats.first else {
            throw SupabaseError.categoryNotFound
        }

        let words = try await fetchWords(categoryID: categoryID)
        return mapToPack(category: cat, words: words)
    }

    // MARK: - Fetch all packs

    func fetchAllPacks() async throws -> [Pack] {
        let categories = try await fetchCategories()

        return try await withThrowingTaskGroup(of: Pack.self) { group in
            for cat in categories {
                group.addTask {
                    let words = try await self.fetchWords(categoryID: cat.id)
                    return self.mapToPack(category: cat, words: words)
                }
            }
            var packs: [Pack] = []
            for try await pack in group {
                packs.append(pack)
            }
            return packs.sorted { $0.title < $1.title }
        }
    }

    // MARK: - Mapping: Supabase → Pack/Card

    private func mapToPack(category: SupabaseCategory, words: [SupabaseWord]) -> Pack {
        let cards = words.map { word -> Card in
            // Toma el primer ejemplo de cada array (o vacío si no hay)
            let exampleEN = word.examples_en?.first ?? ""
            let exampleES = word.uses_es?.first ?? ""

            return Card(
                id: UUID(uuidString: word.id) ?? UUID(),
                phrase: word.word_en,
                type: .custom,
                meaningEN: word.definition_en ?? "",
                meaningES: word.meaning_es ?? "",
                exampleEN: exampleEN,
                exampleES: exampleES
            )
        }

        return Pack(
            id: UUID(uuidString: category.id) ?? UUID(),
            title: category.name,
            description: "",
            emoji: category.emoji ?? "📦",
            language: .english,
            isPremium: false,
            isUserCreated: false,
            cards: cards
        )
    }
}

// MARK: - Errors

enum SupabaseError: LocalizedError {
    case badResponse
    case categoryNotFound

    var errorDescription: String? {
        switch self {
        case .badResponse:      return "Error al conectar con Supabase"
        case .categoryNotFound: return "Categoría no encontrada"
        }
    }
}

