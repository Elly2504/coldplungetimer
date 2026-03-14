import Foundation

struct ZoneThresholds: Codable, Equatable, Sendable {
    var adaptation: TimeInterval = 30
    var dopamineZone: TimeInterval = 60
    var metabolicBoost: TimeInterval = 120
    var deepResilience: TimeInterval = 180

    static let `default` = ZoneThresholds()

    func startSeconds(for zone: BenefitZone) -> TimeInterval {
        switch zone {
        case .coldShock: 0
        case .adaptation: adaptation
        case .dopamineZone: dopamineZone
        case .metabolicBoost: metabolicBoost
        case .deepResilience: deepResilience
        }
    }
}

extension ZoneThresholds: RawRepresentable {
    init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(ZoneThresholds.self, from: data) else {
            return nil
        }
        self = decoded
    }

    var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return string
    }
}
