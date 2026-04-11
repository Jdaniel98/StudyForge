import SwiftUI

struct SFLeaderboardRow: View {
    let rank: Int
    let name: String
    let initials: String
    let value: String
    let sessionCount: Int
    let isCurrentUser: Bool
    let color: Color

    init(
        rank: Int,
        name: String,
        initials: String,
        value: String,
        sessionCount: Int,
        isCurrentUser: Bool = false,
        color: Color = Theme.accentFocus
    ) {
        self.rank = rank
        self.name = name
        self.initials = initials
        self.value = value
        self.sessionCount = sessionCount
        self.isCurrentUser = isCurrentUser
        self.color = color
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Rank
            Text("\(rank)")
                .font(Typography.bodyBold)
                .foregroundStyle(rankColor)
                .frame(width: 28, alignment: .center)

            // Avatar
            SFAvatar(initials: initials, size: 36, color: color)

            // Name + sessions
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(Typography.bodyBold)
                    .foregroundStyle(Theme.textPrimary)

                Text("\(sessionCount) sessions")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textMuted)
            }

            Spacer()

            // Hours
            Text(value)
                .font(Typography.monoStats)
                .foregroundStyle(Theme.accentFocus)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(isCurrentUser ? Theme.accentFocus.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rank \(rank), \(name), \(value), \(sessionCount) sessions")
    }

    private var rankColor: Color {
        switch rank {
        case 1: Color(hex: "FFD700") // Gold
        case 2: Color(hex: "C0C0C0") // Silver
        case 3: Color(hex: "CD7F32") // Bronze
        default: Theme.textMuted
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        SFLeaderboardRow(rank: 1, name: "Daniel M", initials: "DM", value: "12.5h", sessionCount: 28, isCurrentUser: true)
        SFLeaderboardRow(rank: 2, name: "Jane D", initials: "JD", value: "10.2h", sessionCount: 22)
        SFLeaderboardRow(rank: 3, name: "Alex K", initials: "AK", value: "8.7h", sessionCount: 19, color: Color(hex: "F59E0B"))
        SFLeaderboardRow(rank: 4, name: "Sam P", initials: "SP", value: "5.1h", sessionCount: 11)
    }
    .padding()
    .preferredColorScheme(.dark)
}
