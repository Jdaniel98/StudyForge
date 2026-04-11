import SwiftUI
import Combine

@MainActor
final class TimerViewModel: ObservableObject {
    // MARK: - Published

    @Published var selectedSubject: Subject?
    @Published var subjects: [Subject] = []
    @Published var todayTotalSeconds: Int32 = 0
    @Published var todaySessionCount: Int = 0
    @Published var currentStreak: Int = 0
    @Published var error: AppError?

    // MARK: - Dependencies

    private(set) var timerService: TimerService?
    private let subjectRepository: SubjectRepository
    private let sessionRepository: SessionRepository
    private let statsRepository: StatsRepository
    private let preferencesRepository: PreferencesRepository
    private var cancellables = Set<AnyCancellable>()

    init(
        subjectRepository: SubjectRepository = SubjectRepository(),
        sessionRepository: SessionRepository = SessionRepository(),
        statsRepository: StatsRepository = StatsRepository(),
        preferencesRepository: PreferencesRepository = PreferencesRepository()
    ) {
        self.subjectRepository = subjectRepository
        self.sessionRepository = sessionRepository
        self.statsRepository = statsRepository
        self.preferencesRepository = preferencesRepository
    }

    /// Bind to the shared TimerService from the environment. Called once on appear.
    func bind(to timerService: TimerService) {
        guard self.timerService == nil else { return }
        self.timerService = timerService

        timerService.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                if state == .completed || state == .idle {
                    self?.loadData()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Loading

    func loadData() {
        do {
            subjects = try subjectRepository.fetchAll()
            todayTotalSeconds = try sessionRepository.fetchTodayTotalSeconds()
            todaySessionCount = try sessionRepository.fetchTodaySessionCount()
            currentStreak = try statsRepository.fetchCurrentStreak()

            if selectedSubject == nil {
                selectedSubject = subjects.first
            }
        } catch {
            self.error = .persistenceFetchFailed(error.localizedDescription)
        }
    }

    // MARK: - Timer Actions

    func startTimer() {
        guard let timerService else { return }
        guard let subject = selectedSubject, let subjectID = subject.id else {
            error = .noSubjectSelected
            return
        }

        let prefs = try? preferencesRepository.fetch()
        let duration = Int(prefs?.focusDurationSeconds ?? UserPreferences.defaultFocusDuration)
        timerService.start(
            subjectID: subjectID,
            durationSeconds: duration,
            subjectName: subject.wrappedShortName,
            subjectColorHex: subject.wrappedColor,
            subjectIcon: subject.wrappedIcon
        )
    }

    func pauseTimer() { timerService?.pause() }
    func resumeTimer() { timerService?.resume() }
    func skipTimer() { timerService?.skip() }
    func cancelTimer() { timerService?.cancel() }

    func startBreak() {
        guard let timerService else { return }
        let prefs = try? preferencesRepository.fetch()
        let pomosBeforeLong = Int(prefs?.pomosBeforeLongBreak ?? UserPreferences.defaultPomosBeforeLongBreak)
        let isLong = timerService.pomodorosCompleted > 0 && timerService.pomodorosCompleted % pomosBeforeLong == 0
        timerService.startBreak(isLong: isLong)
    }

    // MARK: - Display

    var formattedTodayTotal: String {
        DurationFormatter.humanReadable(from: todayTotalSeconds)
    }

    var subjectColor: Color {
        selectedSubject?.swiftUIColor ?? Color(hex: "3B82F6")
    }

    /// Shows planned duration when idle, actual remaining time otherwise
    var displayTime: String {
        guard let timerService else { return defaultDurationFormatted }
        if timerService.state == .idle || timerService.state == .completed {
            return defaultDurationFormatted
        }
        return timerService.formattedTime
    }

    private var defaultDurationFormatted: String {
        let prefs = try? preferencesRepository.fetch()
        let seconds = Int(prefs?.focusDurationSeconds ?? UserPreferences.defaultFocusDuration)
        return DurationFormatter.timerString(from: seconds)
    }
}
