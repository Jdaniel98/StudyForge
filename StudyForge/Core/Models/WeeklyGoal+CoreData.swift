import CoreData

@objc(WeeklyGoal)
public class WeeklyGoal: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var weekStartDate: Date?
    @NSManaged public var targetMinutes: Int32
    @NSManaged public var achieved: Bool
    @NSManaged public var subject: Subject?
}

// MARK: - Convenience

extension WeeklyGoal {
    var wrappedWeekStartDate: Date { weekStartDate ?? Date().startOfWeek }

    /// Progress as a fraction of the target (0.0 to 1.0+)
    func progress(actualMinutes: Int32) -> Double {
        guard targetMinutes > 0 else { return 0 }
        return Double(actualMinutes) / Double(targetMinutes)
    }
}

// MARK: - Fetch Requests

extension WeeklyGoal {
    static func fetchForWeek(_ weekStart: Date) -> NSFetchRequest<WeeklyGoal> {
        let request = NSFetchRequest<WeeklyGoal>(entityName: "WeeklyGoal")
        request.predicate = NSPredicate(format: "weekStartDate == %@", weekStart as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WeeklyGoal.subject?.sortOrder, ascending: true)]
        return request
    }

    static func fetchForSubjectAndWeek(subject: Subject, weekStart: Date) -> NSFetchRequest<WeeklyGoal> {
        let request = NSFetchRequest<WeeklyGoal>(entityName: "WeeklyGoal")
        request.predicate = NSPredicate(
            format: "subject == %@ AND weekStartDate == %@",
            subject,
            weekStart as NSDate
        )
        request.fetchLimit = 1
        return request
    }
}
