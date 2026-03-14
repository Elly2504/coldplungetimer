import SwiftUI

struct WatchStreakView: View {
    @Environment(WatchConnectivityService.self) private var connectivityService

    var body: some View {
        let streak = connectivityService.streakData

        ScrollView {
            VStack(spacing: 12) {
                // Current streak
                VStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.Colors.iceBlue)

                    Text("\(streak.currentStreak)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text("Day Streak")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                Divider()
                    .background(Theme.Colors.surface)

                // Stats
                HStack(spacing: 16) {
                    statItem(value: "\(streak.bestStreak)", label: "Best")
                    statItem(value: "\(streak.sessionsThisWeek)", label: "This Week")
                }

                if let lastDate = streak.lastSessionDate {
                    Text("Last: \(lastDate.formattedShort)")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .padding(.vertical, 8)
        }
        .containerBackground(Theme.Colors.background.gradient, for: .navigation)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(Theme.Colors.textPrimary)
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }
}
