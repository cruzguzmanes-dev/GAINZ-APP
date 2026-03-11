import SwiftUI

struct SessionSummaryView: View {
    @ObservedObject var vm: SessionViewModel

    var body: some View {
        VStack(spacing: 10) {

            Text("💪")
                .font(.system(size: 30))

            Text("Serie lista")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(Color(red: 0.78, green: 0.96, blue: 0.35))

            // Stats
            HStack(spacing: 0) {
                statCell(value: "\(vm.seenCount)", label: "vistas")
                divider
                statCell(value: "\(vm.knownCount)", label: "sabías")
                divider
                statCell(
                    value: "🔥\(SessionStore.shared.streakDays)",
                    label: "racha"
                )
            }
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )

            Button {
                vm.reset()
            } label: {
                Text("↩ Nueva serie")
                    .font(.system(.footnote, design: .rounded).weight(.bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(red: 0.78, green: 0.96, blue: 0.35))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    // MARK: - Helpers

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.title3, design: .monospaced).weight(.semibold))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.1))
            .frame(width: 1, height: 36)
    }
}

#Preview {
    SessionSummaryView(vm: SessionViewModel())
}
