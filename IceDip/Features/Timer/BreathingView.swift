import SwiftUI

struct BreathingView: View {
    let onComplete: () -> Void
    let onSkip: () -> Void

    @State private var currentPhase: BreathingPhase = .inhale
    @State private var circleScale: CGFloat = 0.6
    @State private var currentCycle = 1
    @State private var breathingTask: Task<Void, Never>?

    private let totalCycles = 3
    private let phaseDuration: TimeInterval = 4.0

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            Text("Prepare Your Breath")
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textSecondary)

            Text(currentPhase.label)
                .font(Theme.Fonts.heading)
                .foregroundStyle(Theme.Colors.textPrimary)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: currentPhase)

            ZStack {
                Circle()
                    .fill(Theme.Colors.iceBlue.opacity(0.08))
                    .frame(width: 240, height: 240)
                    .scaleEffect(circleScale)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.Colors.iceBlue.opacity(0.4), Theme.Colors.iceBlue.opacity(0.15)],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(circleScale)

                Circle()
                    .stroke(Theme.Colors.iceBlue.opacity(0.6), lineWidth: 2)
                    .frame(width: 200, height: 200)
                    .scaleEffect(circleScale)
            }
            .frame(width: 280, height: 280)

            Text("Cycle \(currentCycle) of \(totalCycles)")
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textSecondary)

            Spacer()

            Button {
                breathingTask?.cancel()
                onSkip()
            } label: {
                Text("Skip")
                    .font(Theme.Fonts.body)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .frame(height: 44)
                    .padding(.horizontal, Theme.Spacing.xl)
            }
            .padding(.bottom, Theme.Spacing.xxl)
        }
        .onAppear { startBreathingCycles() }
        .onDisappear { breathingTask?.cancel() }
    }

    private func startBreathingCycles() {
        breathingTask = Task { @MainActor in
            for cycle in 1...totalCycles {
                guard !Task.isCancelled else { return }
                currentCycle = cycle

                // Inhale
                currentPhase = .inhale
                withAnimation(.easeInOut(duration: phaseDuration)) {
                    circleScale = 1.0
                }
                try? await Task.sleep(for: .seconds(phaseDuration))
                guard !Task.isCancelled else { return }

                // Hold
                currentPhase = .hold
                try? await Task.sleep(for: .seconds(phaseDuration))
                guard !Task.isCancelled else { return }

                // Exhale
                currentPhase = .exhale
                withAnimation(.easeInOut(duration: phaseDuration)) {
                    circleScale = 0.6
                }
                try? await Task.sleep(for: .seconds(phaseDuration))
                guard !Task.isCancelled else { return }
            }

            onComplete()
        }
    }
}

private enum BreathingPhase: String {
    case inhale, hold, exhale

    var label: String {
        switch self {
        case .inhale: String(localized: "Breathe In")
        case .hold: String(localized: "Hold")
        case .exhale: String(localized: "Breathe Out")
        }
    }
}
