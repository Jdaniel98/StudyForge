import XCTest
import CoreData
@testable import StudyForge

final class PreferencesRepositoryTests: XCTestCase {
    private var persistence: PersistenceController!
    private var sut: PreferencesRepository!

    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        sut = PreferencesRepository(persistenceController: persistence)
    }

    override func tearDown() {
        sut = nil
        persistence = nil
        super.tearDown()
    }

    // MARK: - Fetch Defaults

    func testFetchCreatesDefaultsOnFirstLaunch() throws {
        let prefs = try sut.fetch()

        XCTAssertEqual(prefs.focusDurationSeconds, UserPreferences.defaultFocusDuration)
        XCTAssertEqual(prefs.shortBreakSeconds, UserPreferences.defaultShortBreak)
        XCTAssertEqual(prefs.longBreakSeconds, UserPreferences.defaultLongBreak)
        XCTAssertEqual(prefs.pomosBeforeLongBreak, UserPreferences.defaultPomosBeforeLongBreak)
        XCTAssertTrue(prefs.soundEnabled)
        XCTAssertTrue(prefs.hapticsEnabled)
        XCTAssertFalse(prefs.autoStartBreaks)
        XCTAssertFalse(prefs.autoStartFocus)
        XCTAssertFalse(prefs.iCloudSyncEnabled)
    }

    func testFetchReturnsSameInstanceOnSubsequentCalls() throws {
        let first = try sut.fetch()
        let second = try sut.fetch()

        XCTAssertEqual(first.objectID, second.objectID)
    }

    // MARK: - Update

    func testUpdatePreferences() async throws {
        _ = try sut.fetch() // Create defaults first

        try await sut.update(
            focusDurationSeconds: 3000,
            shortBreakSeconds: 600,
            longBreakSeconds: 1200,
            pomosBeforeLongBreak: 3,
            soundEnabled: false,
            hapticsEnabled: false,
            autoStartBreaks: true,
            autoStartFocus: true,
            iCloudSyncEnabled: true
        )

        let prefs = try sut.fetch()
        XCTAssertEqual(prefs.focusDurationSeconds, 3000)
        XCTAssertEqual(prefs.shortBreakSeconds, 600)
        XCTAssertEqual(prefs.longBreakSeconds, 1200)
        XCTAssertEqual(prefs.pomosBeforeLongBreak, 3)
        XCTAssertFalse(prefs.soundEnabled)
        XCTAssertFalse(prefs.hapticsEnabled)
        XCTAssertTrue(prefs.autoStartBreaks)
        XCTAssertTrue(prefs.autoStartFocus)
        XCTAssertTrue(prefs.iCloudSyncEnabled)
    }

    func testUpdateCreatesDefaultsIfNoneExist() async throws {
        // Don't call fetch() first — update should handle missing prefs
        try await sut.update(
            focusDurationSeconds: 2000,
            shortBreakSeconds: 400,
            longBreakSeconds: 800,
            pomosBeforeLongBreak: 2,
            soundEnabled: true,
            hapticsEnabled: true,
            autoStartBreaks: false,
            autoStartFocus: false,
            iCloudSyncEnabled: false
        )

        let prefs = try sut.fetch()
        XCTAssertEqual(prefs.focusDurationSeconds, 2000)
    }
}
