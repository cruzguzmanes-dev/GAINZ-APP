import SwiftUI

@main
struct GainzApp: App {
    @StateObject private var packStore    = PackStore.shared
    @StateObject private var sessionStore = SessionStore.shared
    @StateObject private var connectivity = ConnectivityService.shared

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(packStore)
                .environmentObject(sessionStore)
                .environmentObject(connectivity)
                .preferredColorScheme(.dark)
        }
    }
}
