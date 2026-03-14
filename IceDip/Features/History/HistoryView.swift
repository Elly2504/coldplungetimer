import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \PlungeSession.startTime, order: .reverse)
    private var sessions: [PlungeSession]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                if sessions.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: Theme.Spacing.md) {
                            // Chart with period picker
                            ChartView(sessions: sessions)

                            // Stats summary
                            statsBar

                            // Zone distribution
                            ZoneDistributionView(sessions: sessions)

                            // Mood trend
                            moodTrend

                            // Session list
                            sectionHeader("Sessions")

                            ForEach(sessions) { session in
                                SessionCard(session: session)
                                    .accessibilityElement(children: .combine)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            withAnimation {
                                                modelContext.delete(session)
                                            }
                                        } label: {
                                            Label("Delete Session", systemImage: "trash")
                                        }
                                    }
                                    .transition(.opacity.combined(with: .slide))
                            }
                        }
                        .animation(.default, value: sessions.count)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.top, Theme.Spacing.sm)
                    }
                }
            }
            .navigationTitle("History")
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "snowflake")
                .font(.system(size: 60))
                .foregroundStyle(Theme.Colors.iceBlue.opacity(0.3))
            Text("No sessions yet")
                .font(Theme.Fonts.headingSmall)
                .foregroundStyle(Theme.Colors.textSecondary)
            Text("Complete your first cold plunge to see it here")
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var statsBar: some View {
        let completedSessions = sessions.filter(\.isCompleted)
        let totalMinutes = completedSessions.reduce(0.0) { $0 + $1.duration / 60.0 }
        let avgDuration = completedSessions.isEmpty ? 0 : totalMinutes / Double(completedSessions.count)

        return HStack(spacing: Theme.Spacing.md) {
            statItem("Sessions", value: "\(completedSessions.count)")
            statItem("Total", value: "\(Int(totalMinutes))m")
            statItem("Average", value: String(format: "%.1fm", avgDuration))
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statItem(_ label: String, value: String) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(value)
                .font(Theme.Fonts.headingSmall)
                .foregroundStyle(Theme.Colors.iceBlue)
            Text(label)
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(Theme.Fonts.headingSmall)
                .foregroundStyle(Theme.Colors.textPrimary)
            Spacer()
        }
    }

    @ViewBuilder
    private var moodTrend: some View {
        let withMood = sessions.filter { $0.isCompleted && $0.moodBefore != nil && $0.moodAfter != nil }
        if !withMood.isEmpty {
            let avgBefore = Double(withMood.compactMap(\.moodBefore).reduce(0, +)) / Double(withMood.count)
            let avgAfter = Double(withMood.compactMap(\.moodAfter).reduce(0, +)) / Double(withMood.count)

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Mood Impact")
                    .font(Theme.Fonts.headingSmall)
                    .foregroundStyle(Theme.Colors.textPrimary)

                HStack(spacing: Theme.Spacing.lg) {
                    moodStat("Before", avg: avgBefore)
                    Image(systemName: "arrow.right")
                        .foregroundStyle(Theme.Colors.iceBlue)
                    moodStat("After", avg: avgAfter)
                    Spacer()
                    VStack(spacing: Theme.Spacing.xs) {
                        let delta = avgAfter - avgBefore
                        Text(delta >= 0 ? "+\(String(format: "%.1f", delta))" : String(format: "%.1f", delta))
                            .font(Theme.Fonts.headingSmall)
                            .foregroundStyle(delta >= 0 ? .green : .red)
                        Text("Change")
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func moodStat(_ label: String, avg: Double) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(moodEmoji(Int(avg.rounded())))
                .font(.title2)
            Text(String(format: "%.1f", avg))
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textPrimary)
            Text(label)
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }
}
