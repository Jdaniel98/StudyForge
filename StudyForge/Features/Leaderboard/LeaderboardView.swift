import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject private var authService: AuthService
    @StateObject private var viewModel = LeaderboardViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if !authService.isAuthenticated {
                    signInPrompt
                } else {
                    leaderboardContent
                }
            }
            .navigationTitle("Leaderboard")
            .task {
                if authService.isAuthenticated {
                    await viewModel.loadInitialData()
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .alert(
                "Error",
                isPresented: Binding(
                    get: { viewModel.error != nil },
                    set: { if !$0 { viewModel.error = nil } }
                ),
                presenting: viewModel.error
            ) { _ in
                Button("OK") { viewModel.error = nil }
            } message: { error in
                Text(error.localizedDescription)
            }
        }
    }

    // MARK: - Main Content

    private var leaderboardContent: some View {
        VStack(spacing: 0) {
            // Tab picker
            Picker("Leaderboard", selection: $viewModel.selectedTab) {
                ForEach(LeaderboardViewModel.Tab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .onChange(of: viewModel.selectedTab) { _, newTab in
                Task {
                    if newTab == .global {
                        await viewModel.loadGlobalLeaderboard()
                    } else {
                        await viewModel.loadInitialData()
                    }
                }
            }

            // Content
            switch viewModel.selectedTab {
            case .groups:
                groupsLeaderboard
            case .global:
                globalLeaderboard
            }
        }
    }

    // MARK: - Groups Leaderboard

    private var groupsLeaderboard: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                if viewModel.groups.isEmpty {
                    SFEmptyState(
                        icon: "person.3",
                        title: "No Groups",
                        subtitle: "Join or create a study group to see group leaderboards."
                    )
                    .padding(.top, Spacing.xxl)
                } else {
                    // Group picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.sm) {
                            ForEach(viewModel.groups) { group in
                                groupChip(group)
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                    }

                    // Leaderboard rows
                    leaderboardRows(viewModel.groupLeaderboard)
                        .padding(.horizontal, Spacing.lg)
                }
            }
        }
    }

    private func groupChip(_ group: StudyGroup) -> some View {
        Button {
            Task { await viewModel.selectGroup(group) }
        } label: {
            Text(group.name)
                .font(Typography.bodyBold)
                .foregroundStyle(viewModel.selectedGroupId == group.id ? .white : Theme.textSecondary)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
                .background(viewModel.selectedGroupId == group.id ? Theme.accentFocus : Theme.surfaceTertiary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Global Leaderboard

    private var globalLeaderboard: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, Spacing.xxl)
                } else if viewModel.globalLeaderboard.isEmpty {
                    SFEmptyState(
                        icon: "globe",
                        title: "No Public Studiers",
                        subtitle: "Make your profile public in Settings to appear on the global leaderboard."
                    )
                    .padding(.top, Spacing.xxl)
                } else {
                    leaderboardRows(viewModel.globalLeaderboard)
                        .padding(.horizontal, Spacing.lg)
                }
            }
        }
    }

    // MARK: - Shared Leaderboard Rows

    private func leaderboardRows(_ entries: [LeaderboardEntry]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                SFLeaderboardRow(
                    rank: index + 1,
                    name: entry.displayName,
                    initials: entry.initials,
                    value: entry.formattedHours,
                    sessionCount: entry.sessionCount,
                    isCurrentUser: entry.isMe ?? false
                )
            }
        }
        .background(Theme.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLarge))
    }

    // MARK: - Sign In Prompt

    private var signInPrompt: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color(hex: "FFD700"))

            Text("Sign in to see leaderboards")
                .font(Typography.title3Bold)
                .foregroundStyle(Theme.textPrimary)

            Text("Compete with friends and see how you stack up against other studiers worldwide.")
                .font(Typography.body)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)

            NavigationLink {
                AuthView()
            } label: {
                Text("Sign In")
                    .font(Typography.bodyBold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.vertical, Spacing.md)
                    .background(Theme.accentFocus)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
            }
        }
        .padding(Spacing.xxl)
    }
}

#Preview {
    LeaderboardView()
        .environmentObject(AuthService())
        .preferredColorScheme(.dark)
}
