import AppIntents

struct StartPlungeIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Cold Plunge"
    static let description = IntentDescription("Start a cold plunge timer session.")
    static let openAppWhenRun = true

    @Parameter(title: "Duration")
    var duration: Measurement<UnitDuration>?

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: "pendingShortcutStart")
        if let duration {
            let seconds = duration.converted(to: .seconds).value
            defaults.set(seconds, forKey: "pendingShortcutDuration")
        } else {
            defaults.removeObject(forKey: "pendingShortcutDuration")
        }
        return .result()
    }
}
