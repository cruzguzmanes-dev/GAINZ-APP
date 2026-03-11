import SwiftUI

struct StatsView: View {
    @EnvironmentObject var sessionStore: SessionStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Streak
                    streakCard

                    // This week
                    weekChart

                    // All sessions
                    sessionList
                }
                .padding()
            }
            .navigationTitle("Stats")
            .background(Color.black.ignoresSafeArea())
            .preferredColorScheme(.dark)
        }
    }

    // MARK: - Sections

    private var streakCard: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("🔥")
                    .font(.system(size: 36))
                Text("\(sessionStore.streakDays)")
                    .font(.system(.largeTitle, design: .monospaced).weight(.black))
                    .foregroundStyle(Color(red: 0.78, green: 0.96, blue: 0.35))
                Text("días de racha")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()

            VStack(spacing: 4) {
                Text("📚")
                    .font(.system(size: 36))
                Text("\(totalCardsAllTime)")
                    .font(.system(.largeTitle, design: .monospaced).weight(.black))
                    .foregroundStyle(Color(red: 0.78, green: 0.96, blue: 0.35))
                Text("tarjetas totales")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }

    private var weekChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ESTA SEMANA")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
                .tracking(2)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(last7Days, id: \.0) { (date, count) in
                    VStack(spacing: 4) {
                        Capsule()
                            .fill(count > 0
                                  ? Color(red: 0.78, green: 0.96, blue: 0.35)
                                  : Color.white.opacity(0.08))
                            .frame(height: max(4, CGFloat(count) * 18))
                        Text(dayLabel(date))
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 100, alignment: .bottom)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }

    private var sessionList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HISTORIAL")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
                .tracking(2)

            ForEach(sessionStore.sessions) { session in
                SessionRow(session: session)
            }

            if sessionStore.sessions.isEmpty {
                Text("Sin sesiones todavía. ¡A entrenar!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
    }

    // MARK: - Helpers

    private var totalCardsAllTime: Int {
        sessionStore.sessions.reduce(0) { $0 + $1.seenCount }
    }

    private var last7Days: [(Date, Int)] {
        (0..<7).reversed().map { offset -> (Date, Int) in
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date())!
            let start = Calendar.current.startOfDay(for: date)
            let count = sessionStore.sessions
                .filter { Calendar.current.isDate($0.date, inSameDayAs: start) }
                .reduce(0) { $0 + $1.seenCount }
            return (start, count)
        }
    }

    private func dayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }
}

#Preview {
    StatsView()
        .environmentObject(SessionStore.shared)
}
