import SwiftUI

struct ZoneGradientBackground: View {
    let zone: BenefitZone
    let isActive: Bool

    var body: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .animation(Theme.Animations.zoneTransition, value: zone)
    }

    private var gradientColors: [Color] {
        if isActive {
            return [
                Theme.Colors.background,
                zone.color.opacity(0.3),
                Theme.Colors.background
            ]
        }
        return [Theme.Colors.background, Theme.Colors.background]
    }
}
