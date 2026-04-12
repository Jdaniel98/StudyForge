import XCTest
import CoreData
@testable import StudyForge

final class SubjectRepositoryTests: XCTestCase {
    private var persistence: PersistenceController!
    private var sut: SubjectRepository!

    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        sut = SubjectRepository(persistenceController: persistence)
    }

    override func tearDown() {
        sut = nil
        persistence = nil
        super.tearDown()
    }

    // MARK: - Create

    func testCreateSubject() async throws {
        try await sut.create(
            name: "Linear Algebra",
            shortName: "LinAlg",
            color: "3B82F6",
            icon: "function",
            category: "Mathematics",
            weeklyTargetMinutes: 600
        )

        let subjects = try sut.fetchAll()
        XCTAssertEqual(subjects.count, 1)
        XCTAssertEqual(subjects.first?.wrappedName, "Linear Algebra")
        XCTAssertEqual(subjects.first?.wrappedShortName, "LinAlg")
        XCTAssertEqual(subjects.first?.wrappedColor, "3B82F6")
        XCTAssertEqual(subjects.first?.wrappedIcon, "function")
        XCTAssertEqual(subjects.first?.wrappedCategory, "Mathematics")
        XCTAssertEqual(subjects.first?.weeklyTargetMinutes, 600)
        XCTAssertFalse(subjects.first?.isArchived ?? true)
    }

    func testCreateTrimsWhitespace() async throws {
        try await sut.create(
            name: "  Calculus  ",
            shortName: "  Calc  ",
            color: "3B82F6",
            icon: "function",
            category: "Mathematics",
            weeklyTargetMinutes: 300
        )

        let subjects = try sut.fetchAll()
        XCTAssertEqual(subjects.first?.wrappedName, "Calculus")
        XCTAssertEqual(subjects.first?.wrappedShortName, "Calc")
    }

    func testCreateRejectsDuplicateName() async throws {
        try await sut.create(
            name: "Physics",
            shortName: "Phys",
            color: "EF4444",
            icon: "atom",
            category: "Science",
            weeklyTargetMinutes: 300
        )

        do {
            try await sut.create(
                name: "physics", // Same name, different case
                shortName: "Phys2",
                color: "EF4444",
                icon: "atom",
                category: "Science",
                weeklyTargetMinutes: 300
            )
            XCTFail("Should have thrown duplicate error")
        } catch {
            // Expected
        }
    }

    func testCreateRejectsEmptyName() async throws {
        do {
            try await sut.create(
                name: "   ",
                shortName: "X",
                color: "3B82F6",
                icon: "book.fill",
                category: "Custom",
                weeklyTargetMinutes: 300
            )
            XCTFail("Should have thrown empty name error")
        } catch {
            // Expected
        }
    }

    func testCreateAssignsSortOrder() async throws {
        try await sut.create(name: "Subject A", shortName: "A", color: "3B82F6", icon: "book.fill", category: "Custom", weeklyTargetMinutes: 300)
        try await sut.create(name: "Subject B", shortName: "B", color: "EF4444", icon: "book.fill", category: "Custom", weeklyTargetMinutes: 300)

        let subjects = try sut.fetchAll()
        let sorted = subjects.sorted { $0.sortOrder < $1.sortOrder }
        XCTAssertEqual(sorted.count, 2)
        XCTAssertEqual(sorted[0].sortOrder, 0)
        XCTAssertEqual(sorted[1].sortOrder, 1)
    }

    // MARK: - Fetch

    func testFetchAllExcludesArchived() async throws {
        try await sut.create(name: "Active", shortName: "Act", color: "3B82F6", icon: "book.fill", category: "Custom", weeklyTargetMinutes: 300)
        try await sut.create(name: "ToArchive", shortName: "Arc", color: "EF4444", icon: "book.fill", category: "Custom", weeklyTargetMinutes: 300)

        let all = try sut.fetchAll()
        let toArchive = all.first { $0.wrappedName == "ToArchive" }
        XCTAssertNotNil(toArchive?.id)

        try await sut.archive(toArchive!.id!)

        let active = try sut.fetchAll()
        XCTAssertEqual(active.count, 1)
        XCTAssertEqual(active.first?.wrappedName, "Active")
    }

    func testFetchIncludingArchivedReturnsAll() async throws {
        try await sut.create(name: "Active", shortName: "Act", color: "3B82F6", icon: "book.fill", category: "Custom", weeklyTargetMinutes: 300)
        try await sut.create(name: "ToArchive", shortName: "Arc", color: "EF4444", icon: "book.fill", category: "Custom", weeklyTargetMinutes: 300)

        let toArchive = try sut.fetchAll().first { $0.wrappedName == "ToArchive" }
        try await sut.archive(toArchive!.id!)

        let all = try sut.fetchIncludingArchived()
        XCTAssertEqual(all.count, 2)
    }

    func testSubjectCount() async throws {
        XCTAssertEqual(try sut.subjectCount(), 0)

        try await sut.create(name: "A", shortName: "A", color: "3B82F6", icon: "book.fill", category: "Custom", weeklyTargetMinutes: 300)
        try await sut.create(name: "B", shortName: "B", color: "EF4444", icon: "book.fill", category: "Custom", weeklyTargetMinutes: 300)

        XCTAssertEqual(try sut.subjectCount(), 2)
    }

    // MARK: - Update

    func testUpdateSubject() async throws {
        try await sut.create(name: "Old Name", shortName: "Old", color: "3B82F6", icon: "book.fill", category: "Custom", weeklyTargetMinutes: 300)

        let subject = try sut.fetchAll().first!
        try await sut.update(
            subject.id!,
            name: "New Name",
            shortName: "New",
            color: "EF4444",
            icon: "atom",
            category: "Science",
            weeklyTargetMinutes: 600
        )

        let updated = try sut.fetchAll().first!
        XCTAssertEqual(updated.wrappedName, "New Name")
        XCTAssertEqual(updated.wrappedShortName, "New")
        XCTAssertEqual(updated.wrappedColor, "EF4444")
        XCTAssertEqual(updated.weeklyTargetMinutes, 600)
    }

    func testUpdateRejectsEmptyName() async throws {
        try await sut.create(name: "Valid", shortName: "V", color: "3B82F6", icon: "book.fill", category: "Custom", weeklyTargetMinutes: 300)

        let subject = try sut.fetchAll().first!
        do {
            try await sut.update(subject.id!, name: "  ", shortName: "V", color: "3B82F6", icon: "book.fill", category: "Custom", weeklyTargetMinutes: 300)
            XCTFail("Should have thrown empty name error")
        } catch {
            // Expected
        }
    }

    // MARK: - Archive

    func testArchiveSubject() async throws {
        try await sut.create(name: "ToArchive", shortName: "Arc", color: "3B82F6", icon: "book.fill", category: "Custom", weeklyTargetMinutes: 300)

        let subject = try sut.fetchAll().first!
        try await sut.archive(subject.id!)

        // Allow background context merge to propagate
        try await Task.sleep(nanoseconds: 200_000_000)

        let active = try sut.fetchAll()
        XCTAssertEqual(active.count, 0)

        let all = try sut.fetchIncludingArchived()
        XCTAssertEqual(all.count, 1)
        XCTAssertTrue(all.first?.isArchived ?? false)
    }

    // MARK: - Reorder

    func testReorderSubjects() async throws {
        try await sut.create(name: "A", shortName: "A", color: "3B82F6", icon: "book.fill", category: "Custom", weeklyTargetMinutes: 300)
        try await sut.create(name: "B", shortName: "B", color: "EF4444", icon: "book.fill", category: "Custom", weeklyTargetMinutes: 300)
        try await sut.create(name: "C", shortName: "C", color: "10B981", icon: "book.fill", category: "Custom", weeklyTargetMinutes: 300)

        let subjects = try sut.fetchAll()
        let ids = subjects.sorted { $0.sortOrder < $1.sortOrder }.compactMap(\.id)
        XCTAssertEqual(ids.count, 3)

        // Reverse the order
        try await sut.reorder(ids.reversed())

        let reordered = try sut.fetchAll().sorted { $0.sortOrder < $1.sortOrder }
        XCTAssertEqual(reordered[0].id, ids[2])
        XCTAssertEqual(reordered[1].id, ids[1])
        XCTAssertEqual(reordered[2].id, ids[0])
    }
}
