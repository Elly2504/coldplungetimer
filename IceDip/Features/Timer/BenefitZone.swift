import SwiftUI

enum BenefitZone: String, CaseIterable, Codable, Identifiable {
    case coldShock
    case adaptation
    case dopamineZone
    case metabolicBoost
    case deepResilience

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .coldShock: "Cold Shock"
        case .adaptation: "Adaptation"
        case .dopamineZone: "Dopamine Zone"
        case .metabolicBoost: "Metabolic Boost"
        case .deepResilience: "Deep Resilience"
        }
    }

    var description: String {
        switch self {
        case .coldShock: "Adrenaline spike, fight-or-flight response activating"
        case .adaptation: "Body adjusting, norepinephrine rising"
        case .dopamineZone: "Dopamine +250%, norepinephrine +530%"
        case .metabolicBoost: "Brown fat activation, doubled metabolic rate"
        case .deepResilience: "Cellular cleanup, autophagy activation"
        }
    }

    var icon: String {
        switch self {
        case .coldShock: "bolt.fill"
        case .adaptation: "arrow.triangle.2.circlepath"
        case .dopamineZone: "brain.head.profile"
        case .metabolicBoost: "flame.fill"
        case .deepResilience: "snowflake"
        }
    }

    var color: Color {
        switch self {
        case .coldShock: Theme.Colors.coldShock
        case .adaptation: Theme.Colors.adaptation
        case .dopamineZone: Theme.Colors.dopamineZone
        case .metabolicBoost: Theme.Colors.metabolicBoost
        case .deepResilience: Theme.Colors.deepResilience
        }
    }

    /// Threshold in seconds where this zone begins
    var startSeconds: TimeInterval {
        switch self {
        case .coldShock: 0
        case .adaptation: 30
        case .dopamineZone: 60
        case .metabolicBoost: 120
        case .deepResilience: 180
        }
    }

    static func zone(for elapsedSeconds: TimeInterval) -> BenefitZone {
        for zone in Self.allCases.reversed() {
            if elapsedSeconds >= zone.startSeconds {
                return zone
            }
        }
        return .coldShock
    }
}
