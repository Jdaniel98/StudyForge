import CoreData

final class SessionRepository {
    private let persistenceController: PersistenceController

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    // MARK: - Reads (main context)

    func fetchTodaySessions() throws -> [StudySession] {
        let request = StudySession.fetchToday()
        return try persistenceController.viewContext.fetch(request)
    }

    func fetchTodayTotalSeconds() throws -> Int32 {
        let sessions = try fetchTodaySessions()
        return sessions.reduce(0) { $0 + $1.durationSeconds }
    }

    func fetchTodaySessionCount() throws -> Int {
        let request = StudySession.fetchToday()
        return try persistenceController.viewContext.count(for: request)
    }

    func fetchSessions(for subject: Subject, in range: ClosedRange<Date>) throws -> [StudySession] {
        let request = StudySession.fetchForSubject(subject, in: range)
        return try persistenceController.viewContext.fetch(request)
    }

    // MARK: - Write: Save Completed Session

    /// Saves a completed study session and updates the DailyStreak.
    /// This is the primary write path — called by TimerService when a session ends.
    func saveCompletedSession(
        subjectID: UUID,
        startedAt: Date,
        endedAt: Date,
        durationSeconds: Int32,
        plannedDurationSeconds: Int32,
        completedFully: Bool,
        pomodoroCount: Int16,
        notes: String?
    ) async throws {
        try await persistenceController.performBackgroundTask { context in
            // Find the subject in this context
            let subjectRequest = NSFetchRequest<Subject>(entityName: "Subject")
            subjectRequest.predicate = NSPredicate(format: "id == %@", subjectID as CVarArg)
            subjectRequest.fetchLimit = 1

            guard let subject = try context.fetch(subjectRequest).first else {
                throw AppError.entityNotFound("Subject")
            }

            // Create the session
            let session = StudySession(context: context)
            session.id = UUID()
            session.subject = subject
            session.startedAt = startedAt
            session.endedAt = endedAt
            session.durationSeconds = durationSeconds
            session.plannedDurationSeconds = plannedDurationSeconds
            session.completedFully = completedFully
            session.pomodoroCount = pomodoroCount
            session.notes = notes
            session.syncedToRemote = false

            // Update DailyStreak for today
            try Self.updateDailyStreak(
                for: startedAt,
                subjectName: subject.wrappedShortName,
                additionalMinutes: durationSeconds / 60,
                in: context
            )
        }
    }

    // MARK: - DailyStreak Update

    /// Updates or creates the DailyStreak entry for the given date.
    /// Called internally whenever a session is saved.
    private static func updateDailyStreak(
        for date: Date,
        subjectName: String,
        additionalMinutes: Int32,
        in context: NSManagedObjectContext
    ) throws {
        let dayStart = date.startOfDay
        let request = DailyStreak.fetchForDate(dayStart)
        let existing = try context.fetch(request).first

        if let streak = existing {
            streak.totalMinutes += additionalMinutes
            var breakdown = streak.subjectBreakdown
            breakdown[subjectName, default: 0] += Int(additionalMinutes)
            streak.subjectBreakdown = breakdown
        } else {
            let streak = DailyStreak(context: context)
            streak.id = UUID()
            streak.date = dayStart
            streak.totalMinutes = additionalMinutes
            streak.subjectBreakdown = [subjectName: Int(additionalMinutes)]
        }
    }
}
