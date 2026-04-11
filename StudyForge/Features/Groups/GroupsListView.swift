import SwiftUI

struct GroupsListView: View {
    @EnvironmentObject private var authService: AuthService
    @StateObject private var viewModel = GroupsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if !authService.isAuthenticated {
                    signInPrompt
                } else if viewModel.isLoading && viewModel.groups.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.groups.isEmpty {
                    emptyState
                } else {
                    groupsList
                }
            }
            .navigationTitle("Study Groups")
            .toolbar {
                if authService.isAuthenticated {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button {
                            viewModel.showJoinSheet = true
                        } label: {
                            Image(systemName: "person.badge.plus")
                        }

                        Button {
                            viewModel.showCreateSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showCreateSheet) {
                CreateGroupView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showJoinSheet) {
                JoinGroupView(viewModel: viewModel)
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
            .task {
                if authService.isAuthenticated {
                    await viewModel.loadGroups()
                }
            }
            .refreshable {
                await viewModel.loadGroups()
            }
        }
    }

    // MARK: - Groups List

    private var groupsList: some View {
        List {
            ForEach(viewModel.groups) { group in
                NavigationLink {
                    GroupDetailView(group: group, viewModel: viewModel)
                } label: {
                    groupRow(group)
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
    }

    private func groupRow(_ group: StudyGroup) -> some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.radiusMedium)
                    .fill(Theme.accentFocus.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "person.3.fill")
                    .font(.body)
                    .foregroundStyle(Theme.accentFocus)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .font(Typography.bodyBold)
                    .foregroundStyle(Theme.textPrimary)

                Text("\(group.memberCount)/\(group.maxMembers) members")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textMuted)
            }

            Spacer()

            if group.isAdmin {
                SFTag(text: "Admin", color: Theme.accentWarning)
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    // MARK: - Empty & Auth States

    private var emptyState: some View {
        SFEmptyState(
            icon: "person.3",
            title: "No Study Groups",
            subtitle: "Create a group and invite friends, or join one with an invite code.",
            actionTitle: "Create Group"
        ) {
            viewModel.showCreateSheet = true
        }
    }

    private var signInPrompt: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Theme.accentFocus)

            Text("Sign in to join study groups")
                .font(Typography.title3Bold)
                .foregroundStyle(Theme.textPrimary)

            Text("Study groups let you track progress with friends and compete on leaderboards.")
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
    GroupsListView()
        .environmentObject(AuthService())
        .preferredColorScheme(.dark)
}
