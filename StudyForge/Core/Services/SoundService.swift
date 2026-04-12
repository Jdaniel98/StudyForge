import AVFoundation

final class SoundService {
    private let preferencesRepository: PreferencesRepository

    init(preferencesRepository: PreferencesRepository = PreferencesRepository()) {
        self.preferencesRepository = preferencesRepository
    }

    private var isEnabled: Bool {
        (try? preferencesRepository.fetch().soundEnabled) ?? true
    }

    func playSessionComplete() {
        guard isEnabled else { return }
        playSystemSound(id: 1007) // "Tink" — subtle completion chime
    }

    func playBreakStart() {
        guard isEnabled else { return }
        playSystemSound(id: 1003) // Gentle notification
    }

    func playBreakEnd() {
        guard isEnabled else { return }
        playSystemSound(id: 1013) // "Tink" variant
    }

    func playWarning() {
        guard isEnabled else { return }
        playSystemSound(id: 1005) // Subtle alert
    }

    private func playSystemSound(id: SystemSoundID) {
        AudioServicesPlaySystemSound(id)
    }
}
