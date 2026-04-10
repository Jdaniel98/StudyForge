import CoreData

final class GoalRepository {
    private let persistenceController: PersistenceController

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    // MARK: - Reads

    /// Fetches the weekly goal for a subject in the current week, creating one if it doesn't exist.
    func fetchOrCreate(for subject: Subject) throws -> WeeklyGoal {
        let weekStart = Date().startOfWeek
        let request = WeeklyGoal.fetchForSubjectAndWeek(subject: subject, weekStart: weekStart)
        let existing = try persistenceController.viewContext.fetch(request)

        if let goal = existing.first {
            return goal
        }

        // Create a new goal using the subject's default weekly target
        let goal = WeeklyGoal(context: persistenceController.viewContext)
        goal.id = UUID()
        goal.subject = subject
        goal.weekStartDate = weekStart
        goal.targetMinutes = subject.weeklyTargetMinutes
        goal.achieved = false

        try persistenceController.viewContext.save()
        return goal
    }

    /// Fetches all goals for the current week
    func fetchCurrentWeekGoals() throws -> [WeeklyGoal] {
        let request = WeeklyGoal.fetchForWeek(Date().startOfWeek)
        return try persistenceController.viewContext.fetch(request)
    }

    // MARK: - Writes

    func updateAchieved(_ goalID: UUID, achieved: Bool) async throws {
        try await persistenceController.performBackgroundTask { context in
            let request = NSFetchRequest<WeeklyGoal>(entityName: "WeeklyGoal")
            request.predicate = NSPredicate(format: "id == %@", goalID as CVarArg)
            request.fetchLimit = 1

            guard let goal = try context.fetch(request).first else {
                throw AppError.entityNotFound("WeeklyGoal")
            }

            goal.achieved = achieved
        }
    }
}
