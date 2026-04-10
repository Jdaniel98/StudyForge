import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @State private var showingFilters = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.groupedSessions.isEmpty {
                    SFEmptyState(
                        icon: "clock.arrow.circlepath",
                        title: "No Sessions Yet",
                        subtitle: "Complete a study session and it will appear here."
                    )
                } else {
                    sessionList
                }
            }
            .navigationTitle("History")
            .searchable(text: $viewModel.searchText, prompt: "Search by subject or notes")
            .onChange(of: viewModel.searchText) { _, _ in viewModel.applyFilter() }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingFilters.toggle()
                    } label: {
                        Image(systemName: viewModel.hasActiveFilter ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                filterSheet
            }
            .onAppear { viewModel.loadData() }
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

    // MARK: - Session List

    private var sessionList: some View {
        List {
            // Summary bar
            Section {
                HStack {
                    Text("\(viewModel.totalFilteredSessions) sessions")
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(viewModel.formattedFilteredTotal)
                        .font(Typography.captionBold)
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(viewModel.groupedSessions) { dayGroup in
                Section {
                    ForEach(dayGroup.sessions) { session in
                        SessionRow(session: session)
                    }
                } header: {
                    HStack {
                        Text(dayGroup.formattedDate)
                        Spacer()
                        Text(dayGroup.formattedTotal)
                            .font(Typography.caption)
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Filter Sheet

    private var filterSheet: some View {
        NavigationStack {
            Form {
                Section("Subject") {
                    Picker("Subject", selection: $viewModel.selectedSubject) {
                        Text("All Subjects").tag(nil as Subject?)
                        ForEach(viewModel.subjects) { subject in
                            Label(subject.wrappedName, systemImage: subject.wrappedIcon)
                                .tag(subject as Subject?)
                        }
                    }
                }

                Section("Date Range") {
                    DatePicker("From", selection: $viewModel.startDate, displayedComponents: .date)
                    DatePicker("To", selection: $viewModel.endDate, displayedComponents: .date)
                }

                Section {
                    Button("Clear Filters") {
                        viewModel.clearFilter()
                        showingFilters = false
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle("Filters")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        viewModel.applyFilter()
                        showingFilters = false
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingFilters = false }
                }
            }
        }
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: StudySession
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.md) {
                // Subject color
                RoundedRectangle(cornerRadius: 3)
                    .fill(session.subject?.swiftUIColor ?? .gray)
                    .frame(width: 3, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(session.subject?.wrappedShortName ?? "Unknown")
                        .font(Typography.bodyBold)

                    Text(timeRange)
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(session.formattedDuration)
                        .font(Typography.bodyBold)

                    HStack(spacing: Spacing.xs) {
                        Image(systemName: session.completedFully ? "checkmark.circle.fill" : "xmark.circle")
                            .font(.caption2)
                            .foregroundStyle(session.completedFully ? .green : .orange)

                        if session.notes != nil {
                            Image(systemName: "note.text")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if session.notes != nil {
                    withAnimation { isExpanded.toggle() }
                }
            }

            // Expandable notes
            if isExpanded, let notes = session.notes, !notes.isEmpty {
                Text(notes)
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, Spacing.lg)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    private var timeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let start = formatter.string(from: session.wrappedStartedAt)
        let end = formatter.string(from: session.wrappedEndedAt)
        return "\(start) – \(end)"
    }
}

#Preview {
    HistoryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .preferredColorScheme(.dark)
}
