import WidgetKit
import SwiftUI

struct WatchStreakEntry: TimelineEntry {
    let date: Date
    let currentStreak: Int
    let sessionsThisWeek: Int

    static let placeholder = WatchStreakEntry(date: .now, currentStreak: 3, sessionsThisWeek: 2)
}

struct WatchComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchStreakEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchStreakEntry) -> Void) {
        completion(context.isPreview ? .placeholder : fetchEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchStreakEntry>) -> Void) {
        let entry = fetchEntry()
        let midnight = Calendar.current.startOfDay(for: .now).addingTimeInterval(86400)
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }

    private func fetchEntry() -> WatchStreakEntry {
        let defaults = UserDefaults.standard
        let calendar = Calendar.current
        let currentWeek = calendar.component(.weekOfYear, from: .now)
        let currentYear = calendar.component(.yearForWeekOfYear, from: .now)
        let storedWeek = defaults.integer(forKey: "complication_weekOfYear")
        let storedYear = defaults.integer(forKey: "complication_yearForWeek")

        var sessionsThisWeek = defaults.integer(forKey: "complication_sessionsThisWeek")
        if currentWeek != storedWeek || currentYear != storedYear {
            sessionsThisWeek = 0
            defaults.set(0, forKey: "complication_sessionsThisWeek")
            defaults.set(currentWeek, forKey: "complication_weekOfYear")
            defaults.set(currentYear, forKey: "complication_yearForWeek")
        }

        return WatchStreakEntry(
            date: .now,
            currentStreak: defaults.integer(forKey: "complication_currentStreak"),
            sessionsThisWeek: sessionsThisWeek
        )
    }
}
