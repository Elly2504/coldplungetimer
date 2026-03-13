import SwiftUI

struct SessionCard: View {
    let session: PlungeSession
    @AppStorage(PreferenceKey.tempUnit) private var tempUnit = "celsius"

    var body: some View {
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
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func moodDelta(before: Int, after: Int) -> some View {
        let delta = after - before
        let symbol = delta > 0 ? "arrow.up" : delta < 0 ? "arrow.down" : "minus"
        let color = delta > 0 ? Color.green : delta < 0 ? Color.red : Theme.Colors.textSecondary
        return Image(systemName: symbol)
            .font(.caption)
            .foregroundStyle(color)
    }
}
