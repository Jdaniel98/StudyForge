import CoreData

final class StatsRepository {
    private let persistenceController: PersistenceController

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    // MARK: - Daily Streaks

    func fetchDailyStreaks(last days: Int) throws -> [DailyStreak] {
        let request = DailyStreak.fetchLast(days: days)
        return try persistenceController.viewContext.fetch(request)
    }

    /// Returns the current consecutive-day streak count.
    /// A streak breaks when a day has zero study minutes.
    func fetchCurrentStreak() throws -> Int {
        let request = DailyStreak.fetchLast(days: 365)
        let streaks = try persistenceController.viewContext.fetch(request)

        guard !streaks.isEmpty else { return 0 }

        let calendar = Calendar.current
        var currentDate = Date().startOfDay
        var streakCount = 0

        // Check if today has any study time; if not, start from yesterday
        if let todayStreak = streaks.last, todayStreak.wrappedDate == currentDate, todayStreak.totalMinutes > 0 {
            streakCount = 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        } else {
            // No study today — check if yesterday had study time
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }

        // Walk backwards through dates
        let streaksByDate = Dictionary(uniqueKeysWithValues: streaks.map { ($0.wrappedDate, $0) })

        while let streak = streaksByDate[currentDate], streak.totalMinutes > 0 {
            streakCount += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }

        return streakCount
    }

    /// Returns the longest consecutive-day streak ever recorded.
    func fetchLongestStreak() throws -> Int {
        let request = DailyStreak.fetchLast(days: 365)
        let streaks = try persistenceController.viewContext.fetch(request)
        guard !streaks.isEmpty else { return 0 }

        let calendar = Calendar.current
        let streaksByDate = Dictionary(uniqueKeysWithValues: streaks.map { ($0.wrappedDate, $0) })

        var longest = 0
        var current = 0
        let today = Date().startOfDay

        for dayOffset in (0..<365).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            if let streak = streaksByDate[date.startOfDay], streak.totalMinutes > 0 {
                current += 1
                longest = max(longest, current)
            } else {
                current = 0
            }
        }

        return longest
    }

    // MARK: - Weekly Stats

    /// Total seconds studied this week for a specific subject
    func fetchWeeklyTotal(for subject: Subject) throws -> Int32 {
        let weekStart = Date().startOfWeek
        let weekEnd = Date().endOfDay
        let range = weekStart...weekEnd

        let request = StudySession.fetchForSubject(subject, in: range)
        let sessions = try persistenceController.viewContext.fetch(request)
        return sessions.reduce(0) { $0 + $1.durationSeconds }
    }

    /// Total seconds studied this week across all subjects
    func fetchWeeklyTotalAll() throws -> Int32 {
        let weekStart = Date().startOfWeek
        let request = NSFetchRequest<StudySession>(entityName: "StudySession")
        request.predicate = NSPredicate(format: "startedAt >= %@", weekStart as NSDate)
        let sessions = try persistenceController.viewContext.fetch(request)
        return sessions.reduce(0) { $0 + $1.durationSeconds }
    }

    // MARK: - Today Stats

    func fetchTodayTotalMinutes() throws -> Int32 {
        let startOfDay = Date().startOfDay
        let request = NSFetchRequest<StudySession>(entityName: "StudySession")
        request.predicate = NSPredicate(format: "startedAt >= %@", startOfDay as NSDate)
        let sessions = try persistenceController.viewContext.fetch(request)
        return sessions.reduce(0) { $0 + $1.durationSeconds } / 60
    }
}
