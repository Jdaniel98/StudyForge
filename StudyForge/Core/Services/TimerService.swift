import Foundation
import Combine

enum TimerState: Equatable {
    case idle
    case running
    case paused
    case onBreak(isLong: Bool)
    case completed
}

final class TimerService: ObservableObject {
    // MARK: - Published State

    @Published private(set) var state: TimerState = .idle
    @Published private(set) var remainingSeconds: Int = 0
    @Published private(set) var totalDurationSeconds: Int = 0
    @Published private(set) var currentSubjectID: UUID?
    @Published private(set) var pomodorosCompleted: Int = 0

    // MARK: - Dependencies

    private let sessionRepository: SessionRepository
    private let preferencesRepository: PreferencesRepository
    private let notificationService: NotificationService
    private let soundService: SoundService

    // MARK: - Internal State

    private var timer: DispatchSourceTimer?
    private let timerQueue = DispatchQueue(label: "com.studyforge.timer", qos: .userInteractive)
    private var sessionStartedAt: Date?
    private var lastPauseDate: Date?
    private var totalPausedSeconds: TimeInterval = 0
    private var targetEndDate: Date?

    // Background state keys
    private enum UserDefaultsKey {
        static let targetEndDate = "sf_timer_targetEndDate"
        static let timerState = "sf_timer_state"
        static let subjectID = "sf_timer_subjectID"
        static let sessionStartedAt = "sf_timer_sessionStartedAt"
        static let pomodorosCompleted = "sf_timer_pomodorosCompleted"
        static let totalDuration = "sf_timer_totalDuration"
        static let isBreak = "sf_timer_isBreak"
    }

    // Anti-gaming threshold: 3 hours in seconds
    private let antiGamingThresholdSeconds: TimeInterval = 10800

    init(
        sessionRepository: SessionRepository = SessionRepository(),
        preferencesRepository: PreferencesRepository = PreferencesRepository(),
        notificationService: NotificationService = NotificationService(),
        soundService: SoundService = SoundService()
    ) {
        self.sessionRepository = sessionRepository
        self.preferencesRepository = preferencesRepository
        self.notificationService = notificationService
        self.soundService = soundService
    }

    // MARK: - Public API

    func start(subjectID: UUID, durationSeconds: Int) {
        guard state == .idle || state == .completed else { return }

        currentSubjectID = subjectID
        totalDurationSeconds = durationSeconds
        remainingSeconds = durationSeconds
        sessionStartedAt = Date()
        totalPausedSeconds = 0
        targetEndDate = Date().addingTimeInterval(TimeInterval(durationSeconds))
        state = .running

        persistBackgroundState()
        notificationService.scheduleSessionEnd(in: durationSeconds)
        notificationService.scheduleWarning(in: durationSeconds - 300) // 5-min warning
        startDispatchTimer()
    }

    func pause() {
        guard state == .running else { return }

        stopDispatchTimer()
        lastPauseDate = Date()
        state = .paused

        notificationService.cancelPending()
        persistBackgroundState()
    }

    func resume() {
        guard state == .paused else { return }

        if let pauseDate = lastPauseDate {
            totalPausedSeconds += Date().timeIntervalSince(pauseDate)
        }
        lastPauseDate = nil

        targetEndDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        state = .running

        notificationService.scheduleSessionEnd(in: remainingSeconds)
        if remainingSeconds > 300 {
            notificationService.scheduleWarning(in: remainingSeconds - 300)
        }
        persistBackgroundState()
        startDispatchTimer()
    }

    func skip() {
        stopDispatchTimer()
        notificationService.cancelPending()

        switch state {
        case .running, .paused:
            // Skip current focus session — save partial progress
            completeSession(completedFully: false)
        case .onBreak:
            // Skip break — go back to idle for next focus
            state = .idle
        default:
            break
        }

        clearBackgroundState()
    }

    func cancel() {
        stopDispatchTimer()
        notificationService.cancelPending()
        clearBackgroundState()

        // Don't save session on cancel
        state = .idle
        remainingSeconds = 0
        currentSubjectID = nil
        sessionStartedAt = nil
        totalPausedSeconds = 0
    }

    func startBreak(isLong: Bool) {
        let prefs = try? preferencesRepository.fetch()
        let duration = isLong
            ? Int(prefs?.longBreakSeconds ?? UserPreferences.defaultLongBreak)
            : Int(prefs?.shortBreakSeconds ?? UserPreferences.defaultShortBreak)

        totalDurationSeconds = duration
        remainingSeconds = duration
        targetEndDate = Date().addingTimeInterval(TimeInterval(duration))
        state = .onBreak(isLong: isLong)

        notificationService.scheduleBreakEnd(in: duration)
        persistBackgroundState()
        startDispatchTimer()
    }

    // MARK: - Background / Foreground

    func appDidEnterBackground() {
        persistBackgroundState()
        stopDispatchTimer()
    }

    func appWillEnterForeground() {
        guard let target = targetEndDate else {
            restoreFromBackground()
            return
        }

        let now = Date()
        if now >= target {
            // Timer expired while backgrounded
            remainingSeconds = 0
            handleTimerCompletion()
        } else {
            remainingSeconds = Int(target.timeIntervalSince(now))
            if state == .running || state == .onBreak(isLong: false) || state == .onBreak(isLong: true) {
                startDispatchTimer()
            }
        }
    }

    // MARK: - Progress

    var progress: Double {
        guard totalDurationSeconds > 0 else { return 0 }
        return 1.0 - (Double(remainingSeconds) / Double(totalDurationSeconds))
    }

    var formattedTime: String {
        DurationFormatter.timerString(from: remainingSeconds)
    }

    var isActive: Bool {
        state == .running || state == .paused
    }

    // MARK: - Private: Timer Engine

    private func startDispatchTimer() {
        stopDispatchTimer()

        let source = DispatchSource.makeTimerSource(flags: .strict, queue: timerQueue)
        source.schedule(deadline: .now() + 1, repeating: 1.0)
        source.setEventHandler { [weak self] in
            self?.tick()
        }
        source.resume()
        timer = source
    }

    private func stopDispatchTimer() {
        timer?.cancel()
        timer = nil
    }

    private func tick() {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.remainingSeconds > 0 else {
                self?.handleTimerCompletion()
                return
            }
            self.remainingSeconds -= 1

            if self.remainingSeconds <= 0 {
                self.handleTimerCompletion()
            }
        }
    }

    private func handleTimerCompletion() {
        stopDispatchTimer()
        notificationService.cancelPending()

        switch state {
        case .running, .paused:
            completeSession(completedFully: true)
        case .onBreak:
            state = .idle
            let prefs = try? preferencesRepository.fetch()
            if prefs?.autoStartFocus == true {
                // Auto-start next focus session would need a subject — stay idle
            }
            soundService.playBreakEnd()
        default:
            break
        }

        clearBackgroundState()
    }

    private func completeSession(completedFully: Bool) {
        guard let subjectID = currentSubjectID, let startedAt = sessionStartedAt else {
            state = .idle
            return
        }

        let endedAt = Date()
        let actualDuration = Int32(endedAt.timeIntervalSince(startedAt) - totalPausedSeconds)
        let plannedDuration = Int32(totalDurationSeconds)

        state = .completed
        pomodorosCompleted += 1
        soundService.playSessionComplete()

        #if os(iOS)
        HapticsService.shared.playCompletion()
        #endif

        Task {
            try? await sessionRepository.saveCompletedSession(
                subjectID: subjectID,
                startedAt: startedAt,
                endedAt: endedAt,
                durationSeconds: actualDuration,
                plannedDurationSeconds: plannedDuration,
                completedFully: completedFully,
                pomodoroCount: Int16(pomodorosCompleted),
                notes: nil
            )
        }
    }

    // MARK: - Background State Persistence

    private func persistBackgroundState() {
        let defaults = UserDefaults.standard
        defaults.set(targetEndDate, forKey: UserDefaultsKey.targetEndDate)
        defaults.set(currentSubjectID?.uuidString, forKey: UserDefaultsKey.subjectID)
        defaults.set(sessionStartedAt, forKey: UserDefaultsKey.sessionStartedAt)
        defaults.set(pomodorosCompleted, forKey: UserDefaultsKey.pomodorosCompleted)
        defaults.set(totalDurationSeconds, forKey: UserDefaultsKey.totalDuration)

        switch state {
        case .running: defaults.set("running", forKey: UserDefaultsKey.timerState)
        case .paused: defaults.set("paused", forKey: UserDefaultsKey.timerState)
        case .onBreak(let isLong): defaults.set(isLong ? "longBreak" : "shortBreak", forKey: UserDefaultsKey.timerState)
        default: defaults.set("idle", forKey: UserDefaultsKey.timerState)
        }
    }

    private func restoreFromBackground() {
        let defaults = UserDefaults.standard
        guard let stateString = defaults.string(forKey: UserDefaultsKey.timerState),
              stateString != "idle" else { return }

        if let subjectString = defaults.string(forKey: UserDefaultsKey.subjectID) {
            currentSubjectID = UUID(uuidString: subjectString)
        }
        sessionStartedAt = defaults.object(forKey: UserDefaultsKey.sessionStartedAt) as? Date
        pomodorosCompleted = defaults.integer(forKey: UserDefaultsKey.pomodorosCompleted)
        totalDurationSeconds = defaults.integer(forKey: UserDefaultsKey.totalDuration)
        targetEndDate = defaults.object(forKey: UserDefaultsKey.targetEndDate) as? Date

        switch stateString {
        case "running":
            state = .running
        case "paused":
            state = .paused
        case "shortBreak":
            state = .onBreak(isLong: false)
        case "longBreak":
            state = .onBreak(isLong: true)
        default:
            state = .idle
        }
    }

    private func clearBackgroundState() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: UserDefaultsKey.targetEndDate)
        defaults.removeObject(forKey: UserDefaultsKey.timerState)
        defaults.removeObject(forKey: UserDefaultsKey.subjectID)
        defaults.removeObject(forKey: UserDefaultsKey.sessionStartedAt)
        defaults.removeObject(forKey: UserDefaultsKey.pomodorosCompleted)
        defaults.removeObject(forKey: UserDefaultsKey.totalDuration)
    }
}
