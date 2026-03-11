import SwiftUI

@main
struct GainzWatchApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    @StateObject private var vm = SessionViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Group {
                switch vm.appState {
                case .picker:
                    RestPickerView(vm: vm)
                case .timer:
                    TimerView(vm: vm)
                case .card:
                    CardView(vm: vm)
                case .timeout:
                    TimeoutView()
                case .summary:
                    SessionSummaryView(vm: vm)
                }
            }
            .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.2), value: vm.appState)
    }
}
