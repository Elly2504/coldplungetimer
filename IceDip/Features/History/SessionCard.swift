import SwiftUI

struct SessionCard: View {
    let session: PlungeSession
    @AppStorage(PreferenceKey.tempUnit) private var tempUnit = "celsius"

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack(spacing: Theme.Spacing.md) {
                // Zone color indicator
                if let zone = session.zone {
                    Circle()
                        .fill(zone.color)
                        .frame(width: 12, height: 12)
                } else {
                    Circle()
                        .fill(Theme.Colors.textSecondary)
                        .frame(width: 12, height: 12)
                }

                // Session info
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    HStack {
                        Text(session.startTime.formattedShort)
                            .font(Theme.Fonts.body)
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text(session.startTime.formattedTime)
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    HStack(spacing: Theme.Spacing.sm) {
                        if let zone = session.zone {
                            Text(zone.displayName)
                                .font(Theme.Fonts.caption)
                                .foregroundStyle(zone.color)
                        }

                        if let temp = session.waterTemp {
                            Label(temp.formattedTemperature(unit: tempUnit), systemImage: "thermometer.medium")
                                .font(Theme.Fonts.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }
                }

                Spacer()

                // Duration
                Text(session.durationFormatted)
                    .font(Theme.Fonts.headingSmall)
                    .foregroundStyle(Theme.Colors.iceBlue)

                // Mood change
                if let before = session.moodBefore, let after = session.moodAfter {
                    moodDelta(before: before, after: after)
                }
            }

            if let notes = session.notes, !notes.isEmpty {
                Text(notes)
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .lineLimit(2)
                    .padding(.leading, 12 + Theme.Spacing.md)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func moodDelta(before: Int, after: Int) -> some View {
        HStack(spacing: 2) {
            Text(moodEmoji(before))
                .font(.caption)
            Image(systemName: "arrow.right")
                .font(.system(size: 8))
                .foregroundStyle(Theme.Colors.textSecondary)
            Text(moodEmoji(after))
                .font(.caption)
        }
    }
}
