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
        return WatchStreakEntry(
            date: .now,
            currentStreak: defaults.integer(forKey: "complication_currentStreak"),
            sessionsThisWeek: defaults.integer(forKey: "complication_sessionsThisWeek")
        )
    }
}
