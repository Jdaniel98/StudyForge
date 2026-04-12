import XCTest
import CoreData
@testable import StudyForge

final class StatsRepositoryTests: XCTestCase {
    private var persistence: PersistenceController!
    private var sut: StatsRepository!

    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        sut = StatsRepository(persistenceController: persistence)
    }

    override func tearDown() {
        sut = nil
        persistence = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func createDailyStreak(daysAgo: Int, totalMinutes: Int32) {
        let context = persistence.viewContext
        let streak = DailyStreak(context: context)
        streak.id = UUID()
        streak.date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date().startOfDay)!
        streak.totalMinutes = totalMinutes
        streak.subjectBreakdown = ["Test": Int(totalMinutes)]
        try! context.save()
    }

    private func createSubjectWithSession(durationSeconds: Int32, daysAgo: Int = 0) -> Subject {
        let context = persistence.viewContext
        let subject = Subject(context: context)
        subject.id = UUID()
        subject.name = "Test \(UUID().uuidString.prefix(4))"
        subject.shortName = "Test"
        subject.color = "3B82F6"
        subject.icon = "book.fill"
        subject.category = "Custom"
        subject.weeklyTargetMinutes = 600
        subject.sortOrder = 0
        subject.isArchived = false

        let session = StudySession(context: context)
        session.id = UUID()
        session.subject = subject
        let startDate = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        session.startedAt = startDate.addingTimeInterval(TimeInterval(-durationSeconds))
        session.endedAt = startDate
        session.durationSeconds = durationSeconds
        session.plannedDurationSeconds = 1500
        session.completedFully = true
        session.pomodoroCount = 1
        session.syncedToRemote = false

        try! context.save()
        return subject
    }

    // MARK: - Current Streak

    func testCurrentStreakWithNoData() throws {
        let streak = try sut.fetchCurrentStreak()
        XCTAssertEqual(streak, 0)
    }

    func testCurrentStreakWithTodayOnly() throws {
        createDailyStreak(daysAgo: 0, totalMinutes: 30)

        let streak = try sut.fetchCurrentStreak()
        XCTAssertEqual(streak, 1)
    }

    func testCurrentStreakConsecutiveDays() throws {
        createDailyStreak(daysAgo: 0, totalMinutes: 30)
        createDailyStreak(daysAgo: 1, totalMinutes: 25)
        createDailyStreak(daysAgo: 2, totalMinutes: 40)

        let streak = try sut.fetchCurrentStreak()
        XCTAssertEqual(streak, 3)
    }

    func testCurrentStreakBreaksOnGap() throws {
        createDailyStreak(daysAgo: 0, totalMinutes: 30)
        createDailyStreak(daysAgo: 1, totalMinutes: 25)
        // Gap at daysAgo: 2
        createDailyStreak(daysAgo: 3, totalMinutes: 40)

        let streak = try sut.fetchCurrentStreak()
        XCTAssertEqual(streak, 2)
    }

    func testCurrentStreakStartsFromYesterdayIfNoToday() throws {
        createDailyStreak(daysAgo: 1, totalMinutes: 30)
        createDailyStreak(daysAgo: 2, totalMinutes: 25)

        let streak = try sut.fetchCurrentStreak()
        XCTAssertEqual(streak, 2)
    }

    func testCurrentStreakZeroMinutesBreaksStreak() throws {
        createDailyStreak(daysAgo: 0, totalMinutes: 30)
        createDailyStreak(daysAgo: 1, totalMinutes: 0) // Zero minutes = no study
        createDailyStreak(daysAgo: 2, totalMinutes: 40)

        let streak = try sut.fetchCurrentStreak()
        XCTAssertEqual(streak, 1)
    }

    // MARK: - Longest Streak

    func testLongestStreakWithNoData() throws {
        let longest = try sut.fetchLongestStreak()
        XCTAssertEqual(longest, 0)
    }

    func testLongestStreakFindsMaxRun() throws {
        // Old streak: 3 days
        createDailyStreak(daysAgo: 10, totalMinutes: 30)
        createDailyStreak(daysAgo: 9, totalMinutes: 30)
        createDailyStreak(daysAgo: 8, totalMinutes: 30)
        // Gap
        // Recent streak: 2 days
        createDailyStreak(daysAgo: 1, totalMinutes: 30)
        createDailyStreak(daysAgo: 0, totalMinutes: 30)

        let longest = try sut.fetchLongestStreak()
        XCTAssertEqual(longest, 3)
    }

    // MARK: - Daily Streaks Fetch

    func testFetchDailyStreaksLast7Days() throws {
        createDailyStreak(daysAgo: 0, totalMinutes: 30)
        createDailyStreak(daysAgo: 3, totalMinutes: 25)
        createDailyStreak(daysAgo: 10, totalMinutes: 40) // Outside 7-day window

        let streaks = try sut.fetchDailyStreaks(last: 7)
        XCTAssertEqual(streaks.count, 2) // Only within 7 days
    }

    // MARK: - Weekly Totals

    func testFetchWeeklyTotalForSubject() throws {
        let subject = createSubjectWithSession(durationSeconds: 1500, daysAgo: 0)

        let total = try sut.fetchWeeklyTotal(for: subject)
        XCTAssertEqual(total, 1500)
    }

    func testFetchWeeklyTotalAllSubjects() throws {
        _ = createSubjectWithSession(durationSeconds: 1500, daysAgo: 0)
        _ = createSubjectWithSession(durationSeconds: 1200, daysAgo: 0)

        let total = try sut.fetchWeeklyTotalAll()
        XCTAssertEqual(total, 2700)
    }

    // MARK: - Today Stats

    func testFetchTodayTotalMinutes() throws {
        _ = createSubjectWithSession(durationSeconds: 1800, daysAgo: 0) // 30 minutes

        let minutes = try sut.fetchTodayTotalMinutes()
        XCTAssertEqual(minutes, 30)
    }

    func testFetchTodayTotalMinutesWhenEmpty() throws {
        let minutes = try sut.fetchTodayTotalMinutes()
        XCTAssertEqual(minutes, 0)
    }
}
