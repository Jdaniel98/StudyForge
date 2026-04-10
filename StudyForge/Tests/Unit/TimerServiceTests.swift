import XCTest
@testable import StudyForge

final class TimerServiceTests: XCTestCase {
    func testInitialStateIsIdle() {
        let service = TimerService()
        XCTAssertEqual(service.state, .idle)
        XCTAssertEqual(service.remainingSeconds, 0)
        XCTAssertFalse(service.isActive)
    }
}
