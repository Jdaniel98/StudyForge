import CoreData

enum SeedDataService {
    struct SeedSubject {
        let name: String
        let shortName: String
        let color: SubjectColor
        let icon: String
        let category: SubjectCategory
        let weeklyTargetMinutes: Int32
    }

    static let defaultSubjects: [SeedSubject] = [
        SeedSubject(
            name: "Linear Algebra",
            shortName: "Lin Alg",
            color: .blue,
            icon: "function",
            category: .mathematics,
            weeklyTargetMinutes: 600
        ),
        SeedSubject(
            name: "Algorithms & Data Structures",
            shortName: "Algorithms",
            color: .amber,
            icon: "cpu",
            category: .csTheory,
            weeklyTargetMinutes: 480
        ),
        SeedSubject(
            name: "Quantitative Finance",
            shortName: "Quant",
            color: .emerald,
            icon: "chart.line.uptrend.xyaxis",
            category: .finance,
            weeklyTargetMinutes: 420
        ),
        SeedSubject(
            name: "Machine Learning",
            shortName: "ML",
            color: .violet,
            icon: "brain",
            category: .machineLearning,
            weeklyTargetMinutes: 480
        ),
        SeedSubject(
            name: "Systems Programming",
            shortName: "Systems",
            color: .rose,
            icon: "terminal",
            category: .systemsProgramming,
            weeklyTargetMinutes: 360
        ),
        SeedSubject(
            name: "Language Study",
            shortName: "Language",
            color: .cyan,
            icon: "character.book.closed",
            category: .languageLearning,
            weeklyTargetMinutes: 300
        ),
    ]

    /// Returns true if there are no subjects in the store (first launch)
    static func needsSeeding(context: NSManagedObjectContext) -> Bool {
        let request = Subject.fetchAll()
        let count = (try? context.count(for: request)) ?? 0
        return count == 0
    }

    /// Seeds the store with default subjects. User can delete/archive any they don't want.
    static func seedDefaults(context: NSManagedObjectContext) throws {
        for (index, seed) in defaultSubjects.enumerated() {
            let subject = Subject(context: context)
            subject.id = UUID()
            subject.name = seed.name
            subject.shortName = seed.shortName
            subject.color = seed.color.rawValue
            subject.icon = seed.icon
            subject.category = seed.category.rawValue
            subject.weeklyTargetMinutes = seed.weeklyTargetMinutes
            subject.sortOrder = Int16(index)
            subject.isArchived = false
        }

        try context.save()
    }
}
