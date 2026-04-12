#if os(iOS)
import UIKit

final class HapticsService {
    static let shared = HapticsService()

    private let preferencesRepository = PreferencesRepository()

    private init() {}

    private var isEnabled: Bool {
        (try? preferencesRepository.fetch().hapticsEnabled) ?? true
    }

    func playWarning() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }

    func playCompletion() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    func playTick() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
}
#endif
