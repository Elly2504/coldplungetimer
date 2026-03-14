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
                            // Weekly chart
                            ChartView(sessions: sessions)

                            // Stats summary
                            statsBar

                            // Session list
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
            .toolbarColorScheme(.dark, for: .navigationBar)
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
}
