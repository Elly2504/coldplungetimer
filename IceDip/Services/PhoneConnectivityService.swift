import Foundation
import SwiftData
import WatchConnectivity

@MainActor
@Observable
final class PhoneConnectivityService: NSObject, WCSessionDelegate {
    var modelContainer: ModelContainer?

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func sendStreakUpdate(currentStreak: Int, bestStreak: Int, sessionsThisWeek: Int, lastSessionDate: Date?) {
        guard WCSession.default.activationState == .activated else { return }
        let streakData = WatchStreakData(
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            sessionsThisWeek: sessionsThisWeek,
            lastSessionDate: lastSessionDate
        )
        do {
            let data = try JSONEncoder().encode(streakData)
            try WCSession.default.updateApplicationContext(["streakData": data])
        } catch {
            print("Failed to send streak update: \(error)")
        }
    }

    // MARK: - WCSessionDelegate

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {}

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let data = userInfo["sessionData"] as? Data else { return }
        do {
            let sessionData = try JSONDecoder().decode(WatchSessionData.self, from: data)
            Task { @MainActor in
                insertSession(sessionData)
            }
        } catch {
            print("Failed to decode watch session: \(error)")
        }
    }

    private func insertSession(_ data: WatchSessionData) {
        guard let container = modelContainer else { return }
        let context = ModelContext(container)
        let session = PlungeSession(targetDuration: data.targetDuration)
        session.endTime = data.endTime
        session.isCompleted = true
        session.benefitZoneReached = data.benefitZoneReached
        session.waterTemp = data.waterTemp
        context.insert(session)
        do {
            try context.save()
            let descriptor = FetchDescriptor<PlungeSession>(sortBy: [SortDescriptor(\.startTime, order: .reverse)])
            let allSessions = try context.fetch(descriptor)
            let calculator = StreakCalculator(sessions: allSessions)
            sendStreakUpdate(
                currentStreak: calculator.currentStreak,
                bestStreak: calculator.bestStreak,
                sessionsThisWeek: calculator.sessionsThisWeekCount,
                lastSessionDate: calculator.lastCompletedSession?.startTime
            )
        } catch {
            print("Failed to save watch session: \(error)")
        }
    }
}
