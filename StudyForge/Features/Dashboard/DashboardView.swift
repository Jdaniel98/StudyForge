import SwiftUI

struct DashboardView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    statsRow
                    streakRow
                    heatmapSection
                    weeklyProgressSection
                    subjectBreakdownSection
                    weeklyReviewSection
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
            }
            .background(Theme.surfacePrimaryFallback(for: colorScheme).ignoresSafeArea())
            .navigationTitle("Dashboard")
            .onAppear { viewModel.loadAll() }
            .refreshable { viewModel.loadAll() }
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

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: Spacing.md) {
            miniStatCard(
                label: "Today",
                value: viewModel.formattedTodayTotal,
                icon: "clock",
                iconColor: .blue
            )

            miniStatCard(
                label: "Sessions",
                value: "\(viewModel.todaySessionCount)",
                icon: "checkmark.circle.fill",
                iconColor: .green
            )

            miniStatCard(
                label: "This Week",
                value: viewModel.formattedWeeklyTotal,
                icon: "calendar",
                iconColor: .purple
            )
        }
    }

    private func miniStatCard(label: String, value: String, icon: String, iconColor: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(iconColor)
                Text(label)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textMutedFallback(for: colorScheme))
            }

            Text(value)
                .font(Typography.title3Bold)
                .foregroundStyle(Theme.textPrimaryFallback(for: colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sfCardStyle()
    }

    // MARK: - Streak Row

    private var streakRow: some View {
        HStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(viewModel.currentStreak > 0 ? .orange : Theme.textMutedFallback(for: colorScheme))

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.currentStreak) days")
                        .font(Typography.title3Bold)
                        .foregroundStyle(Theme.textPrimaryFallback(for: colorScheme))
                    Text("Current streak")
                        .font(Typography.caption)
                        .foregroundStyle(Theme.textMutedFallback(for: colorScheme))
                }

                Spacer()
            }
            .sfCardStyle()

            HStack(spacing: Spacing.md) {
                Image(systemName: "trophy.fill")
                    .font(.title2)
                    .foregroundStyle(viewModel.longestStreak > 0 ? .yellow : Theme.textMutedFallback(for: colorScheme))

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.longestStreak) days")
                        .font(Typography.title3Bold)
                        .foregroundStyle(Theme.textPrimaryFallback(for: colorScheme))
                    Text("Longest streak")
                        .font(Typography.caption)
                        .foregroundStyle(Theme.textMutedFallback(for: colorScheme))
                }

                Spacer()
            }
            .sfCardStyle()
        }
    }

    // MARK: - Sections

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HeatmapView(data: viewModel.heatmapData)
        }
        .sfCardStyle()
    }

    private var weeklyProgressSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            WeeklyProgressView(subjectProgress: viewModel.subjectWeeklyProgress)
        }
        .sfCardStyle()
    }

    private var subjectBreakdownSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            SubjectBreakdownChart(subjectProgress: viewModel.subjectWeeklyProgress)
        }
        .sfCardStyle()
    }

    // MARK: - Weekly Review

    @ViewBuilder
    private var weeklyReviewSection: some View {
        if let review = viewModel.weeklyReview {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HStack {
                    Text("Last Week")
                        .font(Typography.title3Bold)
                        .foregroundStyle(Theme.textPrimaryFallback(for: colorScheme))

                    Spacer()

                    Text(review.formattedChange)
                        .font(Typography.captionBold)
                        .foregroundStyle(review.isPositiveChange ? .green : .red)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(
                            (review.isPositiveChange ? Color.green : Color.red).opacity(0.12)
                        )
                        .clipShape(Capsule())
                }

                HStack(spacing: Spacing.xxl) {
                    reviewStat(label: "Total", value: review.formattedTotal)
                    reviewStat(label: "Sessions", value: "\(review.sessionCount)")
                    reviewStat(label: "Top Subject", value: review.topSubjectName)
                }
            }
            .sfCardStyle()
        }
    }

    private func reviewStat(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(Typography.caption)
                .foregroundStyle(Theme.textMutedFallback(for: colorScheme))
            Text(value)
                .font(Typography.bodyBold)
                .foregroundStyle(Theme.textPrimaryFallback(for: colorScheme))
        }
    }
}

#Preview {
    DashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .preferredColorScheme(.dark)
}
