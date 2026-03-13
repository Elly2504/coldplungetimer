import SwiftUI

enum Theme {
    enum Colors {
        static let background = Color(hex: "0A1628")
        static let surface = Color(hex: "111D2E")
        static let iceBlue = Color(hex: "64D2FF")
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.6)

        // Zone colors
        static let coldShock = Color(hex: "FF6B35")
        static let adaptation = Color(hex: "FFB800")
        static let dopamineZone = Color(hex: "00E5FF")
        static let metabolicBoost = Color(hex: "1565C0")
        static let deepResilience = Color(hex: "B0BEC5")
    }

    enum Fonts {
        static let timerDisplay = Font.system(size: 72, weight: .light, design: .monospaced)
        static let timerDisplaySmall = Font.system(size: 48, weight: .light, design: .monospaced)
        static let heading = Font.system(.title, design: .rounded, weight: .bold)
        static let headingSmall = Font.system(.title3, design: .rounded, weight: .semibold)
        static let body = Font.system(.body, design: .rounded)
        static let caption = Font.system(.caption, design: .rounded)
        static let zoneLabel = Font.system(.subheadline, design: .rounded, weight: .semibold)
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    enum Animations {
        static let zoneTransition = Animation.easeInOut(duration: 0.8)
        static let timerTick = Animation.linear(duration: 0.1)
        static let celebration = Animation.spring(response: 0.5, dampingFraction: 0.6)
    }
}
