import SwiftUI

@main
struct IceDipWatchApp: App {
    @State private var connectivityService = WatchConnectivityService()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environment(connectivityService)
                .onAppear {
                    connectivityService.activate()
                }
        }
    }
}
