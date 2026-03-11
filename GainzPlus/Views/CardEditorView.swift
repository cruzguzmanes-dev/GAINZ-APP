import SwiftUI

struct CardEditorView: View {
    @EnvironmentObject var packStore: PackStore
    @Environment(\.dismiss) var dismiss

    // Pack meta
    @State private var packTitle: String = ""
    @State private var packEmoji: String = "📦"
    @State private var packDescription: String = ""
    @State private var selectedLanguage: Pack.Language = .english

    // Cards
    @State private var cards: [Card] = []
    @State private var showAddCard = false

    var body: some View {
        NavigationStack {
            Form {
                // Pack info
                Section("Información del pack") {
                    HStack {
                        TextField("Emoji", text: $packEmoji)
                            .frame(width: 44)
                        TextField("Nombre del pack", text: $packTitle)
                    }
                    TextField("Descripción (opcional)", text: $packDescription)
                    Picker("Idioma", selection: $selectedLanguage) {
                        ForEach(Pack.Language.allCases, id: \.self) { lang in
                            Text("\(lang.flag) \(lang.displayName)").tag(lang)
                        }
                    }
                }

                // Cards
                Section("Tarjetas (\(cards.count))") {
                    ForEach(cards) { card in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(card.phrase)
                                .font(.system(.subheadline, design: .serif).italic().weight(.semibold))
                            Text(card.meaningEN)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .onDelete { indexSet in
                        cards.remove(atOffsets: indexSet)
                    }

                    Button {
                        showAddCard = true
                    } label: {
                        Label("Agregar tarjeta", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("Nuevo pack")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") { savePack() }
                        .disabled(packTitle.isEmpty || cards.isEmpty)
                        .bold()
                }
            }
            .sheet(isPresented: $showAddCard) {
                AddCardSheet { newCard in
                    cards.append(newCard)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .preferredColorScheme(.dark)
        }
    }

    private func savePack() {
        let pack = Pack(
            title: packTitle,
            description: packDescription,
            emoji: packEmoji.isEmpty ? "📦" : String(packEmoji.prefix(2)),
            language: selectedLanguage,
            isPremium: false,
            isUserCreated: true,
            cards: cards
        )
        packStore.addUserPack(pack)
        dismiss()
    }
}

// MARK: - AddCardSheet

struct AddCardSheet: View {
    @Environment(\.dismiss) var dismiss
    var onAdd: (Card) -> Void

    @State private var phrase     = ""
    @State private var type       = Card.CardType.phrasalVerb
    @State private var meaningEN  = ""
    @State private var meaningES  = ""
    @State private var exampleEN  = ""
    @State private var exampleES  = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Frase o palabra") {
                    TextField("Ej: Give up", text: $phrase)
                    Picker("Tipo", selection: $type) {
                        ForEach(Card.CardType.allCases, id: \.self) { t in
                            Text(t.badgeLabel).tag(t)
                        }
                    }
                }

                Section("Significados") {
                    TextField("Significado en inglés", text: $meaningEN, axis: .vertical)
                        .lineLimit(2...4)
                    TextField("Significado en español", text: $meaningES, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Ejemplos (opcional)") {
                    TextField("Ejemplo en inglés", text: $exampleEN, axis: .vertical)
                    TextField("Ejemplo en español", text: $exampleES, axis: .vertical)
                }
            }
            .navigationTitle("Nueva tarjeta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Agregar") {
                        let card = Card(
                            phrase: phrase,
                            type: type,
                            meaningEN: meaningEN,
                            meaningES: meaningES,
                            exampleEN: exampleEN,
                            exampleES: exampleES
                        )
                        onAdd(card)
                        dismiss()
                    }
                    .disabled(phrase.isEmpty || meaningEN.isEmpty || meaningES.isEmpty)
                    .bold()
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .preferredColorScheme(.dark)
        }
    }
}
