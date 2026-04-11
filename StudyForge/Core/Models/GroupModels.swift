import Foundation

// MARK: - Study Group

struct StudyGroup: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let inviteCode: String
    let createdBy: UUID
    let maxMembers: Int
    let createdAt: Date
    let memberCount: Int
    let myRole: String

    var isAdmin: Bool { myRole == "admin" }

    enum CodingKeys: String, CodingKey {
        case id, name
        case inviteCode = "invite_code"
        case createdBy = "created_by"
        case maxMembers = "max_members"
        case createdAt = "created_at"
        case memberCount = "member_count"
        case myRole = "my_role"
    }
}

// MARK: - Leaderboard Entry

struct LeaderboardEntry: Codable, Identifiable, Equatable {
    let userId: UUID
    let displayName: String
    let avatarUrl: String?
    let totalSeconds: Int
    let sessionCount: Int
    let role: String?
    let categories: [CategoryStat]?
    let isMe: Bool?

    var id: UUID { userId }

    var formattedHours: String {
        let hours = Double(totalSeconds) / 3600.0
        if hours < 1 {
            let minutes = totalSeconds / 60
            return "\(minutes)m"
        }
        return String(format: "%.1fh", hours)
    }

    var initials: String {
        let parts = displayName.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(displayName.prefix(2)).uppercased()
    }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case totalSeconds = "total_seconds"
        case sessionCount = "session_count"
        case role, categories
        case isMe = "is_me"
    }
}

// MARK: - Category Stat

struct CategoryStat: Codable, Equatable {
    let category: String
    let totalSeconds: Int

    enum CodingKeys: String, CodingKey {
        case category
        case totalSeconds = "total_seconds"
    }
}

// MARK: - RPC Responses

struct CreateGroupResponse: Codable {
    let id: UUID
    let name: String
    let inviteCode: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name
        case inviteCode = "invite_code"
        case createdAt = "created_at"
    }
}

struct JoinGroupResponse: Codable {
    let groupId: UUID
    let groupName: String

    enum CodingKeys: String, CodingKey {
        case groupId = "group_id"
        case groupName = "group_name"
    }
}
