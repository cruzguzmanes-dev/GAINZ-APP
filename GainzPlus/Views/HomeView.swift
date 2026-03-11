import SwiftUI

struct HomeView: View {
    @EnvironmentObject var packStore: PackStore
    @EnvironmentObject var sessionStore: SessionStore
    @EnvironmentObject var connectivity: ConnectivityService

    @State private var showPackList = false

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
            }
            .background(Color.black.ignoresSafeArea())
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
            sectionLabel("Pack activo")

            if let pack = packStore.activePack {
                ActivePackCard(pack: pack) {
                    connectivity.sendActivePack(pack)
                }
            } else {
                Text("Sin pack activo")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Hoy")

            HStack(spacing: 12) {
                StatCard(
                    icon: "eye.fill",
                    value: "\(sessionStore.totalCardsToday)",
                    label: "tarjetas vistas"
                )
                StatCard(
                    icon: "flame.fill",
                    value: "\(sessionStore.streakDays)",
                    label: "días de racha",
                    tint: .orange
                )
                StatCard(
                    icon: "clock.fill",
                    value: "\(sessionStore.sessionsThisWeek.count)",
                    label: "sesiones esta semana"
                )
            }
        }
    }

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Últimas sesiones")

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

#Preview {
    HomeView()
        .environmentObject(PackStore.shared)
        .environmentObject(SessionStore.shared)
        .environmentObject(ConnectivityService.shared)
}
