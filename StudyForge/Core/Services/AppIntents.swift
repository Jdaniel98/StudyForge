import AppIntents
import CoreData

// MARK: - Start Study Session

struct StartStudySessionIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Study Session"
    static var description = IntentDescription("Open StudyForge to start a Pomodoro focus session.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        return .result(dialog: "Opening StudyForge. Select a subject and tap Start.")
    }
}

// MARK: - Check Streak

struct CheckStreakIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Study Streak"
    static var description = IntentDescription("Check your current study streak in StudyForge.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let statsRepo = StatsRepository()
        let streak = (try? statsRepo.fetchCurrentStreak()) ?? 0

        let sessionRepo = SessionRepository()
        let todaySeconds = (try? sessionRepo.fetchTodayTotalSeconds()) ?? 0
        let todayMinutes = todaySeconds / 60

        if streak == 0 && todayMinutes == 0 {
            return .result(dialog: "No study streak yet. Start a session to begin building one!")
        }

        return .result(dialog: "You have a \(streak)-day streak! Today: \(todayMinutes) minutes studied.")
    }
}

// MARK: - Check Today's Progress

struct CheckTodayProgressIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Today's Study Progress"
    static var description = IntentDescription("See how much you've studied today in StudyForge.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let sessionRepo = SessionRepository()
        let totalSeconds = (try? sessionRepo.fetchTodayTotalSeconds()) ?? 0
        let sessionCount = (try? sessionRepo.fetchTodaySessionCount()) ?? 0

        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if sessionCount == 0 {
            return .result(dialog: "No sessions today yet. Time to study!")
        }

        let timeStr = hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
        return .result(dialog: "Today: \(timeStr) across \(sessionCount) session\(sessionCount == 1 ? "" : "s").")
    }
}

// MARK: - App Shortcuts Provider

struct StudyForgeShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartStudySessionIntent(),
            phrases: [
                "Start studying in \(.applicationName)",
                "Start a session in \(.applicationName)",
                "Study with \(.applicationName)"
            ],
            shortTitle: "Start Studying",
            systemImageName: "play.fill"
        )

        AppShortcut(
            intent: CheckStreakIntent(),
            phrases: [
                "Check my streak in \(.applicationName)",
                "How's my study streak in \(.applicationName)"
            ],
            shortTitle: "Check Streak",
            systemImageName: "flame.fill"
        )

        AppShortcut(
            intent: CheckTodayProgressIntent(),
            phrases: [
                "How much did I study today in \(.applicationName)",
                "Check today's progress in \(.applicationName)"
            ],
            shortTitle: "Today's Progress",
            systemImageName: "chart.bar.fill"
        )
    }
}
