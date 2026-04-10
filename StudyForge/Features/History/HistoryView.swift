import SwiftUI

struct HistoryView: View {
    @Environment(\.colorScheme) private var colorScheme
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
            .background(Theme.surfacePrimaryFallback(for: colorScheme).ignoresSafeArea())
            .navigationTitle("History")
            .searchable(text: $viewModel.searchText, prompt: "Search subjects or notes")
            .onChange(of: viewModel.searchText) { _, _ in viewModel.applyFilter() }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingFilters.toggle()
                    } label: {
                        Image(systemName: viewModel.hasActiveFilter
                              ? "line.3.horizontal.decrease.circle.fill"
                              : "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                filterSheet
                    .presentationDetents([.medium])
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
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                // Summary
                HStack {
                    Text("\(viewModel.totalFilteredSessions) sessions")
                        .font(Typography.caption)
                    Spacer()
                    Text(viewModel.formattedFilteredTotal)
                        .font(Typography.captionBold)
                }
                .foregroundStyle(Theme.textMutedFallback(for: colorScheme))
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)

                ForEach(viewModel.groupedSessions) { dayGroup in
                    Section {
                        VStack(spacing: 1) {
                            ForEach(dayGroup.sessions) { session in
                                SessionRow(session: session, colorScheme: colorScheme)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLarge))
                        .padding(.horizontal, Spacing.lg)
                        .padding(.bottom, Spacing.md)
                    } header: {
                        HStack {
                            Text(dayGroup.formattedDate)
                                .font(Typography.captionBold)
                            Spacer()
                            Text(dayGroup.formattedTotal)
                                .font(Typography.caption)
                        }
                        .foregroundStyle(Theme.textMutedFallback(for: colorScheme))
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(Theme.surfacePrimaryFallback(for: colorScheme))
                    }
                }
            }
        }
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
                    #if os(iOS)
                    .pickerStyle(.navigationLink)
                    #endif
                }

                Section("Date Range") {
                    DatePicker("From", selection: $viewModel.startDate, displayedComponents: .date)
                    DatePicker("To", selection: $viewModel.endDate, displayedComponents: .date)
                }

                if viewModel.hasActiveFilter {
                    Section {
                        Button("Clear All Filters", role: .destructive) {
                            viewModel.clearFilter()
                            showingFilters = false
                        }
                    }
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
                    .fontWeight(.semibold)
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
    let colorScheme: ColorScheme
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Spacing.md) {
                // Subject icon
                Image(systemName: session.subject?.wrappedIcon ?? "book.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(session.subject?.swiftUIColor ?? .gray)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 2) {
                    Text(session.subject?.wrappedShortName ?? "Unknown")
                        .font(Typography.bodyBold)
                        .foregroundStyle(Theme.textPrimaryFallback(for: colorScheme))

                    Text(timeRange)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.textMutedFallback(for: colorScheme))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(session.formattedDuration)
                        .font(Typography.bodyBold)
                        .foregroundStyle(Theme.textPrimaryFallback(for: colorScheme))

                    Image(systemName: session.completedFully ? "checkmark.circle.fill" : "xmark.circle")
                        .font(.caption)
                        .foregroundStyle(session.completedFully ? .green : .orange)
                }
            }
            .padding(Spacing.md)
            .contentShape(Rectangle())
            .onTapGesture {
                if session.notes != nil {
                    withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
                }
            }

            if isExpanded, let notes = session.notes, !notes.isEmpty {
                Text(notes)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textSecondaryFallback(for: colorScheme))
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.md)
                    .padding(.leading, 28 + Spacing.md) // align with text
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Theme.surfaceSecondaryFallback(for: colorScheme))
    }

    private var timeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: session.wrappedStartedAt)) – \(formatter.string(from: session.wrappedEndedAt))"
    }
}

#Preview {
    HistoryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .preferredColorScheme(.dark)
}
