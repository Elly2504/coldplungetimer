import SwiftUI
import SwiftData

struct StreakView: View {
    @Query(sort: \PlungeSession.startTime, order: .reverse)
    private var sessions: [PlungeSession]
    @AppStorage(PreferenceKey.weeklyGoalSessions) private var weeklyGoal = 3

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Current streak
                        streakCard

                        // Last 7 days
                        weekOverview

                        // Weekly goal progress
                        weeklyGoalCard

                        // Best streak
                        bestStreakCard
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.sm)
                }
            }
            .navigationTitle("Streak")
        }
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "flame.fill")
                .font(.system(size: 48))
                .foregroundStyle(currentStreak > 0 ? Theme.Colors.coldShock : Theme.Colors.textSecondary)

            Text("\(currentStreak)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.Colors.textPrimary)

            Text("Day Streak")
                .font(Theme.Fonts.body)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xl)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(currentStreak) day streak")
    }

    // MARK: - Week Overview

    private var weekOverview: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Last 7 Days")
                .font(Theme.Fonts.zoneLabel)
                .foregroundStyle(Theme.Colors.textSecondary)

            HStack(spacing: Theme.Spacing.sm) {
                ForEach(0..<7, id: \.self) { daysAgo in
                    let date = Date().daysAgo(6 - daysAgo)
                    let hasSession = hasSession(on: date)
                    VStack(spacing: Theme.Spacing.xs) {
                        Circle()
                            .fill(hasSession ? Theme.Colors.iceBlue : Theme.Colors.surface)
                            .frame(width: 36, height: 36)
                            .overlay {
                                if hasSession {
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundStyle(Theme.Colors.background)
                                }
                            }
                        Text(date.formattedWeekday)
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Weekly Goal

    private var weeklyGoalCard: some View {
        let sessionsThisWeek = sessionsThisWeekCount
        let goalProgress = min(Double(sessionsThisWeek) / Double(max(weeklyGoal, 1)), 1.0)

        return VStack(spacing: Theme.Spacing.sm) {
            HStack {
                Text("Weekly Goal")
                    .font(Theme.Fonts.zoneLabel)
                    .foregroundStyle(Theme.Colors.textSecondary)
                Spacer()
                Text("\(sessionsThisWeek)/\(weeklyGoal)")
                    .font(Theme.Fonts.headingSmall)
                    .foregroundStyle(Theme.Colors.iceBlue)
            }

            ProgressView(value: goalProgress)
                .tint(Theme.Colors.iceBlue)

            if sessionsThisWeek >= weeklyGoal {
                Text("Goal reached!")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.iceBlue)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Best Streak

    private var bestStreakCard: some View {
        HStack {
            Image(systemName: "trophy.fill")
                .font(.title2)
                .foregroundStyle(Theme.Colors.adaptation)
            VStack(alignment: .leading) {
                Text("Best Streak")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                Text("\(bestStreak) days")
                    .font(Theme.Fonts.headingSmall)
                    .foregroundStyle(Theme.Colors.textPrimary)
            }
            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Streak Calculations

    private var calculator: StreakCalculator {
        StreakCalculator(sessions: sessions)
    }

    private var currentStreak: Int { calculator.currentStreak }
    private var bestStreak: Int { calculator.bestStreak }
    private var sessionsThisWeekCount: Int { calculator.sessionsThisWeekCount }

    private func hasSession(on date: Date) -> Bool {
        calculator.hasSession(on: date)
    }

}
