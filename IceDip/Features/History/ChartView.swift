import SwiftUI
import Charts

struct ChartView: View {
    let sessions: [PlungeSession]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("This Week")
                .font(Theme.Fonts.headingSmall)
                .foregroundStyle(Theme.Colors.textPrimary)

            Chart(weeklyData, id: \.label) { day in
                BarMark(
                    x: .value("Day", day.label),
                    y: .value("Minutes", day.minutes)
                )
                .foregroundStyle(Theme.Colors.iceBlue.gradient)
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let minutes = value.as(Double.self) {
                            Text("\(Int(minutes))m")
                                .font(Theme.Fonts.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Theme.Colors.surface)
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .frame(height: 160)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var weeklyData: [DayData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

        // .weekday returns 1=Sunday in Gregorian calendar regardless of locale
        // Formula maps to 0=Monday, 1=Tuesday, ..., 6=Sunday
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else {
            return []
        }

        return (0..<7).map { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: monday) else {
                return DayData(label: weekdays[offset], minutes: 0)
            }
            let nextDate = calendar.date(byAdding: .day, value: 1, to: date) ?? date
            let dayMinutes = sessions
                .filter { $0.isCompleted && $0.startTime >= date && $0.startTime < nextDate }
                .reduce(0.0) { $0 + $1.duration / 60.0 }
            return DayData(label: weekdays[offset], minutes: dayMinutes)
        }
    }
}

private struct DayData {
    let label: String
    let minutes: Double
}
