import SwiftUI

struct CardView: View {
    @ObservedObject var vm: SessionViewModel

    @State private var dragOffset: CGFloat = 0
    private let swipeThreshold: CGFloat = 40

    var body: some View {
        VStack(alignment: .center, spacing: 6) {

            // Mini progress bar — fija, no se mueve con el swipe
            timerProgressBar

            // Phrase — fija, no se mueve con el swipe
            if let card = vm.currentCard {
                Text(card.phrase)
                    .font(.system(.title2, design: .serif).italic().weight(.bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Solo esta zona tiene el swipe gesture y el offset
            ScrollView(.vertical, showsIndicators: false) {
                meaningArea
            }
            .frame(maxHeight: .infinity)
            .offset(x: dragOffset)
            .gesture(swipeGesture)
        }
        .padding(.horizontal, 12)
        .animation(.easeInOut(duration: 0.2), value: vm.isTranslationRevealed)
    }

    // MARK: - Mini progress bar

    private var timerProgressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 2)

                Capsule()
                    .fill(vm.ringColor)
                    .frame(width: max(4, geo.size.width * vm.ringProgress), height: 2)
                    .animation(.linear(duration: 1), value: vm.ringProgress)
            }
        }
        .frame(height: 2)
    }

    // MARK: - Meaning area

    @ViewBuilder
    private var meaningArea: some View {
        if vm.isTranslationRevealed {
            // — Vista ES — tap regresa a inglés
            if let card = vm.currentCard {
                VStack(spacing: 6) {
                    Text(card.meaningES)
                        .font(.system(.footnote, design: .serif).italic())
                        .foregroundStyle(Color(red: 0.78, green: 0.96, blue: 0.35))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    if !card.exampleES.isEmpty {
                        Text(card.exampleES)
                            .font(.system(.caption2))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .italic()
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, 4)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        vm.toggleTranslation()
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        } else {
            // — Vista EN — tap muestra traducción ES
            if let card = vm.currentCard {
                VStack(spacing: 6) {
                    Text(card.meaningEN)
                        .font(.system(.footnote))
                        .foregroundStyle(Color.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    if !card.exampleEN.isEmpty {
                        Text(card.exampleEN)
                            .font(.system(.caption2))
                            .foregroundStyle(Color.white.opacity(0.4))
                            .multilineTextAlignment(.center)
                            .italic()
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.1),
                                style: StrokeStyle(lineWidth: 1, dash: [4]))
                )
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        vm.toggleTranslation()
                    }
                }
            }
        }
    }

    // MARK: - Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                dragOffset = value.translation.width * 0.6
            }
            .onEnded { value in
                let dx = value.translation.width
                if dx < -swipeThreshold {
                    triggerSwipe(knew: true)
                } else if dx > swipeThreshold {
                    triggerSwipe(knew: false)
                } else {
                    withAnimation(.spring()) { dragOffset = 0 }
                }
            }
    }

    private func triggerSwipe(knew: Bool) {
        withAnimation(.easeOut(duration: 0.15)) {
            dragOffset = knew ? -200 : 200
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            dragOffset = 0
            vm.submitResult(knew: knew)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        CardView(vm: SessionViewModel())
    }
}
