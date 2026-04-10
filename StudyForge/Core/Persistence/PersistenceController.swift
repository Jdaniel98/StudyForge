import CoreData

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

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "StudyForge")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
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
}
