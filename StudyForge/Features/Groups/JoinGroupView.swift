import SwiftUI

struct JoinGroupView: View {
    @ObservedObject var viewModel: GroupsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(Theme.accentFocus)

                Text("Join a Study Group")
                    .font(Typography.title2Bold)
                    .foregroundStyle(Theme.textPrimary)

                Text("Enter the 8-character invite code shared by a group member.")
                    .font(Typography.body)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)

                TextField("Invite Code", text: $viewModel.joinCode)
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                    .background(Theme.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    #endif

                SFButton("Join Group", icon: "arrow.right", variant: .primary) {
                    Task { await viewModel.joinGroup() }
                }
                .disabled(viewModel.joinCode.count != 8 || viewModel.isJoining)
                .opacity(viewModel.isJoining ? 0.6 : 1)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Theme.surfacePrimary.ignoresSafeArea())
            .navigationTitle("Join Group")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.joinCode = ""
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
