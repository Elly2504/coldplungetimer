import Foundation
import WatchConnectivity

@MainActor
@Observable
final class WatchConnectivityService: NSObject, WCSessionDelegate {
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
            print("Failed to encode session: \(error)")
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
        } catch {
            print("Failed to decode streak data: \(error)")
        }
    }
}
