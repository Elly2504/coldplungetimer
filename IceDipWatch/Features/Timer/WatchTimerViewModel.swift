import Foundation
import WatchKit
import WidgetKit

@MainActor
@Observable
final class WatchTimerViewModel {
    var selectedDuration: TimeInterval = 120
    var isRunning = false
    var isPaused = false
    var elapsedSeconds: TimeInterval = 0
    var currentZone: BenefitZone = .coldShock
    var isComplete = false
    var connectivityService: WatchConnectivityService?

    private var timer: Timer?
    private var backgroundDate: Date?
    private var startTime: Date?
    private var extendedSession: WKExtendedRuntimeSession?

    var remainingSeconds: TimeInterval {
        max(selectedDuration - elapsedSeconds, 0)
    }

    var progress: Double {
        guard selectedDuration > 0 else { return 0 }
        return min(elapsedSeconds / selectedDuration, 1.0)
    }

    var timeFormatted: String {
        if elapsedSeconds > selectedDuration {
            return "+\(elapsedSeconds.formattedTimer)"
        }
        return remainingSeconds.formattedTimer
    }

    // MARK: - Actions

    func start() {
        isRunning = true
        isPaused = false
        elapsedSeconds = 0
        currentZone = .coldShock
        isComplete = false
        startTime = Date()

        startExtendedSession()
        startTimer()

        WKInterfaceDevice.current().play(.start)
    }

    func pause() {
        isPaused = true
        timer?.invalidate()
        timer = nil
    }

    func resume() {
        isPaused = false
        startTimer()
    }

    func stop() -> WatchSessionData? {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        stopExtendedSession()

        WKInterfaceDevice.current().play(.stop)

        guard let startTime, elapsedSeconds >= 5 else {
            reset()
            return nil
        }

        let endTime = Date()
        let zone = BenefitZone.zone(for: elapsedSeconds)

        let sessionData = WatchSessionData(
            id: UUID(),
            startTime: startTime,
            endTime: endTime,
            targetDuration: selectedDuration,
            benefitZoneReached: zone.rawValue,
            waterTemp: nil
        )
        connectivityService?.sendSession(sessionData)
        isComplete = true

        let defaults = UserDefaults.standard
        let calendar = Calendar.current
        let currentWeek = calendar.component(.weekOfYear, from: .now)
        let currentYear = calendar.component(.yearForWeekOfYear, from: .now)
        let storedWeek = defaults.integer(forKey: "complication_weekOfYear")
        let storedYear = defaults.integer(forKey: "complication_yearForWeek")

        var currentSessions = defaults.integer(forKey: "complication_sessionsThisWeek")
        if currentWeek != storedWeek || currentYear != storedYear {
            currentSessions = 0
            defaults.set(currentWeek, forKey: "complication_weekOfYear")
            defaults.set(currentYear, forKey: "complication_yearForWeek")
        }
        defaults.set(currentSessions + 1, forKey: "complication_sessionsThisWeek")
        WidgetCenter.shared.reloadAllTimelines()

        return sessionData
    }

    func reset() {
        isComplete = false
        startTime = nil
    }

    func handleBackground() {
        guard isRunning, !isPaused else { return }
        backgroundDate = Date()
        timer?.invalidate()
        timer = nil
    }

    func handleForeground() {
        guard let backgroundDate, isRunning, !isPaused else { return }
        let elapsed = Date().timeIntervalSince(backgroundDate)
        self.backgroundDate = nil

        elapsedSeconds += elapsed
        currentZone = BenefitZone.zone(for: elapsedSeconds)

        if elapsedSeconds >= selectedDuration {
            _ = stop()
        } else {
            startTimer()
        }
    }

    // MARK: - Private

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func tick() {
        elapsedSeconds += 1

        let newZone = BenefitZone.zone(for: elapsedSeconds)
        if newZone != currentZone {
            currentZone = newZone
            WKInterfaceDevice.current().play(.notification)
        }

        if elapsedSeconds >= selectedDuration {
            _ = stop()
            WKInterfaceDevice.current().play(.success)
        }
    }

    private func startExtendedSession() {
        let session = WKExtendedRuntimeSession()
        session.start()
        extendedSession = session
    }

    private func stopExtendedSession() {
        extendedSession?.invalidate()
        extendedSession = nil
    }
}
