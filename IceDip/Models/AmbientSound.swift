import Foundation

enum AmbientSound: String, CaseIterable, Identifiable {
    case ocean = "ocean"
    case rain = "rain"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ocean: String(localized: "Ocean Waves")
        case .rain: String(localized: "Rain")
        }
    }

    var fileName: String { rawValue }
}
