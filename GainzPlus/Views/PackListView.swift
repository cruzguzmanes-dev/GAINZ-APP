import SwiftUI

// MARK: - PackListView

struct PackListView: View {
    @EnvironmentObject var packStore: PackStore
    @State private var showCreatePack = false

    var body: some View {
        List {
            Section("Mis packs") {
                ForEach(packStore.packs) { pack in
                    NavigationLink(destination: PackDetailView(pack: pack)) {
                        PackRow(pack: pack, isActive: packStore.activePack?.id == pack.id)
                    }
                }
                .onDelete { indexSet in
                    indexSet.map { packStore.packs[$0] }.forEach { pack in
                        if pack.isUserCreated { packStore.deletePack(pack) }
                    }
                }
            }
        }
        .navigationTitle("Packs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showCreatePack = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreatePack) {
            CardEditorView()
                .environmentObject(packStore)
        }
        .scrollContentBackground(.hidden)
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}

// MARK: - PackRow

struct PackRow: View {
    let pack: Pack
    let isActive: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(pack.emoji)
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(pack.title)
                        .font(.system(.subheadline).weight(.semibold))
                    if isActive {
                        Text("ACTIVO")
                            .font(.system(.caption2, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.green.opacity(0.2)))
                            .foregroundStyle(.green)
                    }
                }
                Text("\(pack.totalCards) tarjetas · \(pack.language.flag)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if pack.isPremium {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - PackDetailView

struct PackDetailView: View {
    @EnvironmentObject var packStore: PackStore
    @State var pack: Pack
    @State private var showAddCard = false

    var body: some View {
        List {
            Section {
                // Pack info header
                VStack(spacing: 8) {
                    Text(pack.emoji)
                        .font(.system(size: 48))
                    Text(pack.title)
                        .font(.system(.title2, design: .rounded).weight(.bold))
                    Text(pack.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 20) {
                        Label("\(pack.totalCards) tarjetas", systemImage: "rectangle.stack")
                        Label(pack.language.displayName, systemImage: "globe")
                    }
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)

                    Button {
                        packStore.setActivePack(pack)
                    } label: {
                        Label(
                            packStore.activePack?.id == pack.id ? "Pack activo ✓" : "Usar este pack",
                            systemImage: packStore.activePack?.id == pack.id ? "checkmark" : "play.fill"
                        )
                        .font(.system(.subheadline).weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(packStore.activePack?.id == pack.id
                                      ? Color.green.opacity(0.2)
                                      : Color(red: 0.78, green: 0.96, blue: 0.35))
                        )
                        .foregroundStyle(packStore.activePack?.id == pack.id ? .green : .black)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }

            Section("Tarjetas (\(pack.cards.count))") {
                ForEach(pack.cards) { card in
                    CardRow(card: card)
                }
            }
        }
        .navigationTitle(pack.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if pack.isUserCreated {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddCard = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}

// MARK: - CardRow

struct CardRow: View {
    let card: Card

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(card.phrase)
                    .font(.system(.subheadline, design: .serif).italic().weight(.semibold))
                Spacer()
                TypeBadge(type: card.type)
            }
            Text(card.meaningEN)
                .font(.system(.caption))
                .foregroundStyle(.secondary)
                .lineLimit(2)

            if card.timesShown > 0 {
                Text("\(card.timesShown) veces · \(card.knowledgeRate.asPercent) aciertos")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
