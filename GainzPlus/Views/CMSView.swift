import SwiftUI

// MARK: - Colors
private extension Color {
    static let cmsAccent = Color(red: 0.486, green: 0.427, blue: 0.980) // #7c6dfa
    static let cmsGreen  = Color(red: 0.239, green: 0.839, blue: 0.549) // #3dd68c
    static let cmsLime   = Color(red: 0.78,  green: 0.96,  blue: 0.35)  // lime activo
}

// MARK: - CMSView (Root) ─────────────────────────────────────────────────────

struct CMSView: View {
    @EnvironmentObject var packStore: PackStore
    @Environment(\.dismiss) var dismiss

    @State private var selectedPackID: UUID?
    @State private var showCreatePack = false

    private var selectedPack: Pack? {
        packStore.packs.first { $0.id == selectedPackID }
    }

    var body: some View {
        NavigationSplitView {
            CMSSidebar(
                selectedPackID: $selectedPackID,
                showCreatePack: $showCreatePack,
                onDismiss: { dismiss() }
            )
        } detail: {
            if let pack = selectedPack {
                CMSDetailView(pack: pack)
            } else {
                CMSEmptyDetail()
            }
        }
        .sheet(isPresented: $showCreatePack) {
            CreatePackSheet { newPack in
                packStore.addUserPack(newPack)
                selectedPackID = newPack.id
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - CMSSidebar ─────────────────────────────────────────────────────────

struct CMSSidebar: View {
    @EnvironmentObject var packStore: PackStore
    @Binding var selectedPackID: UUID?
    @Binding var showCreatePack: Bool
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            List(selection: $selectedPackID) {
                Section {
                    ForEach(packStore.packs) { pack in
                        PackSidebarRow(
                            pack: pack,
                            isActive: packStore.activePack?.id == pack.id
                        )
                        .tag(pack.id)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if pack.isUserCreated {
                                Button(role: .destructive) {
                                    withAnimation {
                                        if selectedPackID == pack.id { selectedPackID = nil }
                                        packStore.deletePack(pack)
                                    }
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                            }
                        }
                    }
                } header: {
                    Text("CATEGORÍAS")
                        .font(.system(.caption2, design: .monospaced))
                        .tracking(1.5)
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)

            Divider().background(Color.white.opacity(0.08))

            // ── Botón nueva categoría ──
            Button { showCreatePack = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Nueva categoría")
                }
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(Color.cmsAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.cmsAccent.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(
                                    Color.cmsAccent.opacity(0.4),
                                    style: StrokeStyle(lineWidth: 1, dash: [5])
                                )
                        )
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
        }
        .background(Color.black)
        .navigationTitle("Gainz CMS")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(7)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
            }
        }
    }
}

// MARK: - PackSidebarRow ─────────────────────────────────────────────────────

struct PackSidebarRow: View {
    let pack: Pack
    let isActive: Bool

    var body: some View {
        HStack(spacing: 10) {
            Text(pack.emoji)
                .font(.system(size: 22))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(pack.title)
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(isActive ? Color.cmsAccent : .primary)
                    .lineLimit(1)
                Text("\(pack.cards.count) tarjetas")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if isActive {
                Circle()
                    .fill(Color.cmsGreen)
                    .frame(width: 6, height: 6)
            }
            if pack.isUserCreated {
                Image(systemName: "pencil")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - CMSEmptyDetail ─────────────────────────────────────────────────────

struct CMSEmptyDetail: View {
    var body: some View {
        VStack(spacing: 14) {
            Text("📚")
                .font(.system(size: 56))
                .opacity(0.25)
            Text("Selecciona una categoría")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(.secondary)
            Text("Elige del panel o crea una nueva.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}

// MARK: - CMSDetailView ──────────────────────────────────────────────────────

struct CMSDetailView: View {
    @EnvironmentObject var packStore: PackStore
    let pack: Pack

    @State private var showAddCard     = false
    @State private var editingCard: Card?
    @State private var expandedIDs: Set<UUID> = []
    @State private var searchText      = ""

    private var livePack: Pack {
        packStore.packs.first { $0.id == pack.id } ?? pack
    }

    private var filteredCards: [Card] {
        guard !searchText.isEmpty else { return livePack.cards }
        return livePack.cards.filter {
            $0.phrase.localizedCaseInsensitiveContains(searchText) ||
            $0.meaningES.localizedCaseInsensitiveContains(searchText) ||
            $0.meaningEN.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // ── Header ──────────────────────────────────────────────────
                HStack(alignment: .top, spacing: 14) {
                    Text(livePack.emoji)
                        .font(.system(size: 44))

                    VStack(alignment: .leading, spacing: 5) {
                        Text(livePack.title)
                            .font(.system(.title2, design: .rounded).weight(.bold))
                        Text("\(livePack.cards.count) tarjetas · \(livePack.language.flag) \(livePack.language.displayName)")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)

                        Button {
                            packStore.setActivePack(livePack)
                        } label: {
                            let isActive = packStore.activePack?.id == livePack.id
                            Label(
                                isActive ? "Pack activo ✓" : "Usar este pack",
                                systemImage: isActive ? "checkmark" : "play.fill"
                            )
                            .font(.system(.caption, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(
                                isActive
                                    ? Color.green.opacity(0.15)
                                    : Color.cmsLime.opacity(0.15)
                            ))
                            .foregroundStyle(isActive ? .green : Color.cmsLime)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                // ── Search bar ───────────────────────────────────────────────
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.tertiary)
                    TextField("Buscar en \(livePack.title)…", text: $searchText)
                        .font(.subheadline)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.06))
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1))
                )
                .padding(.horizontal)

                // ── Card list ────────────────────────────────────────────────
                if filteredCards.isEmpty {
                    VStack(spacing: 10) {
                        Text(searchText.isEmpty ? "✍️" : "🔍")
                            .font(.system(size: 40)).opacity(0.3)
                        Text(searchText.isEmpty ? "Sin tarjetas aún" : "Sin resultados")
                            .font(.system(.subheadline).weight(.semibold))
                            .foregroundStyle(.secondary)
                        if searchText.isEmpty {
                            Text("Pulsa + para agregar la primera.")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredCards) { card in
                            CMSCardRow(
                                card: card,
                                isExpanded: expandedIDs.contains(card.id),
                                onToggle: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        expandedIDs.formSymmetricDifference([card.id])
                                    }
                                },
                                onEdit: { editingCard = card },
                                onDelete: {
                                    withAnimation {
                                        var updated = livePack
                                        updated.cards.removeAll { $0.id == card.id }
                                        packStore.updatePack(updated)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle(livePack.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAddCard = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        // ── New card ─────────────────────────────────────────────────────────
        .sheet(isPresented: $showAddCard) {
            CardFormSheet(packTitle: livePack.title) { card in
                var updated = livePack
                updated.cards.append(card)
                packStore.updatePack(updated)
            }
        }
        // ── Edit card ────────────────────────────────────────────────────────
        .sheet(item: $editingCard) { card in
            CardFormSheet(packTitle: livePack.title, editing: card) { updated in
                var newPack = livePack
                if let idx = newPack.cards.firstIndex(where: { $0.id == card.id }) {
                    newPack.cards[idx] = updated
                }
                packStore.updatePack(newPack)
            }
        }
    }
}

// MARK: - CMSCardRow (expandable) ────────────────────────────────────────────

struct CMSCardRow: View {
    let card: Card
    let isExpanded: Bool
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 0) {

            // ── Header ───────────────────────────────────────────────────────
            Button(action: onToggle) {
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(card.phrase)
                            .font(.system(.body, design: .serif).italic().weight(.semibold))
                            .foregroundStyle(.white)
                        if !card.meaningES.isEmpty {
                            Text(card.meaningES)
                                .font(.system(.caption, weight: .medium))
                                .foregroundStyle(Color.cmsGreen)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    TypeBadge(type: card.type)
                        .frame(maxWidth: 100)

                    HStack(spacing: 6) {
                        Button(action: onEdit) {
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(7)
                                .background(Circle().fill(Color.white.opacity(0.08)))
                        }
                        .buttonStyle(.plain)

                        Button(role: .destructive, action: onDelete) {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundStyle(.red.opacity(0.7))
                                .padding(7)
                                .background(Circle().fill(Color.red.opacity(0.08)))
                        }
                        .buttonStyle(.plain)

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            // ── Expanded detail ───────────────────────────────────────────────
            if isExpanded {
                Divider().background(Color.white.opacity(0.08))
                HStack(alignment: .top, spacing: 10) {
                    CMSLangBlock(
                        lang: "EN 🇺🇸",
                        color: Color.cmsAccent,
                        definition: card.meaningEN,
                        example: card.exampleEN
                    )
                    CMSLangBlock(
                        lang: "ES 🇲🇽",
                        color: Color.cmsGreen,
                        definition: card.meaningES,
                        example: card.exampleES
                    )
                }
                .padding(14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(isExpanded ? 0.14 : 0.08), lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - CMSLangBlock ───────────────────────────────────────────────────────

struct CMSLangBlock: View {
    let lang: String
    let color: Color
    let definition: String
    let example: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Lang label
            HStack(spacing: 5) {
                Circle().fill(color).frame(width: 5, height: 5)
                Text(lang)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(color)
                    .tracking(1)
            }

            if !definition.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DEFINITION")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .tracking(1)
                    Text(definition)
                        .font(.system(.caption))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !example.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("EXAMPLE")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .tracking(1)
                    Text(example)
                        .font(.system(.caption).italic())
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.leading, 8)
                        .overlay(alignment: .leading) {
                            Rectangle()
                                .fill(color.opacity(0.5))
                                .frame(width: 2)
                        }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                )
        )
    }
}

// MARK: - CreatePackSheet ────────────────────────────────────────────────────

struct CreatePackSheet: View {
    @Environment(\.dismiss) var dismiss
    var onCreate: (Pack) -> Void

    @State private var name  = ""
    @State private var emoji = "📦"

    // Emojis como Character para que no sean procesados por UIEmojiSearchOperations
    private let emojis: [String] = [
        "💼","📈","🏋️","🧠","🌍","🎯","💡","🔥",
        "🎓","💪","🚀","⚡","🎨","🏆","💬","📱",
        "🌱","🔑","✨","🎵","🍎","🏃","💻","🌐",
        "📦","🧩","🎲","🦁","🐉","🌊","🏔️","🌸"
    ]

    var body: some View {
        NavigationStack {
            // ScrollView en lugar de Form → evita el layout pass que
            // dispara UIEmojiSearchOperations al aparecer el teclado
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // ── Nombre ───────────────────────────────────────────────
                    sectionLabel("Nombre")
                    TextField("Ej. Business English", text: $name)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.07))
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1))
                        )
                        // Fix principal: evita que el teclado busque variantes de emoji
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)

                    // ── Emoji picker ─────────────────────────────────────────
                    sectionLabel("Emoji")
                    // LazyVGrid fuera del contexto de Form: no participa
                    // en el keyboard-avoidance scroll de Form
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(minimum: 36)), count: 8),
                        spacing: 8
                    ) {
                        ForEach(emojis, id: \.self) { e in
                            Button {
                                withAnimation(.easeInOut(duration: 0.1)) { emoji = e }
                            } label: {
                                Text(e)
                                    .font(.system(size: 22))
                                    .frame(width: 36, height: 36)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(emoji == e
                                                  ? Color.cmsAccent.opacity(0.2)
                                                  : Color.white.opacity(0.05))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(
                                                        emoji == e ? Color.cmsAccent : Color.clear,
                                                        lineWidth: 1.5
                                                    )
                                            )
                                    )
                                    // Ocultar del árbol de accesibilidad de texto
                                    // para que el sistema no intente indexar el emoji
                                    .accessibilityHidden(true)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // ── Vista previa ─────────────────────────────────────────
                    sectionLabel("Vista previa")
                    HStack(spacing: 12) {
                        Text(emoji)
                            .font(.system(size: 32))
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(name.isEmpty ? "Nombre del pack" : name)
                                .font(.system(.subheadline, weight: .semibold))
                                .foregroundStyle(name.isEmpty ? .tertiary : .primary)
                            Text("0 tarjetas")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.05))
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1))
                    )
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively) // cierra teclado con scroll
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Nueva categoría")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Crear") {
                        let pack = Pack(
                            title: name.trimmingCharacters(in: .whitespaces),
                            emoji: emoji,
                            isUserCreated: true,
                            cards: []
                        )
                        onCreate(pack)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .bold()
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(.caption2, design: .monospaced))
            .foregroundStyle(.secondary)
            .tracking(1.5)
    }
}

// MARK: - CardFormSheet ──────────────────────────────────────────────────────

struct CardFormSheet: View {
    @Environment(\.dismiss) var dismiss

    let packTitle: String
    var editing: Card? = nil
    var onSave: (Card) -> Void

    @State private var phrase  = ""
    @State private var type    = Card.CardType.custom
    @State private var defEN   = ""
    @State private var exEN    = ""
    @State private var defES   = ""
    @State private var exES    = ""

    private var isValid: Bool {
        !phrase.trimmingCharacters(in: .whitespaces).isEmpty &&
        !defEN.trimmingCharacters(in: .whitespaces).isEmpty &&
        !defES.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            // ScrollView en lugar de Form → evita el UITableView que dispara
            // UIEmojiSearchOperations y congela la pantalla al tocar un TextField
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // ── Palabra + tipo ───────────────────────────────────────
                    formSection(header: "PALABRA / FRASE") {
                        VStack(spacing: 0) {
                            TextField("Ej: leverage", text: $phrase)
                                .font(.system(.body, design: .serif).italic())
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .padding(14)

                            Divider().background(Color.white.opacity(0.08))

                            // Picker inline sin Form — usa Menu para evitar
                            // el layout pass de UITableView
                            Menu {
                                ForEach(Card.CardType.allCases, id: \.self) { t in
                                    Button {
                                        type = t
                                    } label: {
                                        Label(t.badgeLabel, systemImage: type == t ? "checkmark" : "")
                                    }
                                }
                            } label: {
                                HStack {
                                    Text("Tipo")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    TypeBadge(type: type)
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(14)
                            }
                        }
                    }

                    // ── English ──────────────────────────────────────────────
                    formSection(
                        header: "ENGLISH",
                        accentColor: Color.cmsAccent,
                        footer: "Definition  ·  Example (opcional)"
                    ) {
                        VStack(spacing: 0) {
                            TextField(
                                "The use of borrowed capital to increase potential return…",
                                text: $defEN,
                                axis: .vertical
                            )
                            .lineLimit(3...6)
                            .autocorrectionDisabled()
                            .padding(14)

                            Divider().background(Color.white.opacity(0.08))

                            TextField(
                                "She used her network to leverage the deal.",
                                text: $exEN,
                                axis: .vertical
                            )
                            .lineLimit(2...4)
                            .foregroundStyle(.secondary)
                            .autocorrectionDisabled()
                            .padding(14)
                        }
                    }

                    // ── Español ──────────────────────────────────────────────
                    formSection(
                        header: "ESPAÑOL",
                        accentColor: Color.cmsGreen,
                        footer: "Significado  ·  Uso (opcional)"
                    ) {
                        VStack(spacing: 0) {
                            TextField(
                                "Usar recursos o influencia para obtener ventaja…",
                                text: $defES,
                                axis: .vertical
                            )
                            .lineLimit(3...6)
                            .autocorrectionDisabled()
                            .padding(14)

                            Divider().background(Color.white.opacity(0.08))

                            TextField(
                                "Hay que aprovechar cada oportunidad.",
                                text: $exES,
                                axis: .vertical
                            )
                            .lineLimit(2...4)
                            .foregroundStyle(.secondary)
                            .autocorrectionDisabled()
                            .padding(14)
                        }
                    }
                }
                .padding(16)
                .padding(.bottom, 20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle(editing == nil ? "Nueva tarjeta" : "Editar tarjeta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(editing == nil ? "Agregar" : "Guardar") {
                        let card = Card(
                            id:         editing?.id ?? UUID(),
                            phrase:     phrase.trimmingCharacters(in: .whitespaces),
                            type:       type,
                            meaningEN:  defEN.trimmingCharacters(in: .whitespaces),
                            meaningES:  defES.trimmingCharacters(in: .whitespaces),
                            exampleEN:  exEN.trimmingCharacters(in: .whitespaces),
                            exampleES:  exES.trimmingCharacters(in: .whitespaces),
                            timesShown: editing?.timesShown ?? 0,
                            timesKnown: editing?.timesKnown ?? 0
                        )
                        onSave(card)
                        dismiss()
                    }
                    .disabled(!isValid)
                    .bold()
                }
            }
            .onAppear {
                guard let c = editing else { return }
                phrase = c.phrase
                type   = c.type
                defEN  = c.meaningEN
                exEN   = c.exampleEN
                defES  = c.meaningES
                exES   = c.exampleES
            }
            .preferredColorScheme(.dark)
        }
    }

    // ── Sección visual (reemplaza Section de Form) ───────────────────────────
    @ViewBuilder
    private func formSection<Content: View>(
        header: String,
        accentColor: Color = .secondary,
        footer: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(header)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(accentColor)
                .tracking(1.5)
                .padding(.horizontal, 4)

            content()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )

            if let footer {
                Text(footer)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 4)
            }
        }
    }
}

// MARK: - Preview ────────────────────────────────────────────────────────────

#Preview {
    CMSView()
        .environmentObject(PackStore.shared)
}
