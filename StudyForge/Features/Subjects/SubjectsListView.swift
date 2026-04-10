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
            .navigationTitle("Subjects")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.addNewSubject()
                    } label: {
                        Image(systemName: "plus")
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
        List {
            ForEach(viewModel.subjects) { subject in
                subjectRow(subject)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.editSubject(subject)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task { await viewModel.archiveSubject(subject) }
                        } label: {
                            Label("Archive", systemImage: "archivebox")
                        }
                    }
            }
            .onMove { source, destination in
                viewModel.moveSubjects(from: source, to: destination)
            }
        }
        .listStyle(.plain)
    }

    private func subjectRow(_ subject: Subject) -> some View {
        HStack(spacing: Spacing.md) {
            // Color indicator
            RoundedRectangle(cornerRadius: 4)
                .fill(subject.swiftUIColor)
                .frame(width: 4, height: 40)

            // Icon
            Image(systemName: subject.wrappedIcon)
                .font(.title3)
                .foregroundStyle(subject.swiftUIColor)
                .frame(width: 32)

            // Name and category
            VStack(alignment: .leading, spacing: 2) {
                Text(subject.wrappedName)
                    .font(Typography.bodyBold)

                SFTag(text: subject.wrappedCategory, color: subject.swiftUIColor)
            }

            Spacer()

            // Stats
            VStack(alignment: .trailing, spacing: 2) {
                Text(DurationFormatter.humanReadableFromMinutes(subject.weeklyTargetMinutes))
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)

                Text("\(String(format: "%.1f", subject.totalStudiedHours))h total")
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}

#Preview {
    SubjectsListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
