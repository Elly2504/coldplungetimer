import SwiftUI

struct ZoneIndicatorView: View {
    let currentZone: BenefitZone
    let elapsedSeconds: TimeInterval
    var thresholds: ZoneThresholds = .default

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Zone segments bar
            HStack(spacing: 2) {
                ForEach(BenefitZone.allCases) { zone in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(zone.color.opacity(zoneOpacity(for: zone)))
                        .frame(height: 6)
                }
            }

            // Current zone label
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: currentZone.icon)
                    .font(.system(size: 14))
                Text(currentZone.displayName)
                    .font(Theme.Fonts.zoneLabel)
            }
            .foregroundStyle(currentZone.color)

            Text(currentZone.description)
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .animation(Theme.Animations.zoneTransition, value: currentZone)
    }

    private func zoneOpacity(for zone: BenefitZone) -> Double {
        if zone == currentZone { return 1.0 }
        if thresholds.startSeconds(for: zone) < elapsedSeconds { return 0.5 }
        return 0.15
    }
}
