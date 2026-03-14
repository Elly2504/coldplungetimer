import Foundation
import WatchConnectivity
import WidgetKit
import os

@MainActor
@Observable
final class WatchConnectivityService: NSObject, WCSessionDelegate {
    private static let logger = Logger(subsystem: "com.icedip.app", category: "Connectivity")
    var streakData = WatchStreakData(currentStreak: 0, bestStreak: 0, sessionsThisWeek: 0, lastSessionDate: nil)

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func sendSession(_ session: WatchSessionData) {
        guard WCSession.default.activationState == .activated else { return }
        do {
            let data = try JSONEncoder().encode(session)
            WCSession.default.transferUserInfo(["sessionData": data])
        } catch {
            Self.logger.error("Failed to encode session: \(error, privacy: .public)")
        }
    }

    // MARK: - WCSessionDelegate

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        let context = session.receivedApplicationContext
        Task { @MainActor in
            decodeStreakData(from: context)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            decodeStreakData(from: applicationContext)
        }
    }

    private func decodeStreakData(from context: [String: Any]) {
        guard let data = context["streakData"] as? Data else { return }
        do {
            streakData = try JSONDecoder().decode(WatchStreakData.self, from: data)
            persistForComplication()
        } catch {
            Self.logger.error("Failed to decode streak data: \(error, privacy: .public)")
        }
    }

    private func persistForComplication() {
        let defaults = UserDefaults.standard
        defaults.set(streakData.currentStreak, forKey: "complication_currentStreak")
        defaults.set(streakData.bestStreak, forKey: "complication_bestStreak")
        defaults.set(streakData.sessionsThisWeek, forKey: "complication_sessionsThisWeek")
        if let lastDate = streakData.lastSessionDate {
            defaults.set(lastDate.timeIntervalSince1970, forKey: "complication_lastSessionDate")
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
