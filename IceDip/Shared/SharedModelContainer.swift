import SwiftData
import Foundation

enum SharedModelContainer {
    static let appGroupIdentifier = "group.com.icedip.app"

    static let container: ModelContainer = {
        guard let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            fatalError("App Group container '\(appGroupIdentifier)' not found. Check entitlements.")
        }
        let url = groupURL.appendingPathComponent("IceDip.store")
        let config = ModelConfiguration(url: url)
        do {
            return try ModelContainer(
                for: PlungeSession.self,
                migrationPlan: PlungeSessionMigrationPlan.self,
                configurations: config
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
}
