import SwiftUI

struct HomeView: View {
    @EnvironmentObject var packStore: PackStore
    @EnvironmentObject var sessionStore: SessionStore
    @EnvironmentObject var connectivity: ConnectivityService

    @State private var showPackList    = false
    @State private var showCMS         = false
    @State private var isSyncingWatch  = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    activePackSection
                    quickStatsSection
                    recentSessionsSection
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Gainz+")
                        .font(.system(.headline, design: .monospaced).weight(.bold))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: PackListView()) {
                        Image(systemName: "square.stack.fill")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCMS = true
                    } label: {
                        Image(systemName: "plus.rectangle.on.folder")
                    }
                }
            }
            .background(Color.black.ignoresSafeArea())
            .fullScreenCover(isPresented: $showCMS) {
                CMSView()
                    .environmentObject(packStore)
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("Gainz+")
                .font(.system(size: 42, weight: .black, design: .monospaced))
                .foregroundStyle(Color(red: 0.78, green: 0.96, blue: 0.35))
            Text("Not all gainz are physical.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var activePackSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionLabel("Pack activo")
                Spacer()
                SyncStatusPill(state: packStore.syncState) {
                    Task { await packStore.loadFromSupabase() }
                }
            }

            if let pack = packStore.activePack {
                // onSync envía solo el pack activo — mantiene el payload bajo 65 KB
                // para que updateApplicationContext funcione correctamente.
                ActivePackCard(pack: pack) {
                    connectivity.transferActivePack(pack)
                }
            } else {
                Text("Sin pack activo")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("Hoy")

            // ── Fila de números ──────────────────────────────────────────────
            HStack(spacing: 12) {
                StatCard(
                    icon: "eye.fill",
                    value: "\(sessionStore.cardStatsToday.count)",
                    label: "palabras únicas"
                )
                StatCard(
                    icon: "flame.fill",
                    value: "\(sessionStore.streakDays)",
                    label: "días de racha",
                    tint: .orange
                )
                StatCard(
                    icon: "arrow.triangle.2.circlepath",
                    value: "\(sessionStore.repeatedCardsToday.count)",
                    label: "repetidas hoy",
                    tint: Color(red: 0.486, green: 0.427, blue: 0.980)
                )
            }

            // ── Precisión del día ────────────────────────────────────────────
            if sessionStore.totalCardsToday > 0 {
                AccuracyBar(accuracy: sessionStore.accuracyToday,
                            total: sessionStore.totalCardsToday)
            }

            // ── Lista de palabras vistas hoy ─────────────────────────────────
            if !sessionStore.cardStatsToday.isEmpty {
                TodayWordsSection(stats: sessionStore.cardStatsToday)
            }
        }
    }

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionLabel("Últimas sesiones")
                Spacer()
                // Botón para pedir sesiones al Watch cuando está en foreground
                Button {
                    isSyncingWatch = true
                    connectivity.requestSessionsFromWatch { watchSessions in
                        for s in watchSessions
                        where !sessionStore.sessions.contains(where: { $0.id == s.id }) {
                            sessionStore.save(s)
                        }
                        isSyncingWatch = false
                    }
                    // Timeout visual: si en 5s no responde, quita el spinner
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        isSyncingWatch = false
                    }
                } label: {
                    HStack(spacing: 5) {
                        if isSyncingWatch {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.55)
                                .tint(.secondary)
                        } else {
                            Image(systemName: "applewatch.radiowaves.left.and.right")
                                .font(.system(size: 11))
                        }
                        Text(isSyncingWatch ? "Sincronizando…" : "Sync Watch")
                            .font(.system(.caption2, design: .monospaced))
                    }
                    .foregroundStyle(connectivity.isReachable ? .secondary : .tertiary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill(Color.white.opacity(0.05))
                            .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
                .disabled(!connectivity.isReachable || isSyncingWatch)
            }

            if sessionStore.sessions.isEmpty {
                Text("Aún no hay sesiones. ¡Ve al gym! 💪")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(sessionStore.sessions.prefix(5)) { session in
                    SessionRow(session: session)
                }
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(.caption2, design: .monospaced))
            .foregroundStyle(.secondary)
            .tracking(2)
    }
}

// MARK: - ActivePackCard

struct ActivePackCard: View {
    let pack: Pack
    let onSync: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text(pack.emoji)
                .font(.system(size: 32))

            VStack(alignment: .leading, spacing: 3) {
                Text(pack.title)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                Text("\(pack.totalCards) tarjetas · \(pack.language.displayName)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.1))
                            .frame(height: 3)
                        Capsule()
                            .fill(Color(red: 0.78, green: 0.96, blue: 0.35))
                            .frame(width: geo.size.width * pack.progress, height: 3)
                    }
                }
                .frame(height: 3)
                .padding(.top, 2)
            }

            Spacer()

            Button(action: onSync) {
                Image(systemName: "applewatch")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(red: 0.78, green: 0.96, blue: 0.35))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - StatCard

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    var tint: Color = Color(red: 0.78, green: 0.96, blue: 0.35)

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .font(.system(size: 18))
            Text(value)
                .font(.system(.title2, design: .monospaced).weight(.bold))
            Text(label)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - SessionRow

struct SessionRow: View {
    let session: RestSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.date, style: .date)
                    .font(.system(.subheadline).weight(.semibold))
                Text("\(session.restDuration.formattedAsTime) rest · \(session.seenCount) tarjetas")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(session.knownCount)/\(session.seenCount)")
                .font(.system(.subheadline, design: .monospaced).weight(.bold))
                .foregroundStyle(Color(red: 0.78, green: 0.96, blue: 0.35))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.04))
        )
    }
}

// MARK: - AccuracyBar

struct AccuracyBar: View {
    let accuracy: Double   // 0–1
    let total: Int

    private var color: Color {
        switch accuracy {
        case 0.8...: return Color(red: 0.239, green: 0.839, blue: 0.549)  // verde
        case 0.5...: return Color(red: 0.78,  green: 0.96,  blue: 0.35)   // lima
        default:     return Color(red: 0.957, green: 0.431, blue: 0.431)  // rojo
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("PRECISIÓN HOY")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .tracking(1.5)
                Spacer()
                Text("\(Int(accuracy * 100))%  ·  \(total) respuestas")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.07))
                        .frame(height: 5)
                    Capsule().fill(color)
                        .frame(width: geo.size.width * accuracy, height: 5)
                        .animation(.easeOut(duration: 0.6), value: accuracy)
                }
            }
            .frame(height: 5)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.04))
        )
    }
}

// MARK: - TodayWordsSection

struct TodayWordsSection: View {
    let stats: [CardDailyStat]

    private let accentGreen  = Color(red: 0.239, green: 0.839, blue: 0.549)
    private let accentRed    = Color(red: 0.957, green: 0.431, blue: 0.431)
    private let accentPurple = Color(red: 0.486, green: 0.427, blue: 0.980)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PALABRAS VISTAS")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
                .tracking(1.5)

            ForEach(stats) { stat in
                HStack(spacing: 10) {

                    // ── Dots de intentos (hasta 5) ───────────────────────────
                    HStack(spacing: 3) {
                        ForEach(Array(stat.results.prefix(5).enumerated()), id: \.offset) { _, r in
                            Circle()
                                .fill(r.knew ? accentGreen : accentRed)
                                .frame(width: 6, height: 6)
                        }
                        if stat.timesShown > 5 {
                            Text("+\(stat.timesShown - 5)")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .frame(width: 48, alignment: .leading)

                    // ── Palabra ──────────────────────────────────────────────
                    Text(stat.phrase)
                        .font(.system(.subheadline, design: .serif).italic())
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Spacer()

                    // ── Badge repetida ───────────────────────────────────────
                    if stat.isRepeated {
                        Text("×\(stat.timesShown)")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(accentPurple)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(accentPurple.opacity(0.12)))
                    }

                    // ── Accuracy ─────────────────────────────────────────────
                    Text("\(Int(stat.accuracy * 100))%")
                        .font(.system(.caption, design: .monospaced).weight(.semibold))
                        .foregroundStyle(
                            stat.accuracy >= 0.8 ? accentGreen :
                            stat.accuracy >= 0.5 ? Color(red: 0.78, green: 0.96, blue: 0.35) :
                            accentRed
                        )
                        .frame(minWidth: 36, alignment: .trailing)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(stat.lastKnew ? 0.04 : 0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    stat.lastKnew
                                        ? accentGreen.opacity(0.15)
                                        : Color.white.opacity(0.06),
                                    lineWidth: 1
                                )
                        )
                )
            }
        }
    }
}

// MARK: - SyncStatusPill

struct SyncStatusPill: View {
    let state: PackStore.SyncState
    let onRetry: () -> Void

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        Button(action: { if case .error = state { onRetry() } }) {
            HStack(spacing: 5) {
                indicator
                label
            }
            .font(.system(.caption2, design: .monospaced))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(backgroundColor)
                    .overlay(Capsule().stroke(borderColor, lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
        .disabled({ if case .error = state { return false }; return true }())
    }

    @ViewBuilder
    private var indicator: some View {
        switch state {
        case .loading:
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(0.55)
                .tint(Color(red: 0.78, green: 0.96, blue: 0.35))
        case .success:
            Circle()
                .fill(Color(red: 0.239, green: 0.839, blue: 0.549))
                .frame(width: 5, height: 5)
        case .error:
            Circle()
                .fill(Color.red.opacity(0.8))
                .frame(width: 5, height: 5)
        case .idle:
            Circle()
                .fill(Color.secondary)
                .frame(width: 5, height: 5)
        }
    }

    @ViewBuilder
    private var label: some View {
        switch state {
        case .loading:
            Text("Sincronizando…")
                .foregroundStyle(Color(red: 0.78, green: 0.96, blue: 0.35))
        case .success(let date):
            Text("Actualizado \(Self.timeFormatter.string(from: date))")
                .foregroundStyle(Color(red: 0.239, green: 0.839, blue: 0.549))
        case .error:
            HStack(spacing: 3) {
                Text("Sin conexión · reintentar")
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 9))
            }
            .foregroundStyle(Color.red.opacity(0.8))
        case .idle:
            Text("Sin sync")
                .foregroundStyle(.secondary)
        }
    }

    private var backgroundColor: Color {
        switch state {
        case .loading: return Color(red: 0.78, green: 0.96, blue: 0.35).opacity(0.07)
        case .success: return Color(red: 0.239, green: 0.839, blue: 0.549).opacity(0.07)
        case .error:   return Color.red.opacity(0.07)
        case .idle:    return Color.white.opacity(0.04)
        }
    }

    private var borderColor: Color {
        switch state {
        case .loading: return Color(red: 0.78, green: 0.96, blue: 0.35).opacity(0.2)
        case .success: return Color(red: 0.239, green: 0.839, blue: 0.549).opacity(0.2)
        case .error:   return Color.red.opacity(0.2)
        case .idle:    return Color.white.opacity(0.08)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(PackStore.shared)
        .environmentObject(SessionStore.shared)
        .environmentObject(ConnectivityService.shared)
}
