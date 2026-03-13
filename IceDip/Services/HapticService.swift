import UIKit

@MainActor
enum HapticService {
    static func start() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func zoneTransition() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func countdown(secondsRemaining: Int) {
        guard secondsRemaining <= 3 && secondsRemaining > 0 else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func complete() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
