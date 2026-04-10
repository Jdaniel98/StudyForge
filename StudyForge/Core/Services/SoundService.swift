import AVFoundation

final class SoundService {
    private var player: AVAudioPlayer?

    func playSessionComplete() {
        playSystemSound(id: 1007) // "Tink" — subtle completion chime
    }

    func playBreakEnd() {
        playSystemSound(id: 1013) // "Tink" variant
    }

    func playWarning() {
        playSystemSound(id: 1005) // Subtle alert
    }

    private func playSystemSound(id: SystemSoundID) {
        AudioServicesPlaySystemSound(id)
    }
}
