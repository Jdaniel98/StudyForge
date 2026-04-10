import SwiftUI
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    // MARK: - Published

    @Published var todayTotalMinutes: Int32 = 0
    @Published var todaySessionCount: Int = 0
    @Published var weeklyTotalSeconds: Int32 = 0
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var heatmapData: [Date: Int] = [:]
    @Published var subjectWeeklyProgress: [SubjectProgress] = []
    @Published var weeklyReview: WeeklyReview?
    @Published var error: AppError?

    // MARK: - Dependencies

    private let sessionRepository: SessionRepository
    private let statsRepository: StatsRepository
    private let subjectRepository: SubjectRepository
    private let goalRepository: GoalRepository

    init(
        sessionRepository: SessionRepository = SessionRepository(),
        statsRepository: StatsRepository = StatsRepository(),
        subjectRepository: SubjectRepository = SubjectRepository(),
        goalRepository: GoalRepository = GoalRepository()
    ) {
        self.sessionRepository = sessionRepository
        self.statsRepository = statsRepository
        self.subjectRepository = subjectRepository
        self.goalRepository = goalRepository
    }

    // MARK: - Load

    func loadAll() {
        loadTodayStats()
        loadWeeklyStats()
        loadStreaks()
        loadHeatmap()
        loadSubjectProgress()
        loadWeeklyReview()
    }

    private func loadTodayStats() {
        do {
            todayTotalMinutes = try statsRepository.fetchTodayTotalMinutes()
            todaySessionCount = try sessionRepository.fetchTodaySessionCount()
        } catch {
            self.error = .persistenceFetchFailed(error.localizedDescription)
        }
    }

    private func loadWeeklyStats() {
        do {
            weeklyTotalSeconds = try statsRepository.fetchWeeklyTotalAll()
        } catch {
            self.error = .persistenceFetchFailed(error.localizedDescription)
        }
    }

    private func loadStreaks() {
        do {
            currentStreak = try statsRepository.fetchCurrentStreak()
            longestStreak = try statsRepository.fetchLongestStreak()
        } catch {
            self.error = .persistenceFetchFailed(error.localizedDescription)
        }
    }

    private func loadHeatmap() {
        do {
            let streaks = try statsRepository.fetchDailyStreaks(last: 180)
            var data: [Date: Int] = [:]
            for streak in streaks {
                data[streak.wrappedDate] = streak.intensityLevel
            }
            heatmapData = data
        } catch {
            self.error = .persistenceFetchFailed(error.localizedDescription)
        }
    }

    private func loadSubjectProgress() {
        do {
            let subjects = try subjectRepository.fetchAll()
            subjectWeeklyProgress = try subjects.map { subject in
                let weeklySeconds = try statsRepository.fetchWeeklyTotal(for: subject)
                let weeklyMinutes = weeklySeconds / 60
                let targetMinutes = subject.weeklyTargetMinutes
                let progress = targetMinutes > 0 ? Double(weeklyMinutes) / Double(targetMinutes) : 0

                return SubjectProgress(
                    subjectName: subject.wrappedShortName,
                    color: subject.wrappedColor,
                    currentMinutes: weeklyMinutes,
                    targetMinutes: targetMinutes,
                    progress: progress
                )
            }
        } catch {
            self.error = .persistenceFetchFailed(error.localizedDescription)
        }
    }

    private func loadWeeklyReview() {
        do {
            let calendar = Calendar.current
            let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: Date())?.startOfWeek ?? Date()
            let lastWeekEnd = calendar.date(byAdding: .day, value: 6, to: lastWeekStart)?.endOfDay ?? Date()
            let twoWeeksAgoStart = calendar.date(byAdding: .weekOfYear, value: -1, to: lastWeekStart)?.startOfWeek ?? Date()

            // Last week's sessions
            let lastWeekSessions = try fetchAllSessions(from: lastWeekStart, to: lastWeekEnd)
            let lastWeekTotal = lastWeekSessions.reduce(0) { $0 + $1.durationSeconds }

            // Two weeks ago sessions for comparison
            let twoWeeksAgoEnd = calendar.date(byAdding: .day, value: 6, to: twoWeeksAgoStart)?.endOfDay ?? Date()
            let priorWeekSessions = try fetchAllSessions(from: twoWeeksAgoStart, to: twoWeeksAgoEnd)
            let priorWeekTotal = priorWeekSessions.reduce(0) { $0 + $1.durationSeconds }

            guard lastWeekTotal > 0 else {
                weeklyReview = nil
                return
            }

            // Top subject
            var subjectTotals: [String: Int32] = [:]
            for session in lastWeekSessions {
                let name = session.subject?.wrappedShortName ?? "Unknown"
                subjectTotals[name, default: 0] += session.durationSeconds
            }
            let topSubject = subjectTotals.max(by: { $0.value < $1.value })

            // Change from prior week
            let changePercent: Double
            if priorWeekTotal > 0 {
                changePercent = (Double(lastWeekTotal) - Double(priorWeekTotal)) / Double(priorWeekTotal) * 100
            } else {
                changePercent = 100
            }

            weeklyReview = WeeklyReview(
                weekStartDate: lastWeekStart,
                totalSeconds: lastWeekTotal,
                sessionCount: lastWeekSessions.count,
                topSubjectName: topSubject?.key ?? "—",
                topSubjectSeconds: topSubject?.value ?? 0,
                changeFromPriorWeek: changePercent
            )
        } catch {
            self.error = .persistenceFetchFailed(error.localizedDescription)
        }
    }

    private func fetchAllSessions(from start: Date, to end: Date) throws -> [StudySession] {
        let subjects = try subjectRepository.fetchAll()
        var allSessions: [StudySession] = []
        for subject in subjects {
            let sessions = try sessionRepository.fetchSessions(for: subject, in: start...end)
            allSessions.append(contentsOf: sessions)
        }
        return allSessions
    }

    // MARK: - Computed

    var formattedTodayTotal: String {
        DurationFormatter.humanReadable(from: todayTotalMinutes * 60)
    }

    var formattedWeeklyTotal: String {
        DurationFormatter.humanReadable(from: weeklyTotalSeconds)
    }
}

// MARK: - Supporting Types

struct SubjectProgress: Identifiable {
    let id = UUID()
    let subjectName: String
    let color: String
    let currentMinutes: Int32
    let targetMinutes: Int32
    let progress: Double

    var formattedCurrent: String { DurationFormatter.humanReadableFromMinutes(currentMinutes) }
    var formattedTarget: String { DurationFormatter.humanReadableFromMinutes(targetMinutes) }
}

struct WeeklyReview: Identifiable {
    let id = UUID()
    let weekStartDate: Date
    let totalSeconds: Int32
    let sessionCount: Int
    let topSubjectName: String
    let topSubjectSeconds: Int32
    let changeFromPriorWeek: Double

    var formattedTotal: String { DurationFormatter.humanReadable(from: totalSeconds) }
    var formattedTopSubject: String { DurationFormatter.humanReadable(from: topSubjectSeconds) }
    var isPositiveChange: Bool { changeFromPriorWeek >= 0 }
    var formattedChange: String {
        let sign = isPositiveChange ? "+" : ""
        return "\(sign)\(Int(changeFromPriorWeek))%"
    }
}
