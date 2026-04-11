import Foundation
import CoreData

/// Provides study data for WidgetKit widgets.
/// Reads from Core Data via a shared App Group container.
struct WidgetDataProvider {
    private static let appGroupID = "group.com.estudiosoftware.StudyForge"
    private static let suiteName = "group.com.estudiosoftware.StudyForge"

    // MARK: - UserDefaults Shared Data (written by main app, read by widgets)

    static let shared = UserDefaults(suiteName: suiteName) ?? .standard

    /// Keys for shared widget data
    enum Key {
        static let todayMinutes = "widget_today_minutes"
        static let todaySessionCount = "widget_today_session_count"
        static let currentStreak = "widget_current_streak"
        static let weeklyTargetMinutes = "widget_weekly_target_minutes"
        static let weeklyCompletedMinutes = "widget_weekly_completed_minutes"
        static let lastSubjectName = "widget_last_subject_name"
        static let lastSubjectColor = "widget_last_subject_color"
        static let lastUpdated = "widget_last_updated"
    }

    // MARK: - Write (called from main app)

    static func updateWidgetData(
        todayMinutes: Int,
        todaySessionCount: Int,
        currentStreak: Int,
        weeklyTargetMinutes: Int,
        weeklyCompletedMinutes: Int,
        lastSubjectName: String?,
        lastSubjectColor: String?
    ) {
        let defaults = shared
        defaults.set(todayMinutes, forKey: Key.todayMinutes)
        defaults.set(todaySessionCount, forKey: Key.todaySessionCount)
        defaults.set(currentStreak, forKey: Key.currentStreak)
        defaults.set(weeklyTargetMinutes, forKey: Key.weeklyTargetMinutes)
        defaults.set(weeklyCompletedMinutes, forKey: Key.weeklyCompletedMinutes)
        defaults.set(lastSubjectName, forKey: Key.lastSubjectName)
        defaults.set(lastSubjectColor, forKey: Key.lastSubjectColor)
        defaults.set(Date(), forKey: Key.lastUpdated)
    }

    // MARK: - Read (called from widget extension)

    static var todayMinutes: Int { shared.integer(forKey: Key.todayMinutes) }
    static var todaySessionCount: Int { shared.integer(forKey: Key.todaySessionCount) }
    static var currentStreak: Int { shared.integer(forKey: Key.currentStreak) }
    static var weeklyTargetMinutes: Int { shared.integer(forKey: Key.weeklyTargetMinutes) }
    static var weeklyCompletedMinutes: Int { shared.integer(forKey: Key.weeklyCompletedMinutes) }
    static var lastSubjectName: String? { shared.string(forKey: Key.lastSubjectName) }
    static var lastSubjectColor: String? { shared.string(forKey: Key.lastSubjectColor) }
    static var lastUpdated: Date? { shared.object(forKey: Key.lastUpdated) as? Date }
}
