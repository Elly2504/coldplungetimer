import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationService.self) private var notificationService
    @Environment(HealthKitService.self) private var healthKitService
    @State private var timerViewModel = TimerViewModel()
    @AppStorage(PreferenceKey.hasOnboarded) private var hasOnboarded = false
    @State private var orphanedSessions: [PlungeSession] = []
    @State private var showOrphanAlert = false

    var body: some View {
        if hasOnboarded {
            TabView {
                TimerView(viewModel: timerViewModel)
                    .tabItem { Label("Timer", systemImage: "timer") }
                    .badge(timerViewModel.isRunning ? 1 : 0)
                HistoryView()
                    .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                StreakView()
                    .tabItem { Label("Streak", systemImage: "flame.fill") }
                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            }
            .tint(Theme.Colors.iceBlue)
            .task {
                await notificationService.requestPermission()
                healthKitService.checkAuthorizationStatus()
                checkForOrphanedSessions()
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
