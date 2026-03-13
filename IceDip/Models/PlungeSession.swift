import Foundation
import SwiftData

@Model
final class PlungeSession {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var targetDuration: TimeInterval
    var waterTemp: Double?
    var benefitZoneReached: String?
    var moodBefore: Int?
    var moodAfter: Int?
    var isCompleted: Bool

    var duration: TimeInterval {
        guard let endTime else { return Date().timeIntervalSince(startTime) }
        return endTime.timeIntervalSince(startTime)
    }

    var durationFormatted: String {
        duration.formattedTimer
    }

    var zone: BenefitZone? {
        guard let benefitZoneReached else { return nil }
        return BenefitZone(rawValue: benefitZoneReached)
    }

    init(targetDuration: TimeInterval) {
        self.id = UUID()
        self.startTime = Date()
        self.endTime = nil
        self.targetDuration = targetDuration
        self.waterTemp = nil
        self.benefitZoneReached = nil
        self.moodBefore = nil
        self.moodAfter = nil
        self.isCompleted = false
    }

    func complete(waterTemp: Double?, moodBefore: Int?, moodAfter: Int?) {
        self.endTime = Date()
        self.waterTemp = waterTemp
        self.moodBefore = moodBefore
        self.moodAfter = moodAfter
        self.benefitZoneReached = BenefitZone.zone(for: duration).rawValue
        self.isCompleted = true
    }
}
