import SwiftUI
import Charts

enum ChartPeriod: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case all = "All"
}

struct ChartView: View {
    let sessions: [PlungeSession]
    @State private var period: ChartPeriod = .week

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Picker("Period", selection: $period) {
                ForEach(ChartPeriod.allCases, id: \.self) { p in
                    Text(p.rawValue).tag(p)
                }
            }
            .pickerStyle(.segmented)

            Chart(chartData, id: \.label) { day in
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
                AxisMarks { _ in
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
        .animation(.default, value: period)
    }

    private var chartData: [DayData] {
        switch period {
        case .week: weeklyData
        case .month: monthlyData
        case .all: allTimeData
        }
    }

    private var weeklyData: [DayData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let symbols = Calendar.current.shortWeekdaySymbols
        let weekdays = Array(symbols.dropFirst()) + [symbols[0]]

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

    private var monthlyData: [DayData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        // Show last 4 weeks as W1..W4
        return (0..<4).reversed().map { weeksAgo in
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: today),
                  let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
                return DayData(label: "W\(4 - weeksAgo)", minutes: 0)
            }
            let weekStartDay = calendar.startOfDay(for: weekStart)
            let minutes = sessions
                .filter { $0.isCompleted && $0.startTime >= weekStartDay && $0.startTime < weekEnd }
                .reduce(0.0) { $0 + $1.duration / 60.0 }
            return DayData(label: "W\(4 - weeksAgo)", minutes: minutes)
        }
    }

    private var allTimeData: [DayData] {
        let calendar = Calendar.current
        let completed = sessions.filter(\.isCompleted)
        guard let earliest = completed.map(\.startTime).min() else { return [] }

        let startMonth = calendar.dateComponents([.year, .month], from: earliest)
        let endMonth = calendar.dateComponents([.year, .month], from: .now)
        guard let startDate = calendar.date(from: startMonth),
              let endDate = calendar.date(from: endMonth) else { return [] }

        var result: [DayData] = []
        var current = startDate
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        while current <= endDate {
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: current) else { break }
            let minutes = completed
                .filter { $0.startTime >= current && $0.startTime < nextMonth }
                .reduce(0.0) { $0 + $1.duration / 60.0 }
            result.append(DayData(label: formatter.string(from: current), minutes: minutes))
            current = nextMonth
        }

        // Show at most last 6 months
        if result.count > 6 { result = Array(result.suffix(6)) }
        return result
    }
}

private struct DayData {
    let label: String
    let minutes: Double
}
