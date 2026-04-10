import CoreData

final class SubjectRepository {
    private let persistenceController: PersistenceController

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    // MARK: - Reads (main context)

    func fetchAll() throws -> [Subject] {
        let request = Subject.fetchAllActive()
        return try persistenceController.viewContext.fetch(request)
    }

    func fetchIncludingArchived() throws -> [Subject] {
        let request = Subject.fetchAll()
        return try persistenceController.viewContext.fetch(request)
    }

    func subjectCount() throws -> Int {
        let request = Subject.fetchAllActive()
        return try persistenceController.viewContext.count(for: request)
    }

    // MARK: - Writes (background context)

    func create(
        name: String,
        shortName: String,
        color: String,
        icon: String,
        category: String,
        weeklyTargetMinutes: Int32
    ) async throws {
        // Validate uniqueness
        let existing = try fetchAll()
        if existing.contains(where: { $0.wrappedName.lowercased() == name.lowercased() }) {
            throw AppError.subjectNameDuplicate(name)
        }

        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.subjectNameEmpty
        }

        let nextSortOrder = Int16(existing.count)

        try await persistenceController.performBackgroundTask { context in
            let subject = Subject(context: context)
            subject.id = UUID()
            subject.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            subject.shortName = shortName.trimmingCharacters(in: .whitespacesAndNewlines)
            subject.color = color
            subject.icon = icon
            subject.category = category
            subject.weeklyTargetMinutes = weeklyTargetMinutes
            subject.sortOrder = nextSortOrder
            subject.isArchived = false
        }
    }

    func update(_ subjectID: UUID, name: String, shortName: String, color: String, icon: String, category: String, weeklyTargetMinutes: Int32) async throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.subjectNameEmpty
        }

        try await persistenceController.performBackgroundTask { context in
            let request = NSFetchRequest<Subject>(entityName: "Subject")
            request.predicate = NSPredicate(format: "id == %@", subjectID as CVarArg)
            request.fetchLimit = 1

            guard let subject = try context.fetch(request).first else {
                throw AppError.entityNotFound("Subject")
            }

            subject.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            subject.shortName = shortName.trimmingCharacters(in: .whitespacesAndNewlines)
            subject.color = color
            subject.icon = icon
            subject.category = category
            subject.weeklyTargetMinutes = weeklyTargetMinutes
        }
    }

    func archive(_ subjectID: UUID) async throws {
        try await persistenceController.performBackgroundTask { context in
            let request = NSFetchRequest<Subject>(entityName: "Subject")
            request.predicate = NSPredicate(format: "id == %@", subjectID as CVarArg)
            request.fetchLimit = 1

            guard let subject = try context.fetch(request).first else {
                throw AppError.entityNotFound("Subject")
            }

            subject.isArchived = true
        }
    }

    func reorder(_ subjectIDs: [UUID]) async throws {
        try await persistenceController.performBackgroundTask { context in
            let request = NSFetchRequest<Subject>(entityName: "Subject")
            let subjects = try context.fetch(request)

            for (index, id) in subjectIDs.enumerated() {
                if let subject = subjects.first(where: { $0.id == id }) {
                    subject.sortOrder = Int16(index)
                }
            }
        }
    }
}
