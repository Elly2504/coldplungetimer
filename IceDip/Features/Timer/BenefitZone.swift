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
        case .coldShock: String(localized: "Cold Shock")
        case .adaptation: String(localized: "Adaptation")
        case .dopamineZone: String(localized: "Dopamine Zone")
        case .metabolicBoost: String(localized: "Metabolic Boost")
        case .deepResilience: String(localized: "Deep Resilience")
        }
    }

    var description: String {
        switch self {
        case .coldShock: String(localized: "Adrenaline spike, fight-or-flight response activating")
        case .adaptation: String(localized: "Body adjusting, norepinephrine rising")
        case .dopamineZone: String(localized: "Dopamine +250%, norepinephrine +530%")
        case .metabolicBoost: String(localized: "Brown fat activation, doubled metabolic rate")
        case .deepResilience: String(localized: "Cellular cleanup, autophagy activation")
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

    static func zone(for elapsedSeconds: TimeInterval, thresholds: ZoneThresholds = .default) -> BenefitZone {
        for zone in Self.allCases.reversed() {
            if elapsedSeconds >= thresholds.startSeconds(for: zone) {
                return zone
            }
        }
        return .coldShock
    }
}
