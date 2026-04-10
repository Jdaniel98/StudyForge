import CoreData

final class PreferencesRepository {
    private let persistenceController: PersistenceController

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    // MARK: - Read

    /// Fetches the current user preferences, creating defaults if none exist.
    func fetch() throws -> UserPreferences {
        let request = UserPreferences.fetchCurrent()
        let existing = try persistenceController.viewContext.fetch(request)

        if let prefs = existing.first {
            return prefs
        }

        // First launch — create defaults
        let prefs = UserPreferences.createDefaults(in: persistenceController.viewContext)
        try persistenceController.viewContext.save()
        return prefs
    }

    // MARK: - Write

    func update(
        focusDurationSeconds: Int32,
        shortBreakSeconds: Int32,
        longBreakSeconds: Int32,
        pomosBeforeLongBreak: Int16,
        soundEnabled: Bool,
        hapticsEnabled: Bool,
        autoStartBreaks: Bool,
        autoStartFocus: Bool,
        iCloudSyncEnabled: Bool
    ) async throws {
        try await persistenceController.performBackgroundTask { context in
            let request = UserPreferences.fetchCurrent()
            let prefs = try context.fetch(request).first ?? UserPreferences.createDefaults(in: context)

            prefs.focusDurationSeconds = focusDurationSeconds
            prefs.shortBreakSeconds = shortBreakSeconds
            prefs.longBreakSeconds = longBreakSeconds
            prefs.pomosBeforeLongBreak = pomosBeforeLongBreak
            prefs.soundEnabled = soundEnabled
            prefs.hapticsEnabled = hapticsEnabled
            prefs.autoStartBreaks = autoStartBreaks
            prefs.autoStartFocus = autoStartFocus
            prefs.iCloudSyncEnabled = iCloudSyncEnabled
        }
    }
}
