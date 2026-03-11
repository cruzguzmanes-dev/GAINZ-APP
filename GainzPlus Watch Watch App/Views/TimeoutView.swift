import SwiftUI

struct TimeoutView: View {

    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0

    var body: some View {
        VStack(spacing: 10) {
            Text("💪")
                .font(.system(size: 40))

            Text("¡Buen trabajo!")
                .font(.system(.headline, weight: .bold))
                .foregroundStyle(.white)

            Text("Descanso terminado")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(duration: 0.4)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        TimeoutView()
    }
}
