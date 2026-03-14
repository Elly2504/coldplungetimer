import SwiftUI
import WidgetKit

struct IceDipWidgetEntryView: View {
    var entry: PlungeEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: PlungeEntry

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.title)
                .foregroundStyle(entry.currentStreak > 0
                    ? Color(hex: "FF6B35") : Color.white.opacity(0.6))

            Text("\(entry.currentStreak)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(entry.currentStreak == 1 ? "day streak" : "days streak")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            Color(hex: "0A1628")
        }
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: PlungeEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left: Streak
            VStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(entry.currentStreak > 0
                        ? Color(hex: "FF6B35") : Color.white.opacity(0.6))

                Text("\(entry.currentStreak)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("streak")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(.white.opacity(0.15))
                .frame(width: 1)
                .padding(.vertical, 8)

            // Right: Stats
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "target")
                        .font(.caption)
                        .foregroundStyle(Color(hex: "64D2FF"))
                    Text("\(entry.sessionsThisWeek)/\(entry.weeklyGoal) this week")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.white)
                }

                if let zone = entry.lastZone {
                    HStack(spacing: 6) {
                        Image(systemName: zone.icon)
                            .font(.caption)
                            .foregroundStyle(zone.color)
                        Text(zone.displayName)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }

                if let lastDate = entry.lastPlungeDate {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        Text(lastDate, style: .relative)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            Color(hex: "0A1628")
        }
    }
}
