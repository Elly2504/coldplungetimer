import AppIntents

struct StartPlungeIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Cold Plunge"
    static let description = IntentDescription("Start a cold plunge timer session.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(true, forKey: "pendingShortcutStart")
        return .result()
    }
}
