import SwiftUI

@MainActor
final class LeaderboardViewModel: ObservableObject {
    enum Tab: String, CaseIterable {
        case groups = "My Groups"
        case global = "Global"
    }

    // MARK: - Published

    @Published var selectedTab: Tab = .groups
    @Published var groups: [StudyGroup] = []
    @Published var selectedGroupId: UUID?
    @Published var groupLeaderboard: [LeaderboardEntry] = []
    @Published var globalLeaderboard: [LeaderboardEntry] = []
    @Published var isLoading = false
    @Published var error: AppError?

    // MARK: - Dependencies

    private let groupRepository: GroupRepository

    init(groupRepository: GroupRepository = GroupRepository()) {
        self.groupRepository = groupRepository
    }

    // MARK: - Load

    func loadInitialData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            groups = try await groupRepository.fetchMyGroups()
            if let first = groups.first {
                selectedGroupId = first.id
                groupLeaderboard = try await groupRepository.fetchGroupLeaderboard(groupId: first.id)
            }
        } catch {
            self.error = .groupError(error.localizedDescription)
        }
    }

    func selectGroup(_ group: StudyGroup) async {
        selectedGroupId = group.id
        do {
            groupLeaderboard = try await groupRepository.fetchGroupLeaderboard(groupId: group.id)
        } catch {
            self.error = .groupError(error.localizedDescription)
        }
    }

    func loadGlobalLeaderboard() async {
        isLoading = true
        defer { isLoading = false }

        do {
            globalLeaderboard = try await groupRepository.fetchGlobalLeaderboard()
        } catch {
            self.error = .groupError(error.localizedDescription)
        }
    }

    func refresh() async {
        switch selectedTab {
        case .groups:
            await loadInitialData()
        case .global:
            await loadGlobalLeaderboard()
        }
    }
}
