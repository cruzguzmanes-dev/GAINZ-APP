import Foundation

// MARK: - PackStore + Supabase
// Agrega este extension a tu PackStore existente,
// o pega el método loadFromSupabase() dentro de la clase PackStore.

extension PackStore {

    /// Carga los packs remotos de Supabase y los mezcla con los locales del usuario.
    /// Llama esto en el init() o cuando el usuario quiera refrescar.
    func loadFromSupabase() async {
        syncState = .loading
        do {
            let remotePacks = try await SupabaseService.shared.fetchAllPacks()

            // Conserva packs creados por el usuario localmente
            let userPacks = packs.filter(\.isUserCreated)

            // Reemplaza los packs remotos (default) con la versión fresca de Supabase
            packs = remotePacks + userPacks

            // Si no hay pack activo, activa el primero
            if activePack == nil || !packs.contains(where: { $0.id == activePack?.id }) {
                activePack = packs.first
            }

            saveToDisk()
            // Envía solo el pack activo al Watch (un pack < 65 KB, cabe en updateApplicationContext)
            if let active = activePack {
                ConnectivityService.shared.transferActivePack(active)
            }
            syncState = .success(Date())
        } catch {
            print("SupabaseService error: \(error.localizedDescription)")
            syncState = .error(error.localizedDescription)
            // Si falla, los packs cargados de disco (o DefaultPacks) siguen disponibles
        }
    }

    /// Descarga un solo pack por su categoryID de Supabase (bajo demanda).
    func downloadPack(categoryID: String) async {
        do {
            let pack = try await SupabaseService.shared.fetchPack(categoryID: categoryID)

            // Reemplaza si ya existe, agrega si es nuevo
            if let idx = packs.firstIndex(where: { $0.id == pack.id }) {
                packs[idx] = pack
            } else {
                packs.append(pack)
            }
            saveToDisk()
        } catch {
            print("downloadPack error: \(error.localizedDescription)")
        }
    }
}
