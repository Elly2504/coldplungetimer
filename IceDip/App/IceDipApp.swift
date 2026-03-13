import SwiftUI
import SwiftData

@main
struct IceDipApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [PlungeSession.self])
    }
}
