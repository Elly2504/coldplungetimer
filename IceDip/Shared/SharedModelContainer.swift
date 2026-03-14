import SwiftData
import Foundation
import os

enum SharedModelContainer {
    static let appGroupIdentifier = "group.com.icedip.app"

    private static let logger = Logger(subsystem: "com.icedip.app", category: "ModelContainer")

    static let container: ModelContainer = {
        // Determine store URL: prefer App Group, fall back to documents
        let storeURL: URL
        if let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            storeURL = groupURL.appendingPathComponent("IceDip.store")
        } else {
            logger.error("App Group container not found — falling back to documents directory")
            storeURL = URL.documentsDirectory.appendingPathComponent("IceDip.store")
        }

        let isExtension = Bundle.main.bundlePath.hasSuffix(".appex")
        let isProUser = UserDefaults(suiteName: appGroupIdentifier)?
            .bool(forKey: PreferenceKey.isProUser) ?? false
        let cloudKit: ModelConfiguration.CloudKitDatabase = (isExtension || !isProUser) ? .none : .automatic
        let config = ModelConfiguration(url: storeURL, cloudKitDatabase: cloudKit)

        do {
            return try ModelContainer(
                for: PlungeSession.self,
                migrationPlan: PlungeSessionMigrationPlan.self,
                configurations: config
            )
        } catch {
            logger.error("ModelContainer creation failed: \(error.localizedDescription) — retrying without CloudKit")
        }

        // Retry without CloudKit
        let fallbackConfig = ModelConfiguration(url: storeURL, cloudKitDatabase: .none)
        do {
            return try ModelContainer(
                for: PlungeSession.self,
                migrationPlan: PlungeSessionMigrationPlan.self,
                configurations: fallbackConfig
            )
        } catch {
            logger.error("ModelContainer fallback failed: \(error.localizedDescription) — using in-memory store")
        }

        // Last resort: in-memory
        let inMemoryConfig = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: PlungeSession.self, configurations: inMemoryConfig)
        } catch {
            fatalError("Cannot create even an in-memory ModelContainer: \(error)")
        }
    }()
}
