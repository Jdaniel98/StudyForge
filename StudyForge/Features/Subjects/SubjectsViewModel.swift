import SwiftUI
import CoreData

@MainActor
final class SubjectsViewModel: ObservableObject {
    @Published var subjects: [Subject] = []
    @Published var showingEditor = false
    @Published var editingSubject: Subject?
    @Published var error: AppError?

    private let subjectRepository: SubjectRepository

    init(subjectRepository: SubjectRepository = SubjectRepository()) {
        self.subjectRepository = subjectRepository
    }

    // MARK: - Data Loading

    func loadSubjects() {
        do {
            subjects = try subjectRepository.fetchAll()
        } catch {
            self.error = .persistenceFetchFailed(error.localizedDescription)
        }
    }

    // MARK: - CRUD

    func createSubject(
        name: String,
        shortName: String,
        color: String,
        icon: String,
        category: String,
        weeklyTargetMinutes: Int32
    ) async {
        do {
            try await subjectRepository.create(
                name: name,
                shortName: shortName,
                color: color,
                icon: icon,
                category: category,
                weeklyTargetMinutes: weeklyTargetMinutes
            )
            loadSubjects()
        } catch let appError as AppError {
            error = appError
        } catch {
            self.error = .persistenceSaveFailed(error.localizedDescription)
        }
    }

    func updateSubject(
        id: UUID,
        name: String,
        shortName: String,
        color: String,
        icon: String,
        category: String,
        weeklyTargetMinutes: Int32
    ) async {
        do {
            try await subjectRepository.update(
                id,
                name: name,
                shortName: shortName,
                color: color,
                icon: icon,
                category: category,
                weeklyTargetMinutes: weeklyTargetMinutes
            )
            loadSubjects()
        } catch let appError as AppError {
            error = appError
        } catch {
            self.error = .persistenceSaveFailed(error.localizedDescription)
        }
    }

    func archiveSubject(_ subject: Subject) async {
        guard let id = subject.id else { return }
        do {
            try await subjectRepository.archive(id)
            loadSubjects()
        } catch {
            self.error = .persistenceSaveFailed(error.localizedDescription)
        }
    }

    func moveSubjects(from source: IndexSet, to destination: Int) {
        var reordered = subjects
        reordered.move(fromOffsets: source, toOffset: destination)
        subjects = reordered

        let ids = reordered.compactMap(\.id)
        Task {
            try? await subjectRepository.reorder(ids)
        }
    }

    // MARK: - Editor Helpers

    func editSubject(_ subject: Subject) {
        editingSubject = subject
        showingEditor = true
    }

    func addNewSubject() {
        editingSubject = nil
        showingEditor = true
    }
}
