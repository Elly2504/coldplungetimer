import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class TimerViewModel {
    // MARK: - State

    var selectedDuration: TimeInterval = 120
    var isRunning = false
    var isPaused = false
    var elapsedSeconds: TimeInterval = 0
    var currentSession: PlungeSession?
    var currentZone: BenefitZone = .coldShock
    var showCompletion = false

    // Pre/post plunge inputs
    var waterTemp: Double = 5.0
    var hasWaterTemp = false
    var moodBefore: Int? = nil
    var moodAfter: Int? = nil
    var notes: String = ""

    // MARK: - Private

    private var timer: Timer?
    private var backgroundDate: Date?
    private var storedModelContext: ModelContext?
    private var storedNotificationService: NotificationService?
    private var storedHapticsEnabled: Bool = true

    // MARK: - Computed

    var remainingSeconds: TimeInterval {
        max(selectedDuration - elapsedSeconds, 0)
    }

    var progress: Double {
        guard selectedDuration > 0 else { return 0 }
        return min(elapsedSeconds / selectedDuration, 1.0)
    }

    var timeFormatted: String {
        if showCompletion {
            return "0:00"
        }
        if elapsedSeconds > selectedDuration {
            return "+\(elapsedSeconds.formattedTimer)"
        }
        return remainingSeconds.formattedTimer
    }

    var isComplete: Bool {
        elapsedSeconds >= selectedDuration
    }

    // MARK: - Actions

    func start(modelContext: ModelContext, hapticsEnabled: Bool, soundEnabled: Bool, notificationService: NotificationService) {
        let session = PlungeSession(targetDuration: selectedDuration)
        modelContext.insert(session)
        currentSession = session

        storedModelContext = modelContext
        storedNotificationService = notificationService
        storedHapticsEnabled = hapticsEnabled

        isRunning = true
        isPaused = false
        elapsedSeconds = 0
        currentZone = .coldShock
        showCompletion = false
        moodAfter = nil
        notes = ""

        notificationService.scheduleTimerComplete(duration: selectedDuration, soundEnabled: soundEnabled)

        if hapticsEnabled {
            HapticService.start()
        }

        startTimer(hapticsEnabled: hapticsEnabled)
    }

    func pause() {
        isPaused = true
        timer?.invalidate()
        timer = nil
    }

    func resume(hapticsEnabled: Bool) {
        isPaused = false
        startTimer(hapticsEnabled: hapticsEnabled)
    }

    func stop(modelContext: ModelContext, hapticsEnabled: Bool, notificationService: NotificationService) {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false

        notificationService.cancelTimerNotifications()

        if let session = currentSession {
            if elapsedSeconds < 5 {
                modelContext.delete(session)
                currentSession = nil
                return
            }

            session.complete(
                waterTemp: hasWaterTemp ? waterTemp : nil,
                moodBefore: moodBefore,
                moodAfter: moodAfter
            )

            if hapticsEnabled {
                HapticService.complete()
            }

            showCompletion = true
        }
    }

    func reset() {
        currentSession = nil
        showCompletion = false
        moodBefore = nil
        moodAfter = nil
        notes = ""
        storedModelContext = nil
        storedNotificationService = nil
    }

    func handleBackground() {
        guard isRunning, !isPaused else { return }
        backgroundDate = Date()
        timer?.invalidate()
        timer = nil
    }

    func handleForeground(hapticsEnabled: Bool) {
        guard let backgroundDate, isRunning, !isPaused else { return }
        let elapsed = Date().timeIntervalSince(backgroundDate)
        self.backgroundDate = nil

        // Check for zone transitions that happened while backgrounded
        let previousZone = currentZone
        elapsedSeconds += elapsed
        currentZone = BenefitZone.zone(for: elapsedSeconds)

        if currentZone != previousZone && hapticsEnabled {
            HapticService.zoneTransition()
        }

        if isComplete, let ctx = storedModelContext, let ns = storedNotificationService {
            stop(modelContext: ctx, hapticsEnabled: storedHapticsEnabled, notificationService: ns)
        } else if !isComplete {
            startTimer(hapticsEnabled: hapticsEnabled)
        }
    }

    // MARK: - Private

    private func startTimer(hapticsEnabled: Bool) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.tick(hapticsEnabled: hapticsEnabled)
            }
        }
    }

    private func tick(hapticsEnabled: Bool) {
        elapsedSeconds += 1

        let newZone = BenefitZone.zone(for: elapsedSeconds)
        if newZone != currentZone {
            currentZone = newZone
            if hapticsEnabled {
                HapticService.zoneTransition()
            }
        }

        // Countdown haptics at 3, 2, 1
        if hapticsEnabled {
            let remaining = Int(remainingSeconds)
            HapticService.countdown(secondsRemaining: remaining)
        }

        // Auto-complete when target duration reached
        if isComplete, let ctx = storedModelContext, let ns = storedNotificationService {
            stop(modelContext: ctx, hapticsEnabled: hapticsEnabled, notificationService: ns)
        }
    }
}
