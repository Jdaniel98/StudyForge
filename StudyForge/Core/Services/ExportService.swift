import Foundation
import CoreData
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Exports study session data to CSV format.
final class ExportService {
    private let persistenceController: PersistenceController

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    /// Generate a CSV string of all study sessions.
    func generateCSV() throws -> String {
        let request = NSFetchRequest<StudySession>(entityName: "StudySession")
        request.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]

        let sessions = try persistenceController.viewContext.fetch(request)

        var csv = "Date,Start Time,End Time,Subject,Category,Duration (min),Planned Duration (min),Completed,Pomodoros,Notes\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"

        for session in sessions {
            let date = dateFormatter.string(from: session.wrappedStartedAt)
            let start = timeFormatter.string(from: session.wrappedStartedAt)
            let end = timeFormatter.string(from: session.wrappedEndedAt)
            let subject = escapeCSV(session.subject?.wrappedName ?? "Unknown")
            let category = escapeCSV(session.subject?.wrappedCategory ?? "Custom")
            let duration = session.durationSeconds / 60
            let planned = session.plannedDurationSeconds / 60
            let completed = session.completedFully ? "Yes" : "No"
            let pomodoros = session.pomodoroCount
            let notes = escapeCSV(session.notes ?? "")

            csv += "\(date),\(start),\(end),\(subject),\(category),\(duration),\(planned),\(completed),\(pomodoros),\(notes)\n"
        }

        return csv
    }

    /// Write CSV to a temporary file and return the URL for sharing.
    func exportToFile() throws -> URL {
        let csv = try generateCSV()
        let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
            .replacingOccurrences(of: "/", with: "-")
        let fileName = "StudyForge-Export-\(dateStr).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
