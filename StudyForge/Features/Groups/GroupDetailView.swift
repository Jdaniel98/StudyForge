import SwiftUI

struct GroupDetailView: View {
    let group: StudyGroup
    @ObservedObject var viewModel: GroupsViewModel
    @State private var showLeaveConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Group info card
                groupInfoCard

                // Invite code card
                inviteCodeCard

                // Weekly leaderboard
                leaderboardSection

                // Leave group
                if !group.isAdmin {
                    leaveButton
                }
            }
            .padding(Spacing.lg)
        }
        .navigationTitle(group.name)
        .task {
            await viewModel.loadLeaderboard(for: group)
        }
        .refreshable {
            await viewModel.loadLeaderboard(for: group)
        }
        .confirmationDialog(
            "Leave \(group.name)?",
            isPresented: $showLeaveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Leave Group", role: .destructive) {
                Task { await viewModel.leaveGroup(group) }
            }
        } message: {
            Text("You'll lose access to this group's leaderboard and activity.")
        }
    }

    // MARK: - Group Info

    private var groupInfoCard: some View {
        HStack(spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Members")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textMuted)
                Text("\(group.memberCount)/\(group.maxMembers)")
                    .font(Typography.title2Bold)
                    .foregroundStyle(Theme.textPrimary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: Spacing.xs) {
                Text("Your Role")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textMuted)
                SFTag(
                    text: group.isAdmin ? "Admin" : "Member",
                    color: group.isAdmin ? Theme.accentWarning : Theme.accentFocus
                )
            }
        }
        .sfCardStyle()
    }

    // MARK: - Invite Code

    private var inviteCodeCard: some View {
        VStack(spacing: Spacing.md) {
            Text("Invite Code")
                .font(Typography.caption)
                .foregroundStyle(Theme.textMuted)

            HStack(spacing: Spacing.md) {
                Text(group.inviteCode.uppercased())
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.accentFocus)
                    .tracking(4)

                Button {
                    #if os(iOS)
                    UIPasteboard.general.string = group.inviteCode
                    #elseif os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(group.inviteCode, forType: .string)
                    #endif
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.body)
                        .foregroundStyle(Theme.accentFocus)
                }
                .buttonStyle(.plain)
            }

            Text("Share this code with friends to invite them")
                .font(Typography.caption)
                .foregroundStyle(Theme.textMuted)
        }
        .sfCardStyle()
    }

    // MARK: - Leaderboard

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("This Week")
                    .font(Typography.title3Bold)
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                Image(systemName: "trophy.fill")
                    .foregroundStyle(Color(hex: "FFD700"))
            }

            if viewModel.leaderboard.isEmpty {
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "chart.bar")
                        .font(.title)
                        .foregroundStyle(Theme.textMuted)
                    Text("No activity this week")
                        .font(Typography.body)
                        .foregroundStyle(Theme.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xxl)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.leaderboard.enumerated()), id: \.element.id) { index, entry in
                        SFLeaderboardRow(
                            rank: index + 1,
                            name: entry.displayName,
                            initials: entry.initials,
                            value: entry.formattedHours,
                            sessionCount: entry.sessionCount
                        )
                    }
                }
            }
        }
        .sfCardStyle()
    }

    // MARK: - Leave

    private var leaveButton: some View {
        Button {
            showLeaveConfirmation = true
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Leave Group")
            }
            .font(Typography.bodyBold)
            .foregroundStyle(Theme.accentDestructive)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(Theme.accentDestructive.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
        }
        .buttonStyle(.plain)
    }
}
