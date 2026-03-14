import SwiftUI
import SwiftData

@main
struct IceDipApp: App {
    @State private var notificationService = NotificationService()
    @State private var healthKitService = HealthKitService()
    @State private var ambientSoundService = AmbientSoundService()
    @State private var phoneConnectivityService = PhoneConnectivityService()

    private let container = SharedModelContainer.container

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environment(notificationService)
                .environment(healthKitService)
                .environment(ambientSoundService)
                .environment(phoneConnectivityService)
                .onAppear {
                    phoneConnectivityService.modelContainer = container
                    phoneConnectivityService.activate()
                }
        }
        .modelContainer(container)
    }
}
