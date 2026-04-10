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

    let timerService: TimerService
    private let subjectRepository: SubjectRepository
    private let sessionRepository: SessionRepository
    private let statsRepository: StatsRepository
    private let preferencesRepository: PreferencesRepository
    private var cancellables = Set<AnyCancellable>()

    init(
        timerService: TimerService,
        subjectRepository: SubjectRepository = SubjectRepository(),
        sessionRepository: SessionRepository = SessionRepository(),
        statsRepository: StatsRepository = StatsRepository(),
        preferencesRepository: PreferencesRepository = PreferencesRepository()
    ) {
        self.timerService = timerService
        self.subjectRepository = subjectRepository
        self.sessionRepository = sessionRepository
        self.statsRepository = statsRepository
        self.preferencesRepository = preferencesRepository

        observeTimerCompletion()
    }

    // MARK: - Data Loading

    func loadData() {
        do {
            subjects = try subjectRepository.fetchAll()
            todayTotalSeconds = try sessionRepository.fetchTodayTotalSeconds()
            todaySessionCount = try sessionRepository.fetchTodaySessionCount()
            currentStreak = try statsRepository.fetchCurrentStreak()

            // Auto-select first subject if none selected
            if selectedSubject == nil {
                selectedSubject = subjects.first
            }
        } catch {
            self.error = .persistenceFetchFailed(error.localizedDescription)
        }
    }

    // MARK: - Timer Actions

    func startTimer() {
        guard let subject = selectedSubject, let subjectID = subject.id else {
            error = .noSubjectSelected
            return
        }

        let prefs = try? preferencesRepository.fetch()
        let duration = Int(prefs?.focusDurationSeconds ?? UserPreferences.defaultFocusDuration)
        timerService.start(subjectID: subjectID, durationSeconds: duration)
    }

    func pauseTimer() {
        timerService.pause()
    }

    func resumeTimer() {
        timerService.resume()
    }

    func skipTimer() {
        timerService.skip()
    }

    func cancelTimer() {
        timerService.cancel()
    }

    func startBreak() {
        let prefs = try? preferencesRepository.fetch()
        let pomosBeforeLong = Int(prefs?.pomosBeforeLongBreak ?? UserPreferences.defaultPomosBeforeLongBreak)
        let isLong = timerService.pomodorosCompleted > 0 && timerService.pomodorosCompleted % pomosBeforeLong == 0
        timerService.startBreak(isLong: isLong)
    }

    // MARK: - Computed Display Properties

    var formattedTodayTotal: String {
        DurationFormatter.humanReadable(from: todayTotalSeconds)
    }

    var subjectColor: Color {
        selectedSubject?.swiftUIColor ?? Color(hex: "3B82F6")
    }

    // MARK: - Private

    private func observeTimerCompletion() {
        timerService.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                if state == .completed || state == .idle {
                    self?.loadData()
                }
            }
            .store(in: &cancellables)
    }
}
