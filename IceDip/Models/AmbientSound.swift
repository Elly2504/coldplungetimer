import Foundation

enum AmbientSound: String, CaseIterable, Identifiable {
    case ocean = "ocean"
    case rain = "rain"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ocean: "Ocean Waves"
        case .rain: "Rain"
        }
    }

    var fileName: String { rawValue }
}
