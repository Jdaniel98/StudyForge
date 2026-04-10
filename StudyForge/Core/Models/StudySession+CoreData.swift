import CoreData

@objc(StudySession)
public class StudySession: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var startedAt: Date?
    @NSManaged public var endedAt: Date?
    @NSManaged public var durationSeconds: Int32
    @NSManaged public var plannedDurationSeconds: Int32
    @NSManaged public var completedFully: Bool
    @NSManaged public var notes: String?
    @NSManaged public var pomodoroCount: Int16
    @NSManaged public var syncedToRemote: Bool
    @NSManaged public var remoteId: String?
    @NSManaged public var subject: Subject?
}

// MARK: - Convenience

extension StudySession {
    var wrappedStartedAt: Date { startedAt ?? Date() }
    var wrappedEndedAt: Date { endedAt ?? Date() }

    /// Human-readable duration string (e.g., "25m", "1h 30m")
    var formattedDuration: String {
        DurationFormatter.humanReadable(from: durationSeconds)
    }

    /// What percentage of the planned duration was completed
    var completionPercentage: Double {
        guard plannedDurationSeconds > 0 else { return 0 }
        return min(Double(durationSeconds) / Double(plannedDurationSeconds), 1.0)
    }

    /// Whether this session exceeds the anti-gaming threshold (3 hours without pause)
    var exceedsLeaderboardThreshold: Bool {
        durationSeconds > 10800 // 3 hours in seconds
    }
}

// MARK: - Fetch Requests

extension StudySession {
    static func fetchToday() -> NSFetchRequest<StudySession> {
        let request = NSFetchRequest<StudySession>(entityName: "StudySession")
        let startOfDay = Calendar.current.startOfDay(for: Date())
        request.predicate = NSPredicate(format: "startedAt >= %@", startOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StudySession.startedAt, ascending: false)]
        return request
    }

    static func fetchUnsynced() -> NSFetchRequest<StudySession> {
        let request = NSFetchRequest<StudySession>(entityName: "StudySession")
        request.predicate = NSPredicate(format: "syncedToRemote == NO")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StudySession.startedAt, ascending: true)]
        return request
    }

    static func fetchForSubject(_ subject: Subject, in range: ClosedRange<Date>) -> NSFetchRequest<StudySession> {
        let request = NSFetchRequest<StudySession>(entityName: "StudySession")
        request.predicate = NSPredicate(
            format: "subject == %@ AND startedAt >= %@ AND startedAt <= %@",
            subject,
            range.lowerBound as NSDate,
            range.upperBound as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StudySession.startedAt, ascending: false)]
        return request
    }
}
