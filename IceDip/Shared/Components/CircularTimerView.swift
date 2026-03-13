import SwiftUI

struct CircularTimerView: View {
    let progress: Double
    let timeText: String
    let zone: BenefitZone
    let isRunning: Bool

    private let lineWidth: CGFloat = 8

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(
                    Theme.Colors.surface,
                    lineWidth: lineWidth
                )

            // Progress ring
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    zone.color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(Theme.Animations.timerTick, value: progress)

            // Center content
            VStack(spacing: Theme.Spacing.xs) {
                Text(timeText)
                    .font(Theme.Fonts.timerDisplay)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .contentTransition(.numericText())
                    .monospacedDigit()

                if isRunning {
                    Text(zone.displayName)
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(zone.color)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(timeText) remaining, \(zone.displayName) zone")
        .accessibilityValue("\(Int(progress * 100)) percent complete")
    }
}
