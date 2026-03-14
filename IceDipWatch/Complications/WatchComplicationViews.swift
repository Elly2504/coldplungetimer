import SwiftUI
import WidgetKit

struct CircularComplicationView: View {
    let entry: WatchStreakEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Image(systemName: "flame.fill")
                    .font(.caption)
                Text("\(entry.currentStreak)")
                    .font(.system(.title3, design: .rounded, weight: .bold))
            }
            .widgetAccentable()
        }
    }
}

struct RectangularComplicationView: View {
    let entry: WatchStreakEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Label {
                    Text("\(entry.currentStreak) \(String(localized: "day streak"))")
                } icon: {
                    Image(systemName: "flame.fill")
                }
                .font(.system(.headline, design: .rounded))
                .widgetAccentable()

                Text("\(entry.sessionsThisWeek) \(String(localized: "sessions this week"))")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

struct InlineComplicationView: View {
    let entry: WatchStreakEntry

    var body: some View {
        Label {
            Text("\(entry.currentStreak) \(String(localized: "day streak"))")
        } icon: {
            Image(systemName: "flame.fill")
        }
    }
}
