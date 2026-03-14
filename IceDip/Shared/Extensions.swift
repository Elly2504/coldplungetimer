import SwiftUI

// MARK: - Color Hex Initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - TimeInterval Formatting

extension TimeInterval {
    var formattedTimer: String {
        let totalSeconds = Int(self)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedMinutes: String {
        let minutes = Int(self) / 60
        return "\(minutes) min"
    }
}

// MARK: - Date Helpers

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: self) ?? self
    }

    private enum Formatters {
        static let short: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "MMM d"
            return f
        }()

        static let time: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "h:mm a"
            return f
        }()

        static let medium: DateFormatter = {
            let f = DateFormatter()
            f.dateStyle = .medium
            f.timeStyle = .short
            return f
        }()
    }

    var formattedShort: String {
        if isToday { return "Today" }
        if isYesterday { return "Yesterday" }
        return Formatters.short.string(from: self)
    }

    var formattedTime: String {
        Formatters.time.string(from: self)
    }

    var formattedMedium: String {
        Formatters.medium.string(from: self)
    }
}

// MARK: - Mood Emoji

func moodEmoji(_ rating: Int) -> String {
    switch rating {
    case 1: "😰"
    case 2: "😕"
    case 3: "😐"
    case 4: "😊"
    case 5: "🤩"
    default: "😐"
    }
}

// MARK: - Temperature Conversion

extension Double {
    var celsiusToFahrenheit: Double {
        self * 9.0 / 5.0 + 32.0
    }

    var fahrenheitToCelsius: Double {
        (self - 32.0) * 5.0 / 9.0
    }

    func formattedTemperature(unit: String) -> String {
        let value = unit == "fahrenheit" ? self.celsiusToFahrenheit : self
        let symbol = unit == "fahrenheit" ? "°F" : "°C"
        return String(format: "%.0f%@", value, symbol)
    }
}
