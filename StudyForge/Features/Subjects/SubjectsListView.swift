import SwiftUI

struct SubjectsListView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = SubjectsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.subjects.isEmpty {
                    SFEmptyState(
                        icon: "book.closed",
                        title: "No Subjects Yet",
                        subtitle: "Create your first subject to start tracking study sessions.",
                        actionTitle: "Add Subject"
                    ) {
                        viewModel.addNewSubject()
                    }
                } else {
                    subjectList
                }
            }
            .background(Theme.surfacePrimaryFallback(for: colorScheme).ignoresSafeArea())
            .navigationTitle("Subjects")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.addNewSubject()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingEditor) {
                SubjectEditorView(
                    subject: viewModel.editingSubject,
                    viewModel: viewModel
                )
            }
            .onAppear {
                viewModel.loadSubjects()
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

    private var subjectList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.sm) {
                ForEach(viewModel.subjects) { subject in
                    subjectRow(subject)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.editSubject(subject)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                Task { await viewModel.archiveSubject(subject) }
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }
                        }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
        }
    }

    private func subjectRow(_ subject: Subject) -> some View {
        HStack(spacing: Spacing.md) {
            // Icon with color background
            Image(systemName: subject.wrappedIcon)
                .font(.body)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(subject.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))

            // Name and category
            VStack(alignment: .leading, spacing: 3) {
                Text(subject.wrappedName)
                    .font(Typography.bodyBold)
                    .foregroundStyle(Theme.textPrimaryFallback(for: colorScheme))
                    .lineLimit(1)

                Text(subject.wrappedCategory)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textMutedFallback(for: colorScheme))
            }

            Spacer()

            // Weekly target + total hours
            VStack(alignment: .trailing, spacing: 3) {
                Text(DurationFormatter.humanReadableFromMinutes(subject.weeklyTargetMinutes) + "/wk")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textSecondaryFallback(for: colorScheme))

                Text(String(format: "%.1fh total", subject.totalStudiedHours))
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textMutedFallback(for: colorScheme))
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(Spacing.md)
        .background(Theme.surfaceSecondaryFallback(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLarge))
    }
}

#Preview {
    SubjectsListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .preferredColorScheme(.dark)
}
