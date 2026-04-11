import Foundation
import Supabase

/// Handles all study group and leaderboard operations via Supabase RPC.
/// Groups are remote-only — no Core Data caching.
final class GroupRepository {

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = ISO8601DateFormatter().date(from: dateString) {
                return date
            }
            // Try with fractional seconds
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions.insert(.withFractionalSeconds)
            if let date = formatter.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }
        return decoder
    }

    // MARK: - Groups

    func fetchMyGroups() async throws -> [StudyGroup] {
        let response = try await supabaseClient.rpc("get_my_groups").execute()
        return try decoder.decode([StudyGroup].self, from: response.data)
    }

    func createGroup(name: String) async throws -> CreateGroupResponse {
        let response = try await supabaseClient
            .rpc("create_group", params: ["group_name": name])
            .execute()
        return try decoder.decode(CreateGroupResponse.self, from: response.data)
    }

    func joinGroup(inviteCode: String) async throws -> JoinGroupResponse {
        let response = try await supabaseClient
            .rpc("join_group", params: ["code": inviteCode])
            .execute()
        return try decoder.decode(JoinGroupResponse.self, from: response.data)
    }

    func leaveGroup(groupId: UUID) async throws {
        try await supabaseClient
            .rpc("leave_group", params: ["target_group_id": groupId.uuidString])
            .execute()
    }

    // MARK: - Leaderboards

    func fetchGroupLeaderboard(groupId: UUID) async throws -> [LeaderboardEntry] {
        let response = try await supabaseClient
            .rpc("get_group_leaderboard", params: ["target_group_id": groupId.uuidString])
            .execute()
        return try decoder.decode([LeaderboardEntry].self, from: response.data)
    }

    func fetchGlobalLeaderboard(limit: Int = 50) async throws -> [LeaderboardEntry] {
        let response = try await supabaseClient
            .rpc("get_global_leaderboard", params: ["result_limit": limit])
            .execute()
        return try decoder.decode([LeaderboardEntry].self, from: response.data)
    }
}
