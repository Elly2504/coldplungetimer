import SwiftUI
import SwiftData
import UIKit

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
    @AppStorage(PreferenceKey.colorSchemePreference) private var colorSchemePreference = "dark"
    @AppStorage(PreferenceKey.zoneThresholds) private var zoneThresholds = ZoneThresholds.default
    @AppStorage(PreferenceKey.hasOnboarded) private var hasOnboarded = false

    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationService.self) private var notificationService
    @Environment(HealthKitService.self) private var healthKitService
    @Environment(PurchaseManager.self) private var purchaseManager

    @State private var showDeleteConfirmation = false
    @State private var showPaywall = false
    @State private var exportURL: URL?
    @State private var showExportSheet = false
    @State private var showNoSessionsAlert = false

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
                    // IceDip Pro
                    Section("IceDip Pro") {
                        if purchaseManager.isProUser {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(Theme.Colors.iceBlue)
                                Text("Pro Active")
                                    .font(Theme.Fonts.body)
                                    .foregroundStyle(Theme.Colors.textPrimary)
                                Spacer()
                            }
                            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                Link("Manage Subscription", destination: url)
                            }
                        } else {
                            Button {
                                showPaywall = true
                            } label: {
                                HStack {
                                    Image(systemName: "snowflake")
                                        .foregroundStyle(Theme.Colors.iceBlue)
                                    Text("Upgrade to Pro")
                                        .foregroundStyle(Theme.Colors.iceBlue)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(Theme.Colors.textSecondary)
                                }
                            }
                            Button {
                                Task { await purchaseManager.restorePurchases() }
                            } label: {
                                Text("Restore Purchases")
                            }
                        }
                    }

                    // Appearance
                    Section("Appearance") {
                        Picker("Theme", selection: $colorSchemePreference) {
                            Text("Dark").tag("dark")
                            if purchaseManager.isProUser {
                                Text("Light").tag("light")
                                Text("System").tag("system")
                            } else {
                                Label("Light", systemImage: "lock.fill").tag("light_locked")
                                Label("System", systemImage: "lock.fill").tag("system_locked")
                            }
                        }
                        .onChange(of: colorSchemePreference) { _, newValue in
                            if !purchaseManager.isProUser && (newValue == "light_locked" || newValue == "system_locked") {
                                colorSchemePreference = "dark"
                                showPaywall = true
                            }
                        }
                    }

                    // Timer Defaults
                    Section("Timer") {
                        Picker("Default Duration", selection: $defaultDuration) {
                            ForEach(durationOptions, id: \.1) { label, value in
                                Text(label).tag(value)
                            }
                        }
                        proSettingsRow("Breathing Exercise") {
                            Toggle("Breathing Exercise", isOn: $breathingEnabled)
                        }
                    }

                    // Zone Thresholds
                    if purchaseManager.isProUser {
                        Section("Zone Thresholds") {
                            zoneThresholdRow(
                                zone: .adaptation,
                                value: $zoneThresholds.adaptation,
                                min: 10,
                                max: zoneThresholds.dopamineZone - 10
                            )
                            zoneThresholdRow(
                                zone: .dopamineZone,
                                value: $zoneThresholds.dopamineZone,
                                min: zoneThresholds.adaptation + 10,
                                max: zoneThresholds.metabolicBoost - 10
                            )
                            zoneThresholdRow(
                                zone: .metabolicBoost,
                                value: $zoneThresholds.metabolicBoost,
                                min: zoneThresholds.dopamineZone + 10,
                                max: zoneThresholds.deepResilience - 10
                            )
                            zoneThresholdRow(
                                zone: .deepResilience,
                                value: $zoneThresholds.deepResilience,
                                min: zoneThresholds.metabolicBoost + 10,
                                max: 600
                            )

                            if zoneThresholds != .default {
                                Button("Reset to Defaults") {
                                    zoneThresholds = .default
                                }
                            }
                        }
                        .onChange(of: zoneThresholds) { _, newValue in
                            UserDefaults(suiteName: SharedModelContainer.appGroupIdentifier)?
                                .set(newValue.rawValue, forKey: PreferenceKey.zoneThresholds)
                        }
                    } else {
                        Section {
                            Button { showPaywall = true } label: {
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundStyle(Theme.Colors.iceBlue)
                                    Text("Zone Thresholds")
                                        .foregroundStyle(Theme.Colors.textPrimary)
                                    Spacer()
                                    Text("Pro")
                                        .font(Theme.Fonts.caption)
                                        .foregroundStyle(Theme.Colors.background)
                                        .padding(.horizontal, Theme.Spacing.sm)
                                        .padding(.vertical, Theme.Spacing.xs)
                                        .background(Theme.Colors.iceBlue)
                                        .clipShape(Capsule())
                                }
                            }
                        }
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
                        proSettingsRow("Ambient Sound") {
                            Toggle("Play During Plunge", isOn: $ambientSoundEnabled)
                        }
                        if ambientSoundEnabled && purchaseManager.isProUser {
                            Picker("Sound", selection: $selectedAmbientSound) {
                                ForEach(AmbientSound.allCases) { sound in
                                    Text(sound.displayName).tag(sound.rawValue)
                                }
                            }
                        }
                    }

                    // Notifications
                    Section("Notifications") {
                        proSettingsRow("Daily Reminder") {
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
                        }

                        if reminderEnabled && purchaseManager.isProUser {
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
                            proSettingsRow("Health") {
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
                            }

                            if healthKitEnabled && !healthKitService.isAuthorized && purchaseManager.isProUser {
                                Text("Open Settings \u{203A} Health \u{203A} IceDip to enable access.")
                                    .font(Theme.Fonts.caption)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                        }
                    }

                    // Goals
                    Section("Weekly Goal") {
                        proSettingsRow("Weekly Goal") {
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
                    }

                    // Data
                    Section("Data") {
                        if purchaseManager.isProUser {
                            Button {
                                exportCSV()
                            } label: {
                                Label("Export Sessions", systemImage: "square.and.arrow.up")
                            }
                        } else {
                            Button { showPaywall = true } label: {
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundStyle(Theme.Colors.iceBlue)
                                    Label("Export Sessions", systemImage: "square.and.arrow.up")
                                        .foregroundStyle(Theme.Colors.textPrimary)
                                    Spacer()
                                    Text("Pro")
                                        .font(Theme.Fonts.caption)
                                        .foregroundStyle(Theme.Colors.background)
                                        .padding(.horizontal, Theme.Spacing.sm)
                                        .padding(.vertical, Theme.Spacing.xs)
                                        .background(Theme.Colors.iceBlue)
                                        .clipShape(Capsule())
                                }
                            }
                        }

                        Button("Delete All Data", role: .destructive) {
                            showDeleteConfirmation = true
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
                        Button("Show Tutorial") {
                            hasOnboarded = false
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .confirmationDialog(
                    "Delete All Data?",
                    isPresented: $showDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Delete Everything", role: .destructive) {
                        deleteAllData()
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("This will permanently delete all sessions and reset all settings. This cannot be undone.")
                }
            }
            .navigationTitle("Settings")
            .tint(Theme.Colors.iceBlue)
            .sheet(isPresented: $showPaywall) {
                ProPaywallView()
            }
            .sheet(isPresented: $showExportSheet) {
                if let exportURL {
                    ActivityView(items: [exportURL])
                }
            }
            .alert("No sessions to export.", isPresented: $showNoSessionsAlert) {
                Button("OK", role: .cancel) { }
            }
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

    private func deleteAllData() {
        // Delete all SwiftData sessions
        do {
            try modelContext.delete(model: PlungeSession.self)
        } catch {
            // Best-effort deletion
        }

        // Reset AppStorage keys (not hasOnboarded — user already knows the app)
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: PreferenceKey.defaultDuration)
        defaults.removeObject(forKey: PreferenceKey.tempUnit)
        defaults.removeObject(forKey: PreferenceKey.hapticsEnabled)
        defaults.removeObject(forKey: PreferenceKey.soundEnabled)
        defaults.removeObject(forKey: PreferenceKey.reminderEnabled)
        defaults.removeObject(forKey: PreferenceKey.reminderHour)
        defaults.removeObject(forKey: PreferenceKey.reminderMinute)
        defaults.removeObject(forKey: PreferenceKey.weeklyGoalSessions)
        defaults.removeObject(forKey: PreferenceKey.breathingEnabled)
        defaults.removeObject(forKey: PreferenceKey.healthKitEnabled)
        defaults.removeObject(forKey: PreferenceKey.ambientSoundEnabled)
        defaults.removeObject(forKey: PreferenceKey.selectedAmbientSound)
        defaults.removeObject(forKey: PreferenceKey.colorSchemePreference)
        defaults.removeObject(forKey: PreferenceKey.zoneThresholds)

        // Clear app group UserDefaults (widget) — preserve Pro status
        let appGroupDefaults = UserDefaults(suiteName: SharedModelContainer.appGroupIdentifier)
        let proStatus = appGroupDefaults?.bool(forKey: PreferenceKey.isProUser) ?? false
        appGroupDefaults?.removePersistentDomain(forName: SharedModelContainer.appGroupIdentifier)
        appGroupDefaults?.set(proStatus, forKey: PreferenceKey.isProUser)

        // Re-sync @AppStorage bindings to defaults
        defaultDuration = 120
        tempUnit = "celsius"
        hapticsEnabled = true
        soundEnabled = true
        reminderEnabled = false
        reminderHour = 7
        reminderMinute = 0
        weeklyGoalSessions = 3
        breathingEnabled = true
        healthKitEnabled = false
        ambientSoundEnabled = false
        selectedAmbientSound = "ocean"
        colorSchemePreference = "dark"
        zoneThresholds = .default

        // Cancel scheduled notifications
        notificationService.cancelDailyReminder()
    }

    private func exportCSV() {
        let descriptor = FetchDescriptor<PlungeSession>(
            predicate: #Predicate { $0.isCompleted },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        guard let sessions = try? modelContext.fetch(descriptor), !sessions.isEmpty else {
            showNoSessionsAlert = true
            return
        }
        let csv = CSVExportService.generateCSV(sessions: sessions)
        if let url = CSVExportService.writeToTemporaryFile(csv: csv) {
            exportURL = url
            showExportSheet = true
        }
    }

    @ViewBuilder
    private func proSettingsRow<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        if purchaseManager.isProUser {
            content()
        } else {
            Button { showPaywall = true } label: {
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(Theme.Colors.iceBlue)
                    Text(label)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                    Text("Pro")
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.background)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(Theme.Colors.iceBlue)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private func zoneThresholdRow(zone: BenefitZone, value: Binding<TimeInterval>, min: TimeInterval, max: TimeInterval) -> some View {
        Stepper(value: value, in: min...max, step: 5) {
            HStack(spacing: Theme.Spacing.sm) {
                Circle()
                    .fill(zone.color)
                    .frame(width: 10, height: 10)
                Text(zone.displayName)
                Spacer()
                Text("\(Int(value.wrappedValue))s")
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
    }
}

// MARK: - Activity View

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
