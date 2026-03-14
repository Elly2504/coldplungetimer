import SwiftUI

struct WatchTimerView: View {
    @State private var viewModel = WatchTimerViewModel()
    @Environment(WatchConnectivityService.self) private var connectivityService
    @Environment(\.scenePhase) private var scenePhase

    private let durationPresets: [(String, TimeInterval)] = [
        ("1m", 60), ("2m", 120), ("3m", 180), ("5m", 300)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                if viewModel.isComplete {
                    completionView
                } else if viewModel.isRunning {
                    activeTimerView
                } else {
                    setupView
                }
            }
        }
        .onAppear {
            viewModel.connectivityService = connectivityService
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                viewModel.handleBackground()
            } else if newPhase == .active && oldPhase == .background {
                viewModel.handleForeground()
            }
        }
    }

    // MARK: - Setup

    private var setupView: some View {
        VStack(spacing: 12) {
            Text(viewModel.selectedDuration.formattedTimer)
                .font(.system(size: 36, weight: .light, design: .monospaced))
                .foregroundStyle(Theme.Colors.iceBlue)
                .contentTransition(.numericText())
                .animation(.default, value: viewModel.selectedDuration)

            // Duration presets
            HStack(spacing: 6) {
                ForEach(durationPresets, id: \.1) { label, duration in
                    Button {
                        viewModel.selectedDuration = duration
                    } label: {
                        Text(label)
                            .font(.system(.caption2, design: .rounded, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                viewModel.selectedDuration == duration
                                    ? Theme.Colors.iceBlue
                                    : Theme.Colors.surface
                            )
                            .foregroundStyle(
                                viewModel.selectedDuration == duration
                                    ? Theme.Colors.background
                                    : Theme.Colors.textPrimary
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                viewModel.start()
            } label: {
                Text("START")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(Theme.Colors.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Theme.Colors.iceBlue)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
        }
    }

    // MARK: - Active Timer

    private var activeTimerView: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Theme.Colors.surface, lineWidth: 6)

                Circle()
                    .trim(from: 0, to: viewModel.progress)
                    .stroke(viewModel.currentZone.color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: viewModel.progress)

                VStack(spacing: 2) {
                    Text(viewModel.timeFormatted)
                        .font(.system(size: 28, weight: .light, design: .monospaced))
                        .foregroundStyle(Theme.Colors.textPrimary)

                    HStack(spacing: 4) {
                        Image(systemName: viewModel.currentZone.icon)
                            .font(.caption2)
                        Text(viewModel.currentZone.displayName)
                            .font(.system(.caption2, design: .rounded, weight: .semibold))
                    }
                    .foregroundStyle(viewModel.currentZone.color)
                }
            }
            .frame(width: 130, height: 130)

            HStack(spacing: 16) {
                Button {
                    if viewModel.isPaused {
                        viewModel.resume()
                    } else {
                        viewModel.pause()
                    }
                } label: {
                    Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(Theme.Colors.surface)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button {
                    _ = viewModel.stop()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(Theme.Colors.coldShock.opacity(0.3))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Completion

    private var completionView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(Theme.Colors.iceBlue)

            Text("Complete!")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(Theme.Colors.textPrimary)

            Text(viewModel.elapsedSeconds.formattedTimer)
                .font(.system(size: 24, weight: .light, design: .monospaced))
                .foregroundStyle(Theme.Colors.iceBlue)

            HStack(spacing: 4) {
                Image(systemName: viewModel.currentZone.icon)
                    .font(.caption2)
                Text(viewModel.currentZone.displayName)
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
            }
            .foregroundStyle(viewModel.currentZone.color)

            Button {
                viewModel.reset()
            } label: {
                Text("Done")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(Theme.Colors.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Theme.Colors.iceBlue)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
        }
    }
}
