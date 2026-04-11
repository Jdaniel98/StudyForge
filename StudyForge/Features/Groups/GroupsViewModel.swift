import SwiftUI

@MainActor
final class GroupsViewModel: ObservableObject {
    // MARK: - Published

    @Published var groups: [StudyGroup] = []
    @Published var selectedGroup: StudyGroup?
    @Published var leaderboard: [LeaderboardEntry] = []
    @Published var isLoading = false
    @Published var isCreating = false
    @Published var isJoining = false
    @Published var error: AppError?

    // Create group
    @Published var newGroupName = ""
    @Published var showCreateSheet = false
    @Published var createdInviteCode: String?

    // Join group
    @Published var joinCode = ""
    @Published var showJoinSheet = false

    // MARK: - Dependencies

    private let groupRepository: GroupRepository

    init(groupRepository: GroupRepository = GroupRepository()) {
        self.groupRepository = groupRepository
    }

    // MARK: - Load Groups

    func loadGroups() async {
        isLoading = true
        defer { isLoading = false }

        do {
            groups = try await groupRepository.fetchMyGroups()
        } catch {
            self.error = .groupError(error.localizedDescription)
        }
    }

    // MARK: - Create Group

    func createGroup() async {
        let name = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            error = .validationFailed("Group name cannot be empty")
            return
        }

        isCreating = true
        defer { isCreating = false }

        do {
            let result = try await groupRepository.createGroup(name: name)
            createdInviteCode = result.inviteCode
            newGroupName = ""
            await loadGroups()
        } catch {
            self.error = .groupError(error.localizedDescription)
        }
    }

    // MARK: - Join Group

    func joinGroup() async {
        let code = joinCode.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard code.count == 8 else {
            error = .validationFailed("Invite code must be 8 characters")
            return
        }

        isJoining = true
        defer { isJoining = false }

        do {
            _ = try await groupRepository.joinGroup(inviteCode: code)
            joinCode = ""
            showJoinSheet = false
            await loadGroups()
        } catch {
            self.error = .groupError(error.localizedDescription)
        }
    }

    // MARK: - Leave Group

    func leaveGroup(_ group: StudyGroup) async {
        do {
            try await groupRepository.leaveGroup(groupId: group.id)
            if selectedGroup?.id == group.id {
                selectedGroup = nil
                leaderboard = []
            }
            await loadGroups()
        } catch {
            self.error = .groupError(error.localizedDescription)
        }
    }

    // MARK: - Leaderboard

    func loadLeaderboard(for group: StudyGroup) async {
        selectedGroup = group
        do {
            leaderboard = try await groupRepository.fetchGroupLeaderboard(groupId: group.id)
        } catch {
            self.error = .groupError(error.localizedDescription)
        }
    }
}
