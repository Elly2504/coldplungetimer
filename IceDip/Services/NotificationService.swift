import Foundation
@preconcurrency import UserNotifications

@MainActor
@Observable
final class NotificationService {
    var isAuthorized = false

    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            self.isAuthorized = granted
        } catch {
            print("Notification permission error: \(error)")
        }
    }

    func checkPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        self.isAuthorized = settings.authorizationStatus == .authorized
    }

    nonisolated func scheduleTimerComplete(duration: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Plunge Complete!"
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            content.body = "Great job! You stayed in for \(minutes)m \(seconds)s."
        } else {
            content.body = "Great job! You stayed in for \(seconds) seconds."
        }
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: duration,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "timer-complete-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    nonisolated func scheduleDailyReminder(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Time for Your Cold Plunge"
        content.body = "Build your resilience — start today's cold exposure session."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: "daily-reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    nonisolated func cancelPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    nonisolated func cancelTimerNotifications() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let timerIds = requests
                .filter { $0.identifier.hasPrefix("timer-complete-") }
                .map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: timerIds)
        }
    }
}
