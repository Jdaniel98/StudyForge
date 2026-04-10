import SwiftUI
import CoreData

@MainActor
final class HistoryViewModel: ObservableObject {
    // MARK: - Published

    @Published var groupedSessions: [DayGroup] = []
    @Published var subjects: [Subject] = []
    @Published var selectedSubject: Subject?
    @Published var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @Published var endDate: Date = Date()
    @Published var searchText: String = ""
    @Published var error: AppError?

    // MARK: - Dependencies

    private let sessionRepository: SessionRepository
    private let subjectRepository: SubjectRepository

    init(
        sessionRepository: SessionRepository = SessionRepository(),
        subjectRepository: SubjectRepository = SubjectRepository()
    ) {
        self.sessionRepository = sessionRepository
        self.subjectRepository = subjectRepository
    }

    // MARK: - Load

    func loadData() {
        loadSubjects()
        loadSessions()
    }

    private func loadSubjects() {
        do {
            subjects = try subjectRepository.fetchAll()
        } catch {
            self.error = .persistenceFetchFailed(error.localizedDescription)
        }
    }

    func loadSessions() {
        do {
            let range = startDate.startOfDay...endDate.endOfDay
            var allSessions: [StudySession] = []

            if let subject = selectedSubject {
                allSessions = try sessionRepository.fetchSessions(for: subject, in: range)
            } else {
                let subjects = try subjectRepository.fetchAll()
                for subject in subjects {
                    let sessions = try sessionRepository.fetchSessions(for: subject, in: range)
                    allSessions.append(contentsOf: sessions)
                }
            }

            // Sort by date descending
            allSessions.sort { ($0.startedAt ?? .distantPast) > ($1.startedAt ?? .distantPast) }

            // Apply search filter
            if !searchText.isEmpty {
                allSessions = allSessions.filter { session in
                    let subjectName = session.subject?.wrappedName.lowercased() ?? ""
                    let notes = session.notes?.lowercased() ?? ""
                    let query = searchText.lowercased()
                    return subjectName.contains(query) || notes.contains(query)
                }
            }

            // Group by day
            let calendar = Calendar.current
            let grouped = Dictionary(grouping: allSessions) { session in
                calendar.startOfDay(for: session.wrappedStartedAt)
            }

            groupedSessions = grouped
                .map { DayGroup(date: $0.key, sessions: $0.value) }
                .sorted { $0.date > $1.date }

        } catch {
            self.error = .persistenceFetchFailed(error.localizedDescription)
        }
    }

    func applyFilter() {
        loadSessions()
    }

    func clearFilter() {
        selectedSubject = nil
        startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        endDate = Date()
        searchText = ""
        loadSessions()
    }

    var hasActiveFilter: Bool {
        selectedSubject != nil || !searchText.isEmpty
    }

    var totalFilteredSessions: Int {
        groupedSessions.reduce(0) { $0 + $1.sessions.count }
    }

    var totalFilteredSeconds: Int32 {
        groupedSessions.reduce(0) { total, group in
            total + group.sessions.reduce(0) { $0 + $1.durationSeconds }
        }
    }

    var formattedFilteredTotal: String {
        DurationFormatter.humanReadable(from: totalFilteredSeconds)
    }
}

// MARK: - Day Group

struct DayGroup: Identifiable {
    let date: Date
    let sessions: [StudySession]

    var id: Date { date }

    var formattedDate: String { date.relativeFormatted }

    var totalSeconds: Int32 {
        sessions.reduce(0) { $0 + $1.durationSeconds }
    }

    var formattedTotal: String {
        DurationFormatter.humanReadable(from: totalSeconds)
    }
}
