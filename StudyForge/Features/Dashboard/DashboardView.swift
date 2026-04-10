import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    todaySummaryCard
                    streakCard
                    heatmapSection
                    weeklyProgressSection
                    subjectBreakdownSection
                    weeklyReviewSection
                }
                .padding(Spacing.lg)
            }
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

    // MARK: - Today Summary

    private var todaySummaryCard: some View {
        SFCard {
            HStack {
                statColumn(
                    label: "Today",
                    value: viewModel.formattedTodayTotal,
                    icon: "clock"
                )

                Spacer()

                Divider().frame(height: 40)

                Spacer()

                statColumn(
                    label: "Sessions",
                    value: "\(viewModel.todaySessionCount)",
                    icon: "checkmark.circle"
                )

                Spacer()

                Divider().frame(height: 40)

                Spacer()

                statColumn(
                    label: "This Week",
                    value: viewModel.formattedWeeklyTotal,
                    icon: "calendar"
                )
            }
        }
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        HStack(spacing: Spacing.lg) {
            SFCard {
                HStack {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundStyle(viewModel.currentStreak > 0 ? .orange : .secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(viewModel.currentStreak) days")
                            .font(Typography.title3Bold)
                        Text("Current streak")
                            .font(Typography.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
            }

            SFCard {
                HStack {
                    Image(systemName: "trophy.fill")
                        .font(.title2)
                        .foregroundStyle(viewModel.longestStreak > 0 ? .yellow : .secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(viewModel.longestStreak) days")
                            .font(Typography.title3Bold)
                        Text("Longest streak")
                            .font(Typography.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
            }
        }
    }

    // MARK: - Heatmap

    private var heatmapSection: some View {
        SFCard {
            HeatmapView(data: viewModel.heatmapData)
        }
    }

    // MARK: - Weekly Progress

    private var weeklyProgressSection: some View {
        SFCard {
            WeeklyProgressView(subjectProgress: viewModel.subjectWeeklyProgress)
        }
    }

    // MARK: - Subject Breakdown

    private var subjectBreakdownSection: some View {
        SFCard {
            SubjectBreakdownChart(subjectProgress: viewModel.subjectWeeklyProgress)
        }
    }

    // MARK: - Weekly Review

    @ViewBuilder
    private var weeklyReviewSection: some View {
        if let review = viewModel.weeklyReview {
            SFCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack {
                        Text("Last Week Review")
                            .font(Typography.title3Bold)

                        Spacer()

                        Text(review.formattedChange)
                            .font(Typography.captionBold)
                            .foregroundStyle(review.isPositiveChange ? .green : .red)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(
                                (review.isPositiveChange ? Color.green : Color.red).opacity(0.15)
                            )
                            .clipShape(Capsule())
                    }

                    HStack(spacing: Spacing.xxl) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Total")
                                .font(Typography.caption)
                                .foregroundStyle(.secondary)
                            Text(review.formattedTotal)
                                .font(Typography.bodyBold)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sessions")
                                .font(Typography.caption)
                                .foregroundStyle(.secondary)
                            Text("\(review.sessionCount)")
                                .font(Typography.bodyBold)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Top Subject")
                                .font(Typography.caption)
                                .foregroundStyle(.secondary)
                            Text("\(review.topSubjectName) (\(review.formattedTopSubject))")
                                .font(Typography.bodyBold)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func statColumn(label: String, value: String, icon: String) -> some View {
        VStack(spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(label)
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(Typography.monoStats)
        }
    }
}

#Preview {
    DashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .preferredColorScheme(.dark)
}
