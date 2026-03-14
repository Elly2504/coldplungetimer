import Foundation
import SwiftData

enum CSVExportService {
    static func generateCSV(sessions: [PlungeSession]) -> String {
        var csv = "date,duration_seconds,water_temp_celsius,mood_before,mood_after,zone,notes\n"
        let dateFormatter = ISO8601DateFormatter()

        for session in sessions where session.isCompleted {
            let date = dateFormatter.string(from: session.startTime)
            let duration = String(format: "%.0f", session.duration)
            let temp = session.waterTemp.map { String(format: "%.1f", $0) } ?? ""
            let moodBefore = session.moodBefore.map(String.init) ?? ""
            let moodAfter = session.moodAfter.map(String.init) ?? ""
            let zone = session.benefitZoneReached ?? ""
            let notes = escapeCSV(session.notes ?? "")
            csv += "\(date),\(duration),\(temp),\(moodBefore),\(moodAfter),\(zone),\(notes)\n"
        }
        return csv
    }

    static func writeToTemporaryFile(csv: String) -> URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let fileName = "IceDip_Sessions_\(formatter.string(from: .now)).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            return nil
        }
    }

    private static func escapeCSV(_ value: String) -> String {
        guard !value.isEmpty else { return "" }
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
