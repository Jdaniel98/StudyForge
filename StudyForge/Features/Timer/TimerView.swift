import SwiftUI

struct TimerView: View {
    @EnvironmentObject private var timerService: TimerService
    @Environment(\.managedObjectContext) private var viewContext

    @StateObject private var viewModel: TimerViewModel

    init() {
        // TimerService will be injected via EnvironmentObject once the view appears
        _viewModel = StateObject(wrappedValue: TimerViewModel(timerService: TimerService()))
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            timerSection

            Spacer()

            controlsSection
                .padding(.bottom, Spacing.xl)

            todaySummarySection
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "0F172A"))
        .onAppear {
            viewModel.loadData()
        }
        .task {
            // Request notification permission on first appearance
            _ = await NotificationService().requestPermission()
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
        // Re-inject the shared TimerService from environment
        .onReceive(timerService.$state) { _ in
            // Keep viewModel in sync with the shared timer service
        }
    }

    // MARK: - Timer Section

    private var timerSection: some View {
        VStack(spacing: Spacing.xl) {
            // Subject picker
            if !timerService.isActive {
                subjectPicker
            } else if let subject = viewModel.selectedSubject {
                VStack(spacing: Spacing.xs) {
                    Text(subject.wrappedShortName)
                        .font(Typography.title3Bold)
                        .foregroundStyle(.white)

                    SFTag(text: subject.wrappedCategory, color: subject.swiftUIColor)
                }
            }

            // Progress ring + timer
            ZStack {
                SFProgressRing(
                    progress: timerService.progress,
                    accentColor: ringColor,
                    size: 240,
                    lineWidth: 8
                )

                VStack(spacing: Spacing.xs) {
                    Text(timerService.formattedTime)
                        .font(Typography.monoTimer)
                        .foregroundStyle(.white)

                    Text(stateLabel)
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Subject Picker

    private var subjectPicker: some View {
        Menu {
            ForEach(viewModel.subjects) { subject in
                Button {
                    viewModel.selectedSubject = subject
                } label: {
                    Label(subject.wrappedName, systemImage: subject.wrappedIcon)
                }
            }

            if viewModel.subjects.isEmpty {
                Text("No subjects — create one in Subjects tab")
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                if let subject = viewModel.selectedSubject {
                    Circle()
                        .fill(subject.swiftUIColor)
                        .frame(width: 10, height: 10)
                    Text(subject.wrappedShortName)
                        .font(Typography.bodyBold)
                } else {
                    Text("Select Subject")
                        .font(Typography.bodyBold)
                }
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .background(Color.white.opacity(0.1))
            .clipShape(Capsule())
        }
    }

    // MARK: - Controls

    private var controlsSection: some View {
        HStack(spacing: Spacing.xl) {
            switch timerService.state {
            case .idle:
                SFButton("Start", icon: "play.fill", variant: .primary) {
                    viewModel.startTimer()
                }
                .frame(maxWidth: 200)

            case .running:
                SFButton("Pause", icon: "pause.fill", variant: .secondary) {
                    viewModel.pauseTimer()
                }
                .frame(maxWidth: 140)

                SFButton("Cancel", variant: .ghost) {
                    viewModel.cancelTimer()
                }
                .frame(maxWidth: 100)

            case .paused:
                SFButton("Resume", icon: "play.fill", variant: .primary) {
                    viewModel.resumeTimer()
                }
                .frame(maxWidth: 140)

                SFButton("Skip", variant: .ghost) {
                    viewModel.skipTimer()
                }
                .frame(maxWidth: 100)

            case .onBreak:
                SFButton("Skip Break", icon: "forward.fill", variant: .secondary) {
                    viewModel.skipTimer()
                }
                .frame(maxWidth: 200)

            case .completed:
                SFButton("Take Break", icon: "cup.and.saucer.fill", variant: .secondary) {
                    viewModel.startBreak()
                }
                .frame(maxWidth: 160)

                SFButton("Continue", icon: "play.fill", variant: .primary) {
                    viewModel.startTimer()
                }
                .frame(maxWidth: 160)
            }
        }
        .padding(.horizontal, Spacing.xxl)
    }

    // MARK: - Today Summary

    private var todaySummarySection: some View {
        SFCard {
            HStack {
                statItem(
                    label: "Today",
                    value: viewModel.formattedTodayTotal,
                    icon: "clock"
                )

                Spacer()

                Divider()
                    .frame(height: 32)

                Spacer()

                statItem(
                    label: "Sessions",
                    value: "\(viewModel.todaySessionCount)",
                    icon: "checkmark.circle"
                )

                Spacer()

                Divider()
                    .frame(height: 32)

                Spacer()

                statItem(
                    label: "Streak",
                    value: "\(viewModel.currentStreak)d",
                    icon: "flame"
                )
            }
        }
    }

    private func statItem(label: String, value: String, icon: String) -> some View {
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
                .foregroundStyle(.white)
        }
    }

    // MARK: - Helpers

    private var ringColor: Color {
        switch timerService.state {
        case .onBreak: Color(hex: "10B981") // Emerald for breaks
        default: viewModel.subjectColor
        }
    }

    private var stateLabel: String {
        switch timerService.state {
        case .idle: "Ready"
        case .running: "Focus"
        case .paused: "Paused"
        case .onBreak(let isLong): isLong ? "Long Break" : "Short Break"
        case .completed: "Complete!"
        }
    }
}

#Preview {
    TimerView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(TimerService())
}
