#if os(iOS)
import ActivityKit
import Foundation

struct StudyForgeActivityAttributes: ActivityAttributes {
    // Static data — set once when the activity starts
    let subjectName: String
    let subjectColorHex: String
    let subjectIcon: String
    let totalDurationSeconds: Int

    // Dynamic data — updated as the timer ticks
    struct ContentState: Codable, Hashable {
        let endDate: Date
        let stateLabel: String // "Focus", "Short Break", "Long Break", "Paused"
        let isPaused: Bool
        let pomodorosCompleted: Int
    }
}
#endif
