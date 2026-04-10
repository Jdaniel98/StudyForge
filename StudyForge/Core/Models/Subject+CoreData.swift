import CoreData
import SwiftUI

@objc(Subject)
public class Subject: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var shortName: String?
    @NSManaged public var color: String?
    @NSManaged public var icon: String?
    @NSManaged public var weeklyTargetMinutes: Int32
    @NSManaged public var sortOrder: Int16
    @NSManaged public var isArchived: Bool
    @NSManaged public var category: String?
    @NSManaged public var sessions: NSSet?
}

// MARK: - Convenience

extension Subject {
    var wrappedName: String { name ?? "Untitled" }
    var wrappedShortName: String { shortName ?? wrappedName }
    var wrappedColor: String { color ?? "3B82F6" }
    var wrappedIcon: String { icon ?? "book.fill" }
    var wrappedCategory: String { category ?? "Custom" }

    var swiftUIColor: Color { Color(hex: wrappedColor) }

    var sessionsArray: [StudySession] {
        let set = sessions as? Set<StudySession> ?? []
        return set.sorted { ($0.startedAt ?? .distantPast) > ($1.startedAt ?? .distantPast) }
    }

    /// Total seconds studied across all sessions
    var totalStudiedSeconds: Int32 {
        sessionsArray.reduce(0) { $0 + $1.durationSeconds }
    }

    /// Total hours studied (for display)
    var totalStudiedHours: Double {
        Double(totalStudiedSeconds) / 3600.0
    }
}

// MARK: - Fetch Requests

extension Subject {
    static func fetchAllActive() -> NSFetchRequest<Subject> {
        let request = NSFetchRequest<Subject>(entityName: "Subject")
        request.predicate = NSPredicate(format: "isArchived == NO")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Subject.sortOrder, ascending: true)]
        return request
    }

    static func fetchAll() -> NSFetchRequest<Subject> {
        let request = NSFetchRequest<Subject>(entityName: "Subject")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Subject.sortOrder, ascending: true)]
        return request
    }
}

// MARK: - Generated accessors for sessions

extension Subject {
    @objc(addSessionsObject:)
    @NSManaged public func addToSessions(_ value: StudySession)

    @objc(removeSessionsObject:)
    @NSManaged public func removeFromSessions(_ value: StudySession)

    @objc(addSessions:)
    @NSManaged public func addToSessions(_ values: NSSet)

    @objc(removeSessions:)
    @NSManaged public func removeFromSessions(_ values: NSSet)
}
