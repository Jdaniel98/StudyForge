import CoreData

@objc(UserPreferences)
public class UserPreferences: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var focusDurationSeconds: Int32
    @NSManaged public var shortBreakSeconds: Int32
    @NSManaged public var longBreakSeconds: Int32
    @NSManaged public var pomosBeforeLongBreak: Int16
    @NSManaged public var soundEnabled: Bool
    @NSManaged public var hapticsEnabled: Bool
    @NSManaged public var autoStartBreaks: Bool
    @NSManaged public var autoStartFocus: Bool
    @NSManaged public var iCloudSyncEnabled: Bool
}

// MARK: - Defaults

extension UserPreferences {
    static let defaultFocusDuration: Int32 = 1500       // 25 minutes
    static let defaultShortBreak: Int32 = 300            // 5 minutes
    static let defaultLongBreak: Int32 = 900             // 15 minutes
    static let defaultPomosBeforeLongBreak: Int16 = 4

    /// Creates a UserPreferences entity with default values
    static func createDefaults(in context: NSManagedObjectContext) -> UserPreferences {
        let prefs = UserPreferences(context: context)
        prefs.id = UUID()
        prefs.focusDurationSeconds = defaultFocusDuration
        prefs.shortBreakSeconds = defaultShortBreak
        prefs.longBreakSeconds = defaultLongBreak
        prefs.pomosBeforeLongBreak = defaultPomosBeforeLongBreak
        prefs.soundEnabled = true
        prefs.hapticsEnabled = true
        prefs.autoStartBreaks = false
        prefs.autoStartFocus = false
        prefs.iCloudSyncEnabled = false
        return prefs
    }

    /// Human-readable focus duration (e.g., "25 min")
    var formattedFocusDuration: String {
        "\(focusDurationSeconds / 60) min"
    }

    var formattedShortBreak: String {
        "\(shortBreakSeconds / 60) min"
    }

    var formattedLongBreak: String {
        "\(longBreakSeconds / 60) min"
    }
}

// MARK: - Fetch Request

extension UserPreferences {
    static func fetchCurrent() -> NSFetchRequest<UserPreferences> {
        let request = NSFetchRequest<UserPreferences>(entityName: "UserPreferences")
        request.fetchLimit = 1
        return request
    }
}
