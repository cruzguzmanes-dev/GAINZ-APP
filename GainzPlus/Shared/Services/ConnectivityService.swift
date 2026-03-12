import Foundation
import WatchConnectivity
import Combine

final class ConnectivityService: NSObject, ObservableObject {
    static let shared = ConnectivityService()

    @Published var isReachable: Bool = false

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - iPhone → Watch

    /// Envía el pack activo al Watch (foreground, reachable)
    func sendActivePack(_ pack: Pack) {
        guard WCSession.default.isReachable else { return }
        guard let data = try? JSONEncoder().encode(pack) else { return }
        WCSession.default.sendMessageData(data, replyHandler: nil) { error in
            print("ConnectivityService sendActivePack error: \(error)")
        }
    }

    /// Envía el pack activo al Watch vía updateApplicationContext.
    /// Solo enviamos UN pack para mantenernos bajo el límite de 65 KB.
    /// Este contexto persiste entre lanzamientos del Watch app.
    func transferActivePack(_ pack: Pack) {
        #if os(iOS)
        print("transferActivePack: isWatchAppInstalled=\(WCSession.default.isWatchAppInstalled) isPaired=\(WCSession.default.isPaired) activationState=\(WCSession.default.activationState.rawValue)")
        #endif

        guard let data = try? JSONEncoder().encode(pack) else { return }
        do {
            try WCSession.default.updateApplicationContext(["activePack": data])
            print("transferActivePack: context updated OK (\(data.count) bytes)")
        } catch {
            print("transferActivePack context error: \(error.localizedDescription) — usando transferUserInfo como fallback")
            WCSession.default.transferUserInfo(["activePack": data])
        }
    }

    /// Compatibilidad: internamente solo persiste el pack activo.
    func transferAllPacks(_ packs: [Pack]) {
        guard let first = packs.first else { return }
        transferActivePack(first)
    }

    // MARK: - Watch → iPhone

    /// Envía la sesión al iPhone.
    /// Siempre usa transferUserInfo para garantizar la entrega,
    /// incluso si la app del iPhone está en background.
    func sendSessionToPhone(_ data: Data) {
        let state = WCSession.default.activationState
        print("sendSessionToPhone: activationState=\(state.rawValue) isReachable=\(WCSession.default.isReachable) bytes=\(data.count)")
        guard state == .activated else {
            print("sendSessionToPhone: ⚠️ sesión no activada — datos perdidos")
            return
        }
        WCSession.default.transferUserInfo(["session": data])
        print("sendSessionToPhone: transferUserInfo encolado ✓")
    }

    // MARK: - Pull: Watch pide packs al iPhone

    /// Llamar desde el Watch para obtener los packs más recientes del iPhone.
    /// Primero aplica el contexto en caché (instantáneo); si el iPhone
    /// está en foreground, hace una petición en vivo para obtener la versión actual.
    func requestPacksFromPhone() {
        // 1. Aplica contexto ya almacenado (no requiere conexión)
        let cached = WCSession.default.receivedApplicationContext
        if !cached.isEmpty {
            applyReceivedContext(cached)
        }

        // 2. Si el iPhone está reachable, pide la versión más fresca
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(["request": "packs"], replyHandler: { [weak self] reply in
            self?.applyReceivedContext(reply)
        }, errorHandler: { error in
            print("requestPacksFromPhone error: \(error)")
        })
    }

    // MARK: - Pull: iPhone pide sesiones al Watch

    /// Llamar desde el iPhone para obtener el historial de sesiones del Watch.
    /// Solo funciona cuando el Watch está reachable (app en foreground).
    func requestSessionsFromWatch(completion: @escaping ([RestSession]) -> Void) {
        print("requestSessionsFromWatch: isReachable=\(WCSession.default.isReachable) activationState=\(WCSession.default.activationState.rawValue)")
        guard WCSession.default.isReachable else {
            print("requestSessionsFromWatch: ⚠️ Watch not reachable — usa transferUserInfo como fallback")
            completion([])
            return
        }
        WCSession.default.sendMessage(["request": "sessions"], replyHandler: { reply in
            print("requestSessionsFromWatch: reply recibido keys=\(reply.keys.joined(separator: ","))")
            guard
                let data     = reply["sessions"] as? Data,
                let sessions = try? JSONDecoder().decode([RestSession].self, from: data)
            else {
                print("requestSessionsFromWatch: ❌ falló decodificar sesiones")
                return
            }
            print("requestSessionsFromWatch: \(sessions.count) sesiones recibidas del Watch ✓")
            Task { @MainActor in completion(sessions) }
        }, errorHandler: { error in
            print("requestSessionsFromWatch error: \(error.localizedDescription)")
        })
    }
}

// MARK: - WCSessionDelegate

extension ConnectivityService: WCSessionDelegate {

    func session(_ session: WCSession,
                 activationDidCompleteWith state: WCSessionActivationState,
                 error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }

        // Bug 3 fix: cuando el Watch activa la sesión, aplica
        // el contexto que ya existe (enviado mientras el Watch estaba cerrado)
        #if os(watchOS)
        let ctx = session.receivedApplicationContext
        if !ctx.isEmpty {
            applyReceivedContext(ctx)
        }
        #endif
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    // iOS only: se dispara cuando la Watch app se instala/desinstala o
    // cuando el Watch se empareja/desempareja. Aprovechamos para enviar
    // el pack activo en cuanto el Watch app esté disponible.
    #if os(iOS)
    func sessionWatchStateDidChange(_ session: WCSession) {
        guard session.isWatchAppInstalled else { return }
        Task { @MainActor in
            if let pack = PackStore.shared.activePack {
                self.transferActivePack(pack)
                print("sessionWatchStateDidChange: Watch app detectada — pack enviado")
            }
        }
    }
    #endif

    // Watch recibe pack activo en foreground (botón sync del iPhone)
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        guard let pack = try? JSONDecoder().decode(Pack.self, from: messageData) else { return }
        Task { @MainActor in
            PackStore.shared.setActivePack(pack)
        }
    }

    // Request-Reply: responde peticiones del Watch (iPhone) o del iPhone (Watch)
    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any],
                 replyHandler: @escaping ([String: Any]) -> Void) {
        guard let request = message["request"] as? String else {
            replyHandler([:])
            return
        }

        switch request {

        case "packs":
            // iPhone → devuelve solo el pack activo (no todos, para no superar 65 KB)
            #if os(iOS)
            Task { @MainActor in
                if let pack = PackStore.shared.activePack,
                   let data = try? JSONEncoder().encode(pack) {
                    replyHandler(["activePack": data])
                } else {
                    replyHandler([:])
                }
            }
            #else
            replyHandler([:])
            #endif

        case "sessions":
            // Watch → devuelve sus sesiones al iPhone
            #if os(watchOS)
            Task { @MainActor in
                let sessions = SessionStore.shared.sessions
                print("didReceiveMessage sessions: Watch tiene \(sessions.count) sesiones guardadas")
                if let data = try? JSONEncoder().encode(sessions) {
                    replyHandler(["sessions": data])
                    print("didReceiveMessage sessions: respondido con \(data.count) bytes ✓")
                } else {
                    print("didReceiveMessage sessions: ❌ falló encodear sesiones")
                    replyHandler([:])
                }
            }
            #else
            replyHandler([:])
            #endif

        default:
            replyHandler([:])
        }
    }

    // Bug 1 fix: recibe el contexto más reciente (updateApplicationContext)
    func session(_ session: WCSession,
                 didReceiveApplicationContext applicationContext: [String: Any]) {
        applyReceivedContext(applicationContext)
    }

    // Bug 2 fix: fallback de transferUserInfo también actualiza activePack
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        // Sesión del Watch → iPhone
        if let sessionData = userInfo["session"] as? Data {
            print("didReceiveUserInfo: recibidos \(sessionData.count) bytes de sesión del Watch")
            guard let restSession = try? JSONDecoder().decode(RestSession.self, from: sessionData) else {
                print("didReceiveUserInfo: ❌ falló decodificar RestSession")
                return
            }
            Task { @MainActor in
                SessionStore.shared.save(restSession)
                print("didReceiveUserInfo: sesión guardada en iPhone ✓ (total: \(SessionStore.shared.sessions.count))")
            }
            return
        }

        // Packs del iPhone → Watch (fallback)
        applyReceivedContext(userInfo)
    }

    // iOS only
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif
}

// MARK: - Helpers

private extension ConnectivityService {

    /// Aplica contexto recibido del iPhone.
    /// Soporta dos formatos:
    ///   • "activePack": Data  — solo el pack activo (nuevo, compacto, < 65 KB)
    ///   • "packs": Data       — lista completa (legacy, podría superar el límite)
    func applyReceivedContext(_ context: [String: Any]) {

        // ── Formato nuevo: un solo pack activo ──────────────────────────────
        if let data = context["activePack"] as? Data,
           let pack = try? JSONDecoder().decode(Pack.self, from: data) {
            Task { @MainActor in
                // Añade o actualiza el pack en la lista local
                if let idx = PackStore.shared.packs.firstIndex(where: { $0.id == pack.id }) {
                    PackStore.shared.packs[idx] = pack
                } else {
                    // Insertar al principio para que sea el primero visible
                    PackStore.shared.packs.insert(pack, at: 0)
                }
                PackStore.shared.setActivePack(pack)
                PackStore.shared.saveToDisk()
                print("applyReceivedContext: activePack '\(pack.title)' aplicado ✓")
            }
            return
        }

        // ── Formato legacy: lista completa de packs ─────────────────────────
        guard
            let data  = context["packs"] as? Data,
            let packs = try? JSONDecoder().decode([Pack].self, from: data)
        else { return }

        Task { @MainActor in
            let userPacks = PackStore.shared.packs.filter(\.isUserCreated)
            let merged    = packs + userPacks
            PackStore.shared.packs = merged

            let activeStillExists = merged.contains {
                $0.id == PackStore.shared.activePack?.id
            }
            if !activeStillExists, let first = merged.first {
                PackStore.shared.setActivePack(first)
            }
            PackStore.shared.saveToDisk()
        }
    }
}
