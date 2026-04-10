import CoreData

@objc(DailyStreak)
public class DailyStreak: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var totalMinutes: Int32
    @NSManaged public var subjectBreakdownData: NSDictionary?
}

// MARK: - Convenience

extension DailyStreak {
    var wrappedDate: Date { date ?? Date() }

    /// Typed accessor for the subject breakdown dictionary
    var subjectBreakdown: [String: Int] {
        get {
            guard let data = subjectBreakdownData as? [String: Int] else { return [:] }
            return data
        }
        set {
            subjectBreakdownData = newValue as NSDictionary
        }
    }

    /// Total hours for this day (for heatmap display)
    var totalHours: Double {
        Double(totalMinutes) / 60.0
    }

    /// Intensity level for heatmap coloring (0-4)
    var intensityLevel: Int {
        switch totalMinutes {
        case 0: 0
        case 1...30: 1
        case 31...90: 2
        case 91...180: 3
        default: 4
        }
    }
}

// MARK: - Fetch Requests

extension DailyStreak {
    static func fetchLast(days: Int) -> NSFetchRequest<DailyStreak> {
        let request = NSFetchRequest<DailyStreak>(entityName: "DailyStreak")
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())?.startOfDay ?? Date()
        request.predicate = NSPredicate(format: "date >= %@", startDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DailyStreak.date, ascending: true)]
        return request
    }

    static func fetchForDate(_ date: Date) -> NSFetchRequest<DailyStreak> {
        let request = NSFetchRequest<DailyStreak>(entityName: "DailyStreak")
        let dayStart = date.startOfDay
        request.predicate = NSPredicate(format: "date == %@", dayStart as NSDate)
        request.fetchLimit = 1
        return request
    }
}
