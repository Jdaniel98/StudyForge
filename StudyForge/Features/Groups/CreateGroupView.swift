import SwiftUI

struct CreateGroupView: View {
    @ObservedObject var viewModel: GroupsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                if let code = viewModel.createdInviteCode {
                    // Success state
                    successView(code: code)
                } else {
                    // Create form
                    createForm
                }
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Theme.surfacePrimary.ignoresSafeArea())
            .navigationTitle("Create Group")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.createdInviteCode = nil
                        viewModel.newGroupName = ""
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Create Form

    private var createForm: some View {
        VStack(spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Group Name")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textMuted)

                TextField("e.g. CS Study Squad", text: $viewModel.newGroupName)
                    .font(Typography.body)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                    .background(Theme.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
            }

            Text("Groups can have up to 20 members. You'll get an invite code to share.")
                .font(Typography.caption)
                .foregroundStyle(Theme.textMuted)

            SFButton("Create Group", icon: "plus", variant: .primary) {
                Task { await viewModel.createGroup() }
            }
            .disabled(viewModel.newGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isCreating)
            .opacity(viewModel.isCreating ? 0.6 : 1)
        }
    }

    // MARK: - Success

    private func successView(code: String) -> some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.accentBreak)

            Text("Group Created!")
                .font(Typography.title2Bold)
                .foregroundStyle(Theme.textPrimary)

            VStack(spacing: Spacing.sm) {
                Text("Your invite code:")
                    .font(Typography.body)
                    .foregroundStyle(Theme.textSecondary)

                Text(code.uppercased())
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.accentFocus)
                    .tracking(4)
            }

            HStack(spacing: Spacing.md) {
                SFButton("Copy Code", icon: "doc.on.doc", variant: .secondary) {
                    #if os(iOS)
                    UIPasteboard.general.string = code
                    #elseif os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(code, forType: .string)
                    #endif
                }

                SFButton("Done", variant: .primary) {
                    viewModel.createdInviteCode = nil
                    viewModel.newGroupName = ""
                    dismiss()
                }
            }
        }
    }
}
