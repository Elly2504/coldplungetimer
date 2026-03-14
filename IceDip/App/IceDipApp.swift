import SwiftUI
import SwiftData

@main
struct IceDipApp: App {
    @State private var notificationService = NotificationService()
    @State private var healthKitService = HealthKitService()
    @State private var ambientSoundService = AmbientSoundService()
    @State private var phoneConnectivityService = PhoneConnectivityService()
    @State private var purchaseManager = PurchaseManager()
    @AppStorage(PreferenceKey.colorSchemePreference) private var colorSchemePreference = "dark"
    @Environment(\.scenePhase) private var scenePhase

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
                .environment(purchaseManager)
                .onAppear {
                    phoneConnectivityService.modelContainer = container
                    phoneConnectivityService.activate()
                }
                .task {
                    await purchaseManager.loadProducts()
                    await purchaseManager.checkEntitlements()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        Task { await purchaseManager.checkEntitlements() }
                    }
                }
        }
        .modelContainer(container)
    }
}
