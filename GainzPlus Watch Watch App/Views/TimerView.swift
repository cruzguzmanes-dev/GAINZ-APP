import SwiftUI


struct TimerView: View {
    @ObservedObject var vm: SessionViewModel

    var body: some View {
        VStack(spacing: 14) {

            // Ring + countdown (centrado)
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: vm.ringProgress)
                    .stroke(
                        vm.ringColor,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: vm.ringProgress)
                    .shadow(color: vm.ringColor.opacity(0.5), radius: 4)

                Text(vm.timeRemaining.formattedAsTime)
                    .font(.system(.title, design: .monospaced).weight(.semibold))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }
            .frame(width: 110, height: 110)

            // Skip button
            Button {
                vm.skipToCard()
            } label: {
                Text("Ver tarjeta →")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding()
        // Botón back como overlay — no requiere NavigationStack
        .overlay(alignment: .topLeading) {
            Button {
                vm.reset()
            } label: {
                Image(systemName: "chevron.backward")
                    .font(.system(.caption2, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
    }
}


#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        TimerView(vm: SessionViewModel())
    }
}
