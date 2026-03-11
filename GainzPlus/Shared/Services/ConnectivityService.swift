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

    /// Envía el pack activo al Watch
    func sendActivePack(_ pack: Pack) {
        guard WCSession.default.isReachable else { return }
        guard let data = try? JSONEncoder().encode(pack) else { return }
        WCSession.default.sendMessageData(data, replyHandler: nil) { error in
            print("ConnectivityService sendActivePack error: \(error)")
        }
    }

    /// Envía todos los packs al Watch via transferUserInfo (background)
    func transferAllPacks(_ packs: [Pack]) {
        guard let data = try? JSONEncoder().encode(packs) else { return }
        WCSession.default.transferUserInfo(["packs": data])
    }
    
    func sendSessionToPhone(_ data: Data) {
        // Si el iPhone está abierto (foreground)
        if WCSession.default.isReachable {
            WCSession.default.sendMessageData(data, replyHandler: nil)
        } else {
            // Si el iPhone está en background, lo manda cuando pueda
            WCSession.default.transferUserInfo(["session": data])
        }
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
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    // Watch recibe pack activo (foreground)
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        guard let pack = try? JSONDecoder().decode(Pack.self, from: messageData) else { return }
        Task { @MainActor in
            PackStore.shared.setActivePack(pack)
        }
    }

    // Watch recibe todos los packs (background)
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        guard
            let data = userInfo["packs"] as? Data,
            let packs = try? JSONDecoder().decode([Pack].self, from: data)
        else { return }
        Task { @MainActor in
            // Merge: conserva packs de usuario, reemplaza defaults
            let userPacks = PackStore.shared.packs.filter(\.isUserCreated)
            PackStore.shared.packs = packs + userPacks
        }
    }
    
    

    // iOS only
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif
}
