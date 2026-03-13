import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationService.self) private var notificationService

    var body: some View {
        TabView {
            TimerView()
                .tabItem { Label("Timer", systemImage: "timer") }
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
            cleanupOrphanedSessions()
        }
    }

    private func cleanupOrphanedSessions() {
        let descriptor = FetchDescriptor<PlungeSession>(
            predicate: #Predicate { !$0.isCompleted }
        )
        if let orphans = try? modelContext.fetch(descriptor) {
            for session in orphans {
                modelContext.delete(session)
            }
        }
    }
}
