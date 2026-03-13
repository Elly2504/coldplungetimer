import SwiftUI
import SwiftData

@main
struct IceDipApp: App {
    @State private var notificationService = NotificationService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environment(notificationService)
        }
        .modelContainer(for: [PlungeSession.self])
    }
}
