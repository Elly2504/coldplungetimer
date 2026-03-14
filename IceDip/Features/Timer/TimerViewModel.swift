import Foundation
import SwiftData
import SwiftUI
import WidgetKit

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
    var showBreathing = false

    // Pre/post plunge inputs
    var waterTemp: Double = 5.0
    var hasWaterTemp = false
    var moodBefore: Int? = nil
    var moodAfter: Int? = nil
    var notes: String = ""

    // MARK: - Zone Thresholds

    private var zoneThresholds: ZoneThresholds {
        guard let raw = UserDefaults.standard.string(forKey: PreferenceKey.zoneThresholds),
              let thresholds = ZoneThresholds(rawValue: raw) else {
            return .default
        }
        return thresholds
    }

    // MARK: - Private

    private var timer: Timer?
    private var backgroundDate: Date?
    private var storedModelContext: ModelContext?
    private var storedNotificationService: NotificationService?
    private var storedHealthKitService: HealthKitService?
    private var storedAmbientSoundService: AmbientSoundService?
    private var storedPhoneConnectivityService: PhoneConnectivityService?
    private var storedHapticsEnabled: Bool = true
    private var pendingModelContext: ModelContext?
    private var pendingSoundEnabled: Bool = true
    private var pendingAmbientSound: AmbientSound?

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

    func beginSession(modelContext: ModelContext, hapticsEnabled: Bool, soundEnabled: Bool, notificationService: NotificationService, breathingEnabled: Bool, healthKitService: HealthKitService? = nil, ambientSoundService: AmbientSoundService? = nil, ambientSound: AmbientSound? = nil, phoneConnectivityService: PhoneConnectivityService? = nil) {
        if breathingEnabled {
            pendingModelContext = modelContext
            storedNotificationService = notificationService
            storedHealthKitService = healthKitService
            storedAmbientSoundService = ambientSoundService
            storedPhoneConnectivityService = phoneConnectivityService
            storedHapticsEnabled = hapticsEnabled
            pendingSoundEnabled = soundEnabled
            pendingAmbientSound = ambientSound
            showBreathing = true
        } else {
            start(modelContext: modelContext, hapticsEnabled: hapticsEnabled, soundEnabled: soundEnabled, notificationService: notificationService, healthKitService: healthKitService, ambientSoundService: ambientSoundService, ambientSound: ambientSound, phoneConnectivityService: phoneConnectivityService)
        }
    }

    func breathingComplete() {
        showBreathing = false
        guard let ctx = pendingModelContext, let ns = storedNotificationService else { return }
        start(modelContext: ctx, hapticsEnabled: storedHapticsEnabled, soundEnabled: pendingSoundEnabled, notificationService: ns, healthKitService: storedHealthKitService, ambientSoundService: storedAmbientSoundService, ambientSound: pendingAmbientSound, phoneConnectivityService: storedPhoneConnectivityService)
        pendingModelContext = nil
    }

    func skipBreathing() {
        breathingComplete()
    }

    func start(modelContext: ModelContext, hapticsEnabled: Bool, soundEnabled: Bool, notificationService: NotificationService, healthKitService: HealthKitService? = nil, ambientSoundService: AmbientSoundService? = nil, ambientSound: AmbientSound? = nil, phoneConnectivityService: PhoneConnectivityService? = nil) {
        let session = PlungeSession(targetDuration: selectedDuration)
        modelContext.insert(session)
        currentSession = session

        storedModelContext = modelContext
        storedNotificationService = notificationService
        storedHealthKitService = healthKitService
        storedAmbientSoundService = ambientSoundService
        storedPhoneConnectivityService = phoneConnectivityService
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

        if let ambientSound, let service = storedAmbientSoundService {
            service.play(sound: ambientSound)
        }
    }

    func pause() {
        isPaused = true
        timer?.invalidate()
        timer = nil
        storedAmbientSoundService?.pause()
    }

    func resume(hapticsEnabled: Bool) {
        isPaused = false
        startTimer(hapticsEnabled: hapticsEnabled)
        storedAmbientSoundService?.resume()
    }

    func stop(modelContext: ModelContext, hapticsEnabled: Bool, notificationService: NotificationService) async {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        storedAmbientSoundService?.stop()

        await notificationService.cancelTimerNotifications()

        if let session = currentSession {
            if elapsedSeconds < 5 {
                modelContext.delete(session)
                currentSession = nil
                return
            }

            session.complete(
                waterTemp: hasWaterTemp ? waterTemp : nil,
                moodBefore: moodBefore,
                moodAfter: moodAfter,
                thresholds: zoneThresholds
            )

            if hapticsEnabled {
                HapticService.complete()
            }

            if let hks = storedHealthKitService, let endTime = session.endTime {
                let startDate = session.startTime
                let waterTemp = session.waterTemp
                Task {
                    await hks.saveWorkout(startDate: startDate, endDate: endTime, waterTempCelsius: waterTemp)
                }
            }

            WidgetCenter.shared.reloadAllTimelines()

            if let connectivityService = storedPhoneConnectivityService, let ctx = storedModelContext {
                do {
                    let descriptor = FetchDescriptor<PlungeSession>(sortBy: [SortDescriptor(\.startTime, order: .reverse)])
                    let allSessions = try ctx.fetch(descriptor)
                    let calculator = StreakCalculator(sessions: allSessions)
                    connectivityService.sendStreakUpdate(
                        currentStreak: calculator.currentStreak,
                        bestStreak: calculator.bestStreak,
                        sessionsThisWeek: calculator.sessionsThisWeekCount,
                        lastSessionDate: calculator.lastCompletedSession?.startTime
                    )
                } catch {
                    print("Failed to fetch sessions for streak update: \(error)")
                }
            }

            showCompletion = true
        }
    }

    func reset() {
        currentSession = nil
        showCompletion = false
        showBreathing = false
        moodBefore = nil
        moodAfter = nil
        notes = ""
        storedModelContext = nil
        storedNotificationService = nil
        storedHealthKitService = nil
        storedPhoneConnectivityService = nil
        storedAmbientSoundService?.stop()
        storedAmbientSoundService = nil
        pendingModelContext = nil
        pendingAmbientSound = nil
    }

    func handleBackground() {
        guard isRunning, !isPaused else { return }
        backgroundDate = Date()
        timer?.invalidate()
        timer = nil
    }

    func handleForeground(hapticsEnabled: Bool) async {
        guard let backgroundDate, isRunning, !isPaused else { return }
        let elapsed = Date().timeIntervalSince(backgroundDate)
        self.backgroundDate = nil

        // Check for zone transitions that happened while backgrounded
        let previousZone = currentZone
        elapsedSeconds += elapsed
        currentZone = BenefitZone.zone(for: elapsedSeconds, thresholds: zoneThresholds)

        if currentZone != previousZone && hapticsEnabled {
            HapticService.zoneTransition()
        }

        if isComplete, let ctx = storedModelContext, let ns = storedNotificationService {
            await stop(modelContext: ctx, hapticsEnabled: storedHapticsEnabled, notificationService: ns)
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
                await self.tick(hapticsEnabled: hapticsEnabled)
            }
        }
    }

    private func tick(hapticsEnabled: Bool) async {
        elapsedSeconds += 1

        let newZone = BenefitZone.zone(for: elapsedSeconds, thresholds: zoneThresholds)
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
            await stop(modelContext: ctx, hapticsEnabled: hapticsEnabled, notificationService: ns)
        }
    }
}
