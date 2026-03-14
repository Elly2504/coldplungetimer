import WidgetKit
import SwiftUI
import SwiftData

struct PlungeEntry: TimelineEntry {
    let date: Date
    let currentStreak: Int
    let sessionsThisWeek: Int
    let weeklyGoal: Int
    let lastZone: BenefitZone?
    let lastPlungeDate: Date?
    let isProUser: Bool

    static var placeholder: PlungeEntry {
        PlungeEntry(
            date: .now,
            currentStreak: 3,
            sessionsThisWeek: 2,
            weeklyGoal: 3,
            lastZone: .dopamineZone,
            lastPlungeDate: .now,
            isProUser: true
        )
    }

    static var empty: PlungeEntry {
        PlungeEntry(
            date: .now,
            currentStreak: 0,
            sessionsThisWeek: 0,
            weeklyGoal: 3,
            lastZone: nil,
            lastPlungeDate: nil,
            isProUser: false
        )
    }
}

struct PlungeTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> PlungeEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (PlungeEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
        } else {
            completion(fetchEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PlungeEntry>) -> Void) {
        let entry = fetchEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 2, to: .now) ?? .now.addingTimeInterval(7200)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func fetchEntry() -> PlungeEntry {
        let container = SharedModelContainer.container
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<PlungeSession>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        let sessions = (try? context.fetch(descriptor)) ?? []
        let calc = StreakCalculator(sessions: sessions)

        let storedGoal = UserDefaults(suiteName: SharedModelContainer.appGroupIdentifier)?
            .integer(forKey: PreferenceKey.weeklyGoalSessions) ?? 0
        let goal = storedGoal > 0 ? storedGoal : 3

        let isProUser = UserDefaults(suiteName: SharedModelContainer.appGroupIdentifier)?
            .bool(forKey: PreferenceKey.isProUser) ?? false

        return PlungeEntry(
            date: .now,
            currentStreak: calc.currentStreak,
            sessionsThisWeek: calc.sessionsThisWeekCount,
            weeklyGoal: goal,
            lastZone: calc.lastCompletedSession?.zone,
            lastPlungeDate: calc.lastCompletedSession?.startTime,
            isProUser: isProUser
        )
    }
}

struct IceDipWidget: Widget {
    let kind = "IceDipWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PlungeTimelineProvider()) { entry in
            IceDipWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("IceDip")
        .description("Track your cold plunge streak and progress.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
