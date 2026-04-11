import CoreData
import WidgetKit

final class PersistenceController {
    static let shared = PersistenceController()

    /// In-memory store for SwiftUI previews and unit tests
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        // Seed preview data
        let subject = Subject(context: context)
        subject.id = UUID()
        subject.name = "Linear Algebra (Strang)"
        subject.shortName = "Strang"
        subject.color = "3B82F6"
        subject.icon = "function"
        subject.category = "Mathematics"
        subject.weeklyTargetMinutes = 600
        subject.sortOrder = 0
        subject.isArchived = false

        let session = StudySession(context: context)
        session.id = UUID()
        session.subject = subject
        session.startedAt = Date().addingTimeInterval(-1500)
        session.endedAt = Date()
        session.durationSeconds = 1500
        session.plannedDurationSeconds = 1500
        session.completedFully = true
        session.pomodoroCount = 1
        session.syncedToRemote = false

        do {
            try context.save()
        } catch {
            fatalError("Preview PersistenceController save failed: \(error)")
        }

        return controller
    }()

    let container: NSPersistentContainer

    /// Main queue context for UI reads
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    init(inMemory: Bool = false, useCloudKit: Bool = false) {
        if useCloudKit {
            container = NSPersistentCloudKitContainer(name: "StudyForge")
        } else {
            container = NSPersistentContainer(name: "StudyForge")
        }

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        // Configure App Group shared store for widget access
        if !inMemory {
            let groupURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: "group.com.estudiosoftware.StudyForge"
            )
            if let storeURL = groupURL?.appendingPathComponent("StudyForge.sqlite") {
                let description = container.persistentStoreDescriptions.first
                    ?? NSPersistentStoreDescription(url: storeURL)
                description.url = storeURL

                if useCloudKit {
                    description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                        containerIdentifier: "iCloud.com.estudiosoftware.StudyForge"
                    )
                }

                container.persistentStoreDescriptions = [description]
            }
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Core Data store failed to load: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    /// Perform a write operation on a background context
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }

    /// Async wrapper for background writes
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) throws -> Void) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            container.performBackgroundTask { context in
                do {
                    try block(context)
                    if context.hasChanges {
                        try context.save()
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Update widget shared data after sessions change.
    /// Called after saving a session or on app foreground.
    func refreshWidgetData() {
        let context = viewContext

        do {
            // Today's stats
            let todaySessions = try context.fetch(StudySession.fetchToday())
            let todayMinutes = Int(todaySessions.reduce(0) { $0 + $1.durationSeconds }) / 60
            let todayCount = todaySessions.count
            let lastSession = todaySessions.first

            // Weekly stats
            let weekStart = Calendar.current.date(from: Calendar.current.dateComponents(
                [.yearForWeekOfYear, .weekOfYear], from: Date()
            )) ?? Date()
            let weekRequest = NSFetchRequest<StudySession>(entityName: "StudySession")
            weekRequest.predicate = NSPredicate(format: "startedAt >= %@", weekStart as NSDate)
            let weekSessions = try context.fetch(weekRequest)
            let weeklyMinutes = Int(weekSessions.reduce(0) { $0 + $1.durationSeconds }) / 60

            // Weekly target (sum of all non-archived subjects)
            let subjectRequest = NSFetchRequest<Subject>(entityName: "Subject")
            subjectRequest.predicate = NSPredicate(format: "isArchived == NO")
            let subjects = try context.fetch(subjectRequest)
            let weeklyTarget = subjects.reduce(0) { $0 + Int($1.weeklyTargetMinutes) }

            // Streak
            let statsRepo = StatsRepository()
            let streak = try statsRepo.fetchCurrentStreak()

            WidgetDataProvider.updateWidgetData(
                todayMinutes: todayMinutes,
                todaySessionCount: todayCount,
                currentStreak: streak,
                weeklyTargetMinutes: weeklyTarget,
                weeklyCompletedMinutes: weeklyMinutes,
                lastSubjectName: lastSession?.subject?.wrappedShortName,
                lastSubjectColor: lastSession?.subject?.wrappedColor
            )

            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            // Non-fatal — widgets just won't update
        }
    }
}
