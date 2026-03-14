import SwiftUI
import SwiftData

struct TimerView: View {
    @Bindable var viewModel: TimerViewModel
    @Environment(NotificationService.self) private var notificationService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(PreferenceKey.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(PreferenceKey.soundEnabled) private var soundEnabled = true
    @AppStorage(PreferenceKey.tempUnit) private var tempUnit = "celsius"
    @AppStorage(PreferenceKey.defaultDuration) private var defaultDuration: TimeInterval = 120
    @AppStorage(PreferenceKey.breathingEnabled) private var breathingEnabled = true
    @State private var showStopConfirmation = false
    @State private var celebrationPulse = false
    @State private var shareImage: UIImage?

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
            } else if viewModel.showBreathing {
                BreathingView(
                    onComplete: { viewModel.breathingComplete() },
                    onSkip: { viewModel.skipBreathing() }
                )
            } else {
                setupView
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                viewModel.handleBackground()
            } else if newPhase == .active && oldPhase == .background {
                Task { await viewModel.handleForeground(hapticsEnabled: hapticsEnabled) }
            }
        }
        .onAppear {
            viewModel.selectedDuration = defaultDuration
        }
        .onChange(of: viewModel.showCompletion) { _, show in
            celebrationPulse = show
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
                .contentTransition(.numericText())
                .animation(.default, value: viewModel.selectedDuration)

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
                    .accessibilityLabel("\(label) duration")
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
                        Text(viewModel.waterTemp.formattedTemperature(unit: tempUnit))
                            .font(Theme.Fonts.headingSmall)
                            .foregroundStyle(Theme.Colors.iceBlue)
                            .frame(width: 60)
                        Slider(value: $viewModel.waterTemp, in: 0...15, step: 1)
                            .tint(Theme.Colors.iceBlue)
                            .accessibilityLabel("Water temperature")
                            .accessibilityValue(viewModel.waterTemp.formattedTemperature(unit: tempUnit))
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)

            // Mood before
            moodSelector(title: "How do you feel?", selection: $viewModel.moodBefore)

            Spacer()

            // Start button
            Button {
                viewModel.beginSession(
                    modelContext: modelContext,
                    hapticsEnabled: hapticsEnabled,
                    soundEnabled: soundEnabled,
                    notificationService: notificationService,
                    breathingEnabled: breathingEnabled
                )
            } label: {
                Text("START")
                    .font(Theme.Fonts.heading)
                    .foregroundStyle(Theme.Colors.background)
                    .frame(width: 200, height: 64)
                    .background(Theme.Colors.iceBlue)
                    .clipShape(Capsule())
            }
            .accessibilityLabel("Start cold plunge timer")
            .accessibilityHint("Starts a \(viewModel.selectedDuration.formattedMinutes) timer")
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
                .accessibilityLabel(viewModel.isPaused ? "Resume timer" : "Pause timer")

                // Stop
                Button {
                    showStopConfirmation = true
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .frame(width: 64, height: 64)
                        .background(Theme.Colors.coldShock.opacity(0.3))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Stop timer")
            }
            .padding(.bottom, Theme.Spacing.xxl)
        }
        .confirmationDialog("End Session?", isPresented: $showStopConfirmation, titleVisibility: .visible) {
            Button("End Session", role: .destructive) {
                Task {
                    await viewModel.stop(
                        modelContext: modelContext,
                        hapticsEnabled: hapticsEnabled,
                        notificationService: notificationService
                    )
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your session will be saved with the current duration.")
        }
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Theme.Colors.iceBlue.opacity(0.2), lineWidth: 3)
                    .frame(width: 130, height: 130)
                    .scaleEffect(celebrationPulse ? 1.3 : 1.0)
                    .opacity(celebrationPulse ? 0 : 0.6)

                Circle()
                    .stroke(Theme.Colors.iceBlue.opacity(0.3), lineWidth: 2)
                    .frame(width: 110, height: 110)
                    .scaleEffect(celebrationPulse ? 1.2 : 1.0)
                    .opacity(celebrationPulse ? 0.1 : 0.8)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Theme.Colors.iceBlue)
                    .shadow(color: Theme.Colors.iceBlue.opacity(0.5), radius: celebrationPulse ? 20 : 10)
            }
            .scaleEffect(viewModel.showCompletion ? 1.0 : 0.5)
            .animation(Theme.Animations.celebration, value: viewModel.showCompletion)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: celebrationPulse)

            if let session = viewModel.currentSession {
                Text(session.durationFormatted)
                    .font(Theme.Fonts.timerDisplay)
                    .foregroundStyle(Theme.Colors.iceBlue)
            }

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
                        summaryRow("Water Temp", value: temp.formattedTemperature(unit: tempUnit))
                    }
                }
                .padding()
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, Theme.Spacing.xl)
            }

            // Mood after
            moodSelector(title: "How do you feel now?", selection: $viewModel.moodAfter)

            // Session notes
            TextField("Add a note...", text: $viewModel.notes, axis: .vertical)
                .font(Theme.Fonts.body)
                .foregroundStyle(Theme.Colors.textPrimary)
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .lineLimit(3...6)
                .padding(.horizontal, Theme.Spacing.xl)

            Spacer()

            HStack(spacing: Theme.Spacing.md) {
                if let shareImage {
                    ShareLink(
                        item: Image(uiImage: shareImage),
                        preview: SharePreview("My Cold Plunge", image: Image(uiImage: shareImage))
                    ) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(Theme.Fonts.body)
                            .foregroundStyle(Theme.Colors.iceBlue)
                            .frame(height: 56)
                            .padding(.horizontal, Theme.Spacing.lg)
                            .background(Theme.Colors.surface)
                            .clipShape(Capsule())
                    }
                }

                Button {
                    if let moodAfter = viewModel.moodAfter {
                        viewModel.currentSession?.moodAfter = moodAfter
                    }
                    if !viewModel.notes.isEmpty {
                        viewModel.currentSession?.notes = viewModel.notes
                    }
                    viewModel.reset()
                } label: {
                    Text("Done")
                        .font(Theme.Fonts.headingSmall)
                        .foregroundStyle(Theme.Colors.background)
                        .frame(width: 140, height: 56)
                        .background(Theme.Colors.iceBlue)
                        .clipShape(Capsule())
                }
            }
            .padding(.bottom, Theme.Spacing.xxl)
        }
        .task(id: viewModel.showCompletion) {
            guard viewModel.showCompletion, let session = viewModel.currentSession else {
                shareImage = nil
                return
            }
            let card = ShareCardView(
                duration: session.durationFormatted,
                zone: session.zone,
                date: session.startTime
            )
            let renderer = ImageRenderer(content: card)
            renderer.scale = 3.0
            shareImage = renderer.uiImage
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
                    .accessibilityLabel("Mood rating \(rating) of 5")
                }
            }
        }
    }

}
