import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var focusDurationMinutes: Double = 25
    @Published var shortBreakMinutes: Double = 5
    @Published var longBreakMinutes: Double = 15
    @Published var pomosBeforeLongBreak: Double = 4
    @Published var soundEnabled: Bool = true
    @Published var hapticsEnabled: Bool = true
    @Published var autoStartBreaks: Bool = false
    @Published var autoStartFocus: Bool = false
    @Published var iCloudSyncEnabled: Bool = false
    @Published var error: AppError?

    private let preferencesRepository: PreferencesRepository

    init(preferencesRepository: PreferencesRepository = PreferencesRepository()) {
        self.preferencesRepository = preferencesRepository
    }

    func loadPreferences() {
        do {
            let prefs = try preferencesRepository.fetch()
            focusDurationMinutes = Double(prefs.focusDurationSeconds) / 60.0
            shortBreakMinutes = Double(prefs.shortBreakSeconds) / 60.0
            longBreakMinutes = Double(prefs.longBreakSeconds) / 60.0
            pomosBeforeLongBreak = Double(prefs.pomosBeforeLongBreak)
            soundEnabled = prefs.soundEnabled
            hapticsEnabled = prefs.hapticsEnabled
            autoStartBreaks = prefs.autoStartBreaks
            autoStartFocus = prefs.autoStartFocus
            iCloudSyncEnabled = prefs.iCloudSyncEnabled
        } catch {
            self.error = .persistenceFetchFailed(error.localizedDescription)
        }
    }

    func savePreferences() {
        Task {
            do {
                try await preferencesRepository.update(
                    focusDurationSeconds: Int32(focusDurationMinutes * 60),
                    shortBreakSeconds: Int32(shortBreakMinutes * 60),
                    longBreakSeconds: Int32(longBreakMinutes * 60),
                    pomosBeforeLongBreak: Int16(pomosBeforeLongBreak),
                    soundEnabled: soundEnabled,
                    hapticsEnabled: hapticsEnabled,
                    autoStartBreaks: autoStartBreaks,
                    autoStartFocus: autoStartFocus,
                    iCloudSyncEnabled: iCloudSyncEnabled
                )
            } catch {
                self.error = .persistenceSaveFailed(error.localizedDescription)
            }
        }
    }
}
