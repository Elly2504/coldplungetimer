import SwiftUI

struct SettingsView: View {
    @AppStorage(PreferenceKey.defaultDuration) private var defaultDuration: TimeInterval = 120
    @AppStorage(PreferenceKey.tempUnit) private var tempUnit = "celsius"
    @AppStorage(PreferenceKey.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(PreferenceKey.soundEnabled) private var soundEnabled = true
    @AppStorage(PreferenceKey.reminderEnabled) private var reminderEnabled = false
    @AppStorage(PreferenceKey.reminderHour) private var reminderHour = 7
    @AppStorage(PreferenceKey.reminderMinute) private var reminderMinute = 0
    @AppStorage(PreferenceKey.weeklyGoalSessions) private var weeklyGoalSessions = 3
    @AppStorage(PreferenceKey.breathingEnabled) private var breathingEnabled = true
    @AppStorage(PreferenceKey.healthKitEnabled) private var healthKitEnabled = false
    @AppStorage(PreferenceKey.ambientSoundEnabled) private var ambientSoundEnabled = false
    @AppStorage(PreferenceKey.selectedAmbientSound) private var selectedAmbientSound = "ocean"

    @Environment(NotificationService.self) private var notificationService
    @Environment(HealthKitService.self) private var healthKitService

    private let durationOptions: [(String, TimeInterval)] = [
        ("30 seconds", 30),
        ("1 minute", 60),
        ("2 minutes", 120),
        ("3 minutes", 180),
        ("5 minutes", 300),
        ("10 minutes", 600)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                List {
                    // Timer Defaults
                    Section("Timer") {
                        Picker("Default Duration", selection: $defaultDuration) {
                            ForEach(durationOptions, id: \.1) { label, value in
                                Text(label).tag(value)
                            }
                        }
                        Toggle("Breathing Exercise", isOn: $breathingEnabled)
                    }

                    // Units
                    Section("Units") {
                        Picker("Temperature", selection: $tempUnit) {
                            Text("Celsius (°C)").tag("celsius")
                            Text("Fahrenheit (°F)").tag("fahrenheit")
                        }
                    }

                    // Feedback
                    Section("Feedback") {
                        Toggle("Haptic Feedback", isOn: $hapticsEnabled)
                        Toggle("Sound Effects", isOn: $soundEnabled)
                    }

                    // Ambient Sound
                    Section("Ambient Sound") {
                        Toggle("Play During Plunge", isOn: $ambientSoundEnabled)
                        if ambientSoundEnabled {
                            Picker("Sound", selection: $selectedAmbientSound) {
                                ForEach(AmbientSound.allCases) { sound in
                                    Text(sound.displayName).tag(sound.rawValue)
                                }
                            }
                        }
                    }

                    // Notifications
                    Section("Notifications") {
                        Toggle("Daily Reminder", isOn: $reminderEnabled)
                            .onChange(of: reminderEnabled) { _, enabled in
                                if enabled {
                                    Task { await notificationService.requestPermission() }
                                    notificationService.scheduleDailyReminder(
                                        hour: reminderHour,
                                        minute: reminderMinute,
                                        soundEnabled: soundEnabled
                                    )
                                } else {
                                    notificationService.cancelDailyReminder()
                                }
                            }

                        if reminderEnabled {
                            DatePicker(
                                "Reminder Time",
                                selection: reminderDateBinding,
                                displayedComponents: .hourAndMinute
                            )
                            .onChange(of: reminderHour) { _, _ in updateReminder() }
                            .onChange(of: reminderMinute) { _, _ in updateReminder() }
                        }
                    }

                    // Health
                    if healthKitService.isAvailable {
                        Section("Health") {
                            Toggle("Save to Apple Health", isOn: $healthKitEnabled)
                                .onChange(of: healthKitEnabled) { _, enabled in
                                    if enabled {
                                        Task {
                                            await healthKitService.requestAuthorization()
                                            if !healthKitService.isAuthorized {
                                                healthKitEnabled = false
                                            }
                                        }
                                    }
                                }

                            if healthKitEnabled && !healthKitService.isAuthorized {
                                Text("Open Settings \u{203A} Health \u{203A} IceDip to enable access.")
                                    .font(Theme.Fonts.caption)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                        }
                    }

                    // Goals
                    Section("Weekly Goal") {
                        Stepper(
                            "\(weeklyGoalSessions) sessions per week",
                            value: $weeklyGoalSessions,
                            in: 1...14
                        )
                        .onChange(of: weeklyGoalSessions) { _, newValue in
                            UserDefaults(suiteName: SharedModelContainer.appGroupIdentifier)?
                                .set(newValue, forKey: PreferenceKey.weeklyGoalSessions)
                        }
                    }

                    // About
                    Section("About") {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .tint(Theme.Colors.iceBlue)
        }
    }

    private var reminderDateBinding: Binding<Date> {
        Binding<Date>(
            get: {
                var components = DateComponents()
                components.hour = reminderHour
                components.minute = reminderMinute
                return Calendar.current.date(from: components) ?? .now
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                reminderHour = components.hour ?? 7
                reminderMinute = components.minute ?? 0
            }
        )
    }

    private func updateReminder() {
        guard reminderEnabled else { return }
        notificationService.cancelDailyReminder()
        notificationService.scheduleDailyReminder(hour: reminderHour, minute: reminderMinute, soundEnabled: soundEnabled)
    }
}
