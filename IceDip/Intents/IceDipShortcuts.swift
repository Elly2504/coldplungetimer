import AppIntents

struct IceDipShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartPlungeIntent(),
            phrases: [
                "Start my cold plunge in \(.applicationName)",
                "Start \(.applicationName)",
                "Begin cold plunge with \(.applicationName)",
                "Start ice bath in \(.applicationName)"
            ],
            shortTitle: "Start Cold Plunge",
            systemImageName: "snowflake"
        )
    }
}
