import Foundation

struct StreakCalculator {
    let sessions: [PlungeSession]

    var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: .now)

        if !hasSession(on: checkDate) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                return 0
            }
            checkDate = yesterday
        }

        while hasSession(on: checkDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                break
            }
            checkDate = previousDay
        }

        return streak
    }

    var bestStreak: Int {
        let calendar = Calendar.current
        let completedSessions = sessions.filter(\.isCompleted)
        guard !completedSessions.isEmpty else { return 0 }

        let sessionDays = Set(completedSessions.map { calendar.startOfDay(for: $0.startTime) })
        let sortedDays = sessionDays.sorted()

        var best = 1
        var current = 1

        for i in 1..<sortedDays.count {
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: sortedDays[i - 1]),
               calendar.isDate(nextDay, inSameDayAs: sortedDays[i]) {
                current += 1
                best = max(best, current)
            } else {
                current = 1
            }
        }

        return max(best, currentStreak)
    }

    var sessionsThisWeekCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else {
            return 0
        }
        return sessions.filter { $0.isCompleted && $0.startTime >= monday }.count
    }

    var lastCompletedSession: PlungeSession? {
        sessions.first { $0.isCompleted }
    }

    func hasSession(on date: Date) -> Bool {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            return false
        }
        return sessions.contains { $0.isCompleted && $0.startTime >= dayStart && $0.startTime < dayEnd }
    }
}
