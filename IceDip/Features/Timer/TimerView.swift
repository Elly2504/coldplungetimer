import SwiftUI
import SwiftData

struct TimerView: View {
    @State private var viewModel = TimerViewModel()
    @State private var notificationService = NotificationService()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(PreferenceKey.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(PreferenceKey.defaultDuration) private var defaultDuration: TimeInterval = 120

    private let durationPresets: [(String, TimeInterval)] = [
        ("1m", 60),
        ("2m", 120),
        ("3m", 180),
        ("5m", 300),
        ("10m", 600)
    ]

    var body: some View {
        ZStack {
            ZoneGradientBackground(
                zone: viewModel.currentZone,
                isActive: viewModel.isRunning
            )

            if viewModel.showCompletion {
                completionView
            } else if viewModel.isRunning {
                activeTimerView
            } else {
                setupView
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                viewModel.handleBackground()
            } else if newPhase == .active && oldPhase == .background {
                viewModel.handleForeground(hapticsEnabled: hapticsEnabled)
            }
        }
        .onAppear {
            viewModel.selectedDuration = defaultDuration
            Task { await notificationService.checkPermission() }
        }
    }

    // MARK: - Setup View (Before Start)

    private var setupView: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            // Duration display
            Text(viewModel.selectedDuration.formattedTimer)
                .font(Theme.Fonts.timerDisplay)
                .foregroundStyle(Theme.Colors.textPrimary)

            // Duration presets
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(durationPresets, id: \.1) { label, duration in
                    Button {
                        viewModel.selectedDuration = duration
                        if hapticsEnabled { HapticService.selection() }
                    } label: {
                        Text(label)
                            .font(Theme.Fonts.zoneLabel)
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.vertical, Theme.Spacing.sm)
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
                }
            }

            // Water temperature toggle
            VStack(spacing: Theme.Spacing.sm) {
                Toggle(isOn: $viewModel.hasWaterTemp) {
                    Label("Water Temperature", systemImage: "thermometer.medium")
                        .font(Theme.Fonts.body)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .tint(Theme.Colors.iceBlue)

                if viewModel.hasWaterTemp {
                    HStack {
                        Text("\(Int(viewModel.waterTemp))°C")
                            .font(Theme.Fonts.headingSmall)
                            .foregroundStyle(Theme.Colors.iceBlue)
                            .frame(width: 50)
                        Slider(value: $viewModel.waterTemp, in: 0...15, step: 1)
                            .tint(Theme.Colors.iceBlue)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)

            // Mood before
            moodSelector(title: "How do you feel?", selection: $viewModel.moodBefore)

            Spacer()

            // Start button
            Button {
                Task { await notificationService.requestPermission() }
                viewModel.start(
                    modelContext: modelContext,
                    hapticsEnabled: hapticsEnabled,
                    notificationService: notificationService
                )
            } label: {
                Text("START")
                    .font(Theme.Fonts.heading)
                    .foregroundStyle(Theme.Colors.background)
                    .frame(width: 200, height: 64)
                    .background(Theme.Colors.iceBlue)
                    .clipShape(Capsule())
            }
            .padding(.bottom, Theme.Spacing.xxl)
        }
    }

    // MARK: - Active Timer View

    private var activeTimerView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            CircularTimerView(
                progress: viewModel.progress,
                timeText: viewModel.timeFormatted,
                zone: viewModel.currentZone,
                isRunning: viewModel.isRunning
            )
            .frame(width: 280, height: 280)

            ZoneIndicatorView(
                currentZone: viewModel.currentZone,
                elapsedSeconds: viewModel.elapsedSeconds
            )
            .padding(.horizontal, Theme.Spacing.xl)

            Spacer()

            // Control buttons
            HStack(spacing: Theme.Spacing.xl) {
                // Pause/Resume
                Button {
                    if viewModel.isPaused {
                        viewModel.resume(hapticsEnabled: hapticsEnabled)
                    } else {
                        viewModel.pause()
                    }
                } label: {
                    Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .frame(width: 64, height: 64)
                        .background(Theme.Colors.surface)
                        .clipShape(Circle())
                }

                // Stop
                Button {
                    viewModel.stop(
                        modelContext: modelContext,
                        hapticsEnabled: hapticsEnabled,
                        notificationService: notificationService
                    )
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .frame(width: 64, height: 64)
                        .background(Theme.Colors.coldShock.opacity(0.3))
                        .clipShape(Circle())
                }
            }
            .padding(.bottom, Theme.Spacing.xxl)
        }
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Theme.Colors.iceBlue)
                .scaleEffect(viewModel.showCompletion ? 1.0 : 0.5)
                .animation(Theme.Animations.celebration, value: viewModel.showCompletion)

            Text("Plunge Complete!")
                .font(Theme.Fonts.heading)
                .foregroundStyle(Theme.Colors.textPrimary)

            // Session summary
            if let session = viewModel.currentSession {
                VStack(spacing: Theme.Spacing.sm) {
                    summaryRow("Duration", value: session.durationFormatted)
                    if let zone = session.zone {
                        summaryRow("Zone Reached", value: zone.displayName, color: zone.color)
                    }
                    if let temp = session.waterTemp {
                        summaryRow("Water Temp", value: "\(Int(temp))°C")
                    }
                }
                .padding()
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, Theme.Spacing.xl)
            }

            // Mood after
            moodSelector(title: "How do you feel now?", selection: $viewModel.moodAfter)

            Spacer()

            Button {
                // Save mood after if selected
                if let moodAfter = viewModel.moodAfter {
                    viewModel.currentSession?.moodAfter = moodAfter
                }
                viewModel.reset()
            } label: {
                Text("Done")
                    .font(Theme.Fonts.headingSmall)
                    .foregroundStyle(Theme.Colors.background)
                    .frame(width: 200, height: 56)
                    .background(Theme.Colors.iceBlue)
                    .clipShape(Capsule())
            }
            .padding(.bottom, Theme.Spacing.xxl)
        }
    }

    // MARK: - Helpers

    private func summaryRow(_ label: String, value: String, color: Color = Theme.Colors.textPrimary) -> some View {
        HStack {
            Text(label)
                .font(Theme.Fonts.body)
                .foregroundStyle(Theme.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(Theme.Fonts.body)
                .foregroundStyle(color)
        }
    }

    private func moodSelector(title: String, selection: Binding<Int?>) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text(title)
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textSecondary)

            HStack(spacing: Theme.Spacing.md) {
                ForEach(1...5, id: \.self) { rating in
                    Button {
                        selection.wrappedValue = rating
                        if hapticsEnabled { HapticService.selection() }
                    } label: {
                        Text(moodEmoji(rating))
                            .font(.title2)
                            .padding(Theme.Spacing.sm)
                            .background(
                                selection.wrappedValue == rating
                                    ? Theme.Colors.iceBlue.opacity(0.2)
                                    : Color.clear
                            )
                            .clipShape(Circle())
                    }
                }
            }
        }
    }

    private func moodEmoji(_ rating: Int) -> String {
        switch rating {
        case 1: "😰"
        case 2: "😕"
        case 3: "😐"
        case 4: "😊"
        case 5: "🤩"
        default: "😐"
        }
    }
}
