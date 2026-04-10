import UserNotifications

final class NotificationService {
    private enum NotificationID {
        static let sessionEnd = "sf_session_end"
        static let sessionWarning = "sf_session_warning"
        static let breakEnd = "sf_break_end"
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    func checkPermission() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Schedule

    func scheduleSessionEnd(in seconds: Int) {
        guard seconds > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Session Complete"
        content.body = "Great work! Your focus session has ended."
        content.sound = .default
        content.categoryIdentifier = "SESSION_COMPLETE"

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(seconds),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: NotificationID.sessionEnd,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func scheduleWarning(in seconds: Int) {
        guard seconds > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "5 Minutes Left"
        content.body = "Keep going — you're almost done!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(seconds),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: NotificationID.sessionWarning,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func scheduleBreakEnd(in seconds: Int) {
        guard seconds > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Break Over"
        content.body = "Ready to get back to studying?"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(seconds),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: NotificationID.breakEnd,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Cancel

    func cancelPending() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [
                NotificationID.sessionEnd,
                NotificationID.sessionWarning,
                NotificationID.breakEnd
            ]
        )
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
