import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var syncService: SessionSyncService
    @Environment(\.colorScheme) private var colorScheme

    @State private var displayName = ""
    @State private var isEditing = false
    @State private var showDeleteConfirmation = false
    @State private var showSignOutConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                // Profile header
                Section {
                    profileHeader
                }

                // Sync status
                Section("Sync") {
                    HStack {
                        Label("Status", systemImage: syncService.isSyncing ? "arrow.triangle.2.circlepath" : "checkmark.circle.fill")
                            .foregroundStyle(syncService.isSyncing ? .orange : .green)
                        Spacer()
                        Text(syncService.isSyncing ? "Syncing..." : "Up to date")
                            .font(Typography.caption)
                            .foregroundStyle(Theme.textMutedFallback(for: colorScheme))
                    }

                    if syncService.pendingCount > 0 {
                        HStack {
                            Label("Pending", systemImage: "clock")
                            Spacer()
                            Text("\(syncService.pendingCount) sessions")
                                .font(Typography.caption)
                                .foregroundStyle(Theme.textMutedFallback(for: colorScheme))
                        }
                    }

                    Button {
                        Task { await syncService.syncPendingSessions() }
                    } label: {
                        Label("Sync Now", systemImage: "arrow.clockwise")
                    }
                    .disabled(syncService.isSyncing)
                }

                // Account
                Section("Account") {
                    if let email = authService.currentUser?.email {
                        HStack {
                            Label("Email", systemImage: "envelope")
                            Spacer()
                            Text(email)
                                .font(Typography.caption)
                                .foregroundStyle(Theme.textMutedFallback(for: colorScheme))
                        }
                    }

                    Button(role: .destructive) {
                        showSignOutConfirmation = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }

                // Danger zone
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Account", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                } footer: {
                    Text("This permanently deletes your account and all synced data. Local data on this device will not be affected.")
                        .font(Typography.caption)
                }
            }
            .navigationTitle("Profile")
            .onAppear {
                if let meta = authService.currentUser?.userMetadata,
                   case .string(let name) = meta["display_name"] {
                    displayName = name
                }
            }
            .confirmationDialog("Sign Out", isPresented: $showSignOutConfirmation) {
                Button("Sign Out", role: .destructive) {
                    Task { await authService.signOut() }
                }
            } message: {
                Text("Your local data will be preserved. You can sign back in anytime to resume syncing.")
            }
            .confirmationDialog("Delete Account", isPresented: $showDeleteConfirmation) {
                Button("Delete Account", role: .destructive) {
                    Task { await authService.deleteAccount() }
                }
            } message: {
                Text("This action cannot be undone. All your synced data will be permanently deleted.")
            }
            .alert(
                "Error",
                isPresented: Binding(
                    get: { authService.error != nil },
                    set: { if !$0 { authService.error = nil } }
                ),
                presenting: authService.error
            ) { _ in
                Button("OK") { authService.error = nil }
            } message: { error in
                Text(error.localizedDescription)
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        HStack(spacing: Spacing.lg) {
            // Avatar
            Circle()
                .fill(Theme.accentFocus.opacity(0.15))
                .frame(width: 56, height: 56)
                .overlay {
                    Text(initials)
                        .font(Typography.title2Bold)
                        .foregroundStyle(Theme.accentFocus)
                }

            VStack(alignment: .leading, spacing: 4) {
                if isEditing {
                    TextField("Display Name", text: $displayName)
                        .font(Typography.title3Bold)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            isEditing = false
                            Task { await authService.updateDisplayName(displayName) }
                        }
                } else {
                    Text(displayName.isEmpty ? "No name set" : displayName)
                        .font(Typography.title3Bold)
                        .foregroundStyle(Theme.textPrimaryFallback(for: colorScheme))
                }

                Text("Member since \(memberSince)")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textMutedFallback(for: colorScheme))
            }

            Spacer()

            Button {
                if isEditing {
                    isEditing = false
                    Task { await authService.updateDisplayName(displayName) }
                } else {
                    isEditing = true
                }
            } label: {
                Image(systemName: isEditing ? "checkmark" : "pencil")
                    .font(.body)
                    .foregroundStyle(Theme.accentFocus)
            }
            .buttonStyle(.plain)
        }
    }

    private var initials: String {
        let parts = displayName.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(displayName.prefix(2)).uppercased()
    }

    private var memberSince: String {
        guard let date = authService.currentUser?.createdAt else { return "—" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthService())
        .environmentObject(SessionSyncService())
        .preferredColorScheme(.dark)
}
