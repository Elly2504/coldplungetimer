import Foundation

struct WatchSessionData: Codable, Sendable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let targetDuration: TimeInterval
    let benefitZoneReached: String
    let waterTemp: Double?
}

struct WatchStreakData: Codable, Sendable {
    let currentStreak: Int
    let bestStreak: Int
    let sessionsThisWeek: Int
    let lastSessionDate: Date?
}
