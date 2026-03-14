import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationService.self) private var notificationService
    @Environment(HealthKitService.self) private var healthKitService
    @Environment(AmbientSoundService.self) private var ambientSoundService
    @Environment(PhoneConnectivityService.self) private var phoneConnectivityService
    @State private var timerViewModel = TimerViewModel()
    @AppStorage(PreferenceKey.hasOnboarded) private var hasOnboarded = false
    @AppStorage("pendingShortcutStart") private var pendingShortcutStart = false
    @State private var selectedTab = 0
    @State private var orphanedSessions: [PlungeSession] = []
    @State private var showOrphanAlert = false

    var body: some View {
        if hasOnboarded {
            TabView(selection: $selectedTab) {
                TimerView(viewModel: timerViewModel)
                    .tabItem { Label("Timer", systemImage: "timer") }
                    .badge(timerViewModel.isRunning ? 1 : 0)
                    .tag(0)
                HistoryView()
                    .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                    .tag(1)
                StreakView()
                    .tabItem { Label("Streak", systemImage: "flame.fill") }
                    .tag(2)
                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                    .tag(3)
            }
            .tint(Theme.Colors.iceBlue)
            .task {
                await notificationService.requestPermission()
                healthKitService.checkAuthorizationStatus()
                checkForOrphanedSessions()
                if pendingShortcutStart {
                    pendingShortcutStart = false
                    try? await Task.sleep(for: .milliseconds(500))
                    startFromShortcut()
                }
            }
            .onChange(of: pendingShortcutStart) { _, shouldStart in
                guard shouldStart else { return }
                pendingShortcutStart = false
                startFromShortcut()
            }
            .alert("Incomplete Session Found", isPresented: $showOrphanAlert) {
                Button("Save") { saveOrphanedSessions() }
                Button("Discard", role: .destructive) { discardOrphanedSessions() }
            } message: {
                if orphanedSessions.count == 1 {
                    Text("An incomplete session was found. Would you like to save it or discard it?")
                } else {
                    Text("\(orphanedSessions.count) incomplete sessions were found. Would you like to save them or discard them?")
                }
            }
        } else {
            OnboardingView()
        }
    }

    private func startFromShortcut() {
        guard !timerViewModel.isRunning else { return }
        selectedTab = 0

        let defaults = UserDefaults.standard
        let shortcutDuration = defaults.double(forKey: "pendingShortcutDuration")
        if shortcutDuration > 0 {
            timerViewModel.selectedDuration = shortcutDuration
            defaults.removeObject(forKey: "pendingShortcutDuration")
        } else {
            let duration = defaults.double(forKey: PreferenceKey.defaultDuration)
            timerViewModel.selectedDuration = duration > 0 ? duration : 120
        }

        let ambientSoundEnabled = defaults.bool(forKey: PreferenceKey.ambientSoundEnabled)
        let selectedSound = defaults.string(forKey: PreferenceKey.selectedAmbientSound) ?? "ocean"

        timerViewModel.beginSession(
            modelContext: modelContext,
            hapticsEnabled: defaults.bool(forKey: PreferenceKey.hapticsEnabled),
            soundEnabled: defaults.bool(forKey: PreferenceKey.soundEnabled),
            notificationService: notificationService,
            breathingEnabled: defaults.bool(forKey: PreferenceKey.breathingEnabled),
            healthKitService: defaults.bool(forKey: PreferenceKey.healthKitEnabled) ? healthKitService : nil,
            ambientSoundService: ambientSoundEnabled ? ambientSoundService : nil,
            ambientSound: ambientSoundEnabled ? AmbientSound(rawValue: selectedSound) : nil,
            phoneConnectivityService: phoneConnectivityService
        )
    }

    private func checkForOrphanedSessions() {
        let cutoff = Date(timeIntervalSinceNow: -3600)
        let descriptor = FetchDescriptor<PlungeSession>(
            predicate: #Predicate { !$0.isCompleted && $0.startTime < cutoff }
        )
        if let orphans = try? modelContext.fetch(descriptor), !orphans.isEmpty {
            orphanedSessions = orphans
            showOrphanAlert = true
        }
    }

    private func saveOrphanedSessions() {
        for session in orphanedSessions {
            session.endTime = session.startTime.addingTimeInterval(session.targetDuration)
            session.benefitZoneReached = BenefitZone.zone(for: session.targetDuration).rawValue
            session.isCompleted = true
        }
        orphanedSessions = []
    }

    private func discardOrphanedSessions() {
        for session in orphanedSessions {
            modelContext.delete(session)
        }
        orphanedSessions = []
    }
}
