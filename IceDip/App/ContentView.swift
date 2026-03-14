import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationService.self) private var notificationService
    @Environment(HealthKitService.self) private var healthKitService
    @State private var timerViewModel = TimerViewModel()
    @AppStorage(PreferenceKey.hasOnboarded) private var hasOnboarded = false

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
                cleanupOrphanedSessions()
            }
        } else {
            OnboardingView()
        }
    }

    private func cleanupOrphanedSessions() {
        let cutoff = Date(timeIntervalSinceNow: -3600)
        let descriptor = FetchDescriptor<PlungeSession>(
            predicate: #Predicate { !$0.isCompleted && $0.startTime < cutoff }
        )
        if let orphans = try? modelContext.fetch(descriptor) {
            for session in orphans {
                modelContext.delete(session)
            }
        }
    }
}
