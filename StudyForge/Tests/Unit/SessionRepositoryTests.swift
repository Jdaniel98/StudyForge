import XCTest
import CoreData
@testable import StudyForge

final class SessionRepositoryTests: XCTestCase {
    private var persistence: PersistenceController!
    private var sut: SessionRepository!
    private var subjectID: UUID!

    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        sut = SessionRepository(persistenceController: persistence)

        // Create a subject for sessions
        subjectID = UUID()
        let context = persistence.viewContext
        let subject = Subject(context: context)
        subject.id = subjectID
        subject.name = "Test Subject"
        subject.shortName = "Test"
        subject.color = "3B82F6"
        subject.icon = "book.fill"
        subject.category = "Custom"
        subject.weeklyTargetMinutes = 600
        subject.sortOrder = 0
        subject.isArchived = false
        try! context.save()
    }

    override func tearDown() {
        sut = nil
        persistence = nil
        subjectID = nil
        super.tearDown()
    }

    // MARK: - Save Session

    func testSaveCompletedSession() async throws {
        let startedAt = Date().addingTimeInterval(-1500)
        let endedAt = Date()

        try await sut.saveCompletedSession(
            subjectID: subjectID,
            startedAt: startedAt,
            endedAt: endedAt,
            durationSeconds: 1500,
            plannedDurationSeconds: 1500,
            completedFully: true,
            pomodoroCount: 1,
            notes: "Good session"
        )

        let sessions = try sut.fetchTodaySessions()
        XCTAssertEqual(sessions.count, 1)

        let session = sessions.first!
        XCTAssertEqual(session.durationSeconds, 1500)
        XCTAssertEqual(session.plannedDurationSeconds, 1500)
        XCTAssertTrue(session.completedFully)
        XCTAssertEqual(session.pomodoroCount, 1)
        XCTAssertEqual(session.notes, "Good session")
        XCTAssertFalse(session.syncedToRemote)
        XCTAssertNotNil(session.id)
    }

    func testSavePartialSession() async throws {
        try await sut.saveCompletedSession(
            subjectID: subjectID,
            startedAt: Date().addingTimeInterval(-600),
            endedAt: Date(),
            durationSeconds: 600,
            plannedDurationSeconds: 1500,
            completedFully: false,
            pomodoroCount: 1,
            notes: nil
        )

        let sessions = try sut.fetchTodaySessions()
        XCTAssertEqual(sessions.count, 1)
        XCTAssertFalse(sessions.first!.completedFully)
        XCTAssertEqual(sessions.first!.durationSeconds, 600)
    }

    func testSaveSessionThrowsForInvalidSubject() async {
        do {
            try await sut.saveCompletedSession(
                subjectID: UUID(), // Non-existent subject
                startedAt: Date(),
                endedAt: Date(),
                durationSeconds: 100,
                plannedDurationSeconds: 1500,
                completedFully: false,
                pomodoroCount: 1,
                notes: nil
            )
            XCTFail("Should have thrown entity not found error")
        } catch {
            // Expected
        }
    }

    // MARK: - DailyStreak Update

    func testSaveSessionUpdatesDailyStreak() async throws {
        try await sut.saveCompletedSession(
            subjectID: subjectID,
            startedAt: Date().addingTimeInterval(-1500),
            endedAt: Date(),
            durationSeconds: 1500, // 25 minutes
            plannedDurationSeconds: 1500,
            completedFully: true,
            pomodoroCount: 1,
            notes: nil
        )

        let context = persistence.viewContext
        let request = DailyStreak.fetchForDate(Date().startOfDay)
        let streaks = try context.fetch(request)

        XCTAssertEqual(streaks.count, 1)
        XCTAssertEqual(streaks.first?.totalMinutes, 25)
    }

    func testMultipleSessionsAccumulateDailyStreak() async throws {
        // First session: 25 minutes
        try await sut.saveCompletedSession(
            subjectID: subjectID,
            startedAt: Date().addingTimeInterval(-3000),
            endedAt: Date().addingTimeInterval(-1500),
            durationSeconds: 1500,
            plannedDurationSeconds: 1500,
            completedFully: true,
            pomodoroCount: 1,
            notes: nil
        )

        // Second session: 25 minutes
        try await sut.saveCompletedSession(
            subjectID: subjectID,
            startedAt: Date().addingTimeInterval(-1500),
            endedAt: Date(),
            durationSeconds: 1500,
            plannedDurationSeconds: 1500,
            completedFully: true,
            pomodoroCount: 1,
            notes: nil
        )

        let context = persistence.viewContext
        let request = DailyStreak.fetchForDate(Date().startOfDay)
        let streaks = try context.fetch(request)

        XCTAssertEqual(streaks.count, 1)
        XCTAssertEqual(streaks.first?.totalMinutes, 50) // 25 + 25
    }

    // MARK: - Today Stats

    func testFetchTodayTotalSeconds() async throws {
        try await sut.saveCompletedSession(
            subjectID: subjectID,
            startedAt: Date().addingTimeInterval(-1500),
            endedAt: Date(),
            durationSeconds: 1500,
            plannedDurationSeconds: 1500,
            completedFully: true,
            pomodoroCount: 1,
            notes: nil
        )

        let total = try sut.fetchTodayTotalSeconds()
        XCTAssertEqual(total, 1500)
    }

    func testFetchTodaySessionCount() async throws {
        try await sut.saveCompletedSession(
            subjectID: subjectID,
            startedAt: Date().addingTimeInterval(-3000),
            endedAt: Date().addingTimeInterval(-1500),
            durationSeconds: 1500,
            plannedDurationSeconds: 1500,
            completedFully: true,
            pomodoroCount: 1,
            notes: nil
        )

        try await sut.saveCompletedSession(
            subjectID: subjectID,
            startedAt: Date().addingTimeInterval(-1500),
            endedAt: Date(),
            durationSeconds: 1500,
            plannedDurationSeconds: 1500,
            completedFully: true,
            pomodoroCount: 1,
            notes: nil
        )

        let count = try sut.fetchTodaySessionCount()
        XCTAssertEqual(count, 2)
    }

    func testFetchTodaySessionsWhenEmpty() throws {
        let sessions = try sut.fetchTodaySessions()
        XCTAssertTrue(sessions.isEmpty)

        let total = try sut.fetchTodayTotalSeconds()
        XCTAssertEqual(total, 0)

        let count = try sut.fetchTodaySessionCount()
        XCTAssertEqual(count, 0)
    }
}
