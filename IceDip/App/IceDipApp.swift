import SwiftUI
import SwiftData

@main
struct IceDipApp: App {
    @State private var notificationService = NotificationService()
    @State private var healthKitService = HealthKitService()
    @State private var ambientSoundService = AmbientSoundService()
    @State private var phoneConnectivityService = PhoneConnectivityService()
    @AppStorage(PreferenceKey.colorSchemePreference) private var colorSchemePreference = "dark"

    private let container = SharedModelContainer.container

    private var resolvedColorScheme: ColorScheme? {
        switch colorSchemePreference {
        case "dark": .dark
        case "light": .light
        default: nil
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(resolvedColorScheme)
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
