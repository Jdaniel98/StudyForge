import SwiftUI

struct TimerView: View {
    @EnvironmentObject private var timerService: TimerService
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = TimerViewModel()

    var body: some View {
        ZStack {
            // Background
            Theme.surfacePrimaryFallback(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                timerSection
                    .animation(.easeInOut(duration: 0.3), value: timerService.state)

                Spacer()

                controlsSection
                    .padding(.bottom, Spacing.xxl)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: timerService.state)

                todaySummarySection
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.xxl)
            }
        }
        .onAppear {
            viewModel.bind(to: timerService)
            viewModel.loadData()
        }
        .task {
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
    }

    // MARK: - Timer Section

    private var timerSection: some View {
        VStack(spacing: Spacing.xxl) {
            // Subject label or picker
            if !timerService.isActive {
                subjectPicker
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else if let subject = viewModel.selectedSubject {
                VStack(spacing: Spacing.sm) {
                    Text(subject.wrappedShortName)
                        .font(Typography.title2Bold)
                        .foregroundStyle(Theme.textPrimaryFallback(for: colorScheme))

                    SFTag(text: subject.wrappedCategory, color: subject.swiftUIColor)
                }
                .transition(.opacity)
            }

            // Progress ring + countdown
            ZStack {
                SFProgressRing(
                    progress: timerService.progress,
                    accentColor: ringColor,
                    size: 260,
                    lineWidth: 10
                )

                VStack(spacing: Spacing.sm) {
                    Text(viewModel.displayTime)
                        .font(Typography.monoTimer)
                        .foregroundStyle(Theme.textPrimaryFallback(for: colorScheme))
                        .contentTransition(.numericText())

                    Text(stateLabel)
                        .font(Typography.footnote)
                        .textCase(.uppercase)
                        .tracking(1.2)
                        .foregroundStyle(Theme.textMutedFallback(for: colorScheme))
                }
            }

            // Pomodoro dots
            if timerService.pomodorosCompleted > 0 || timerService.isActive {
                pomodoroDots
            }
        }
    }

    // MARK: - Pomodoro Dots

    private var pomodoroDots: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(index < timerService.pomodorosCompleted
                          ? viewModel.subjectColor
                          : Theme.surfaceTertiaryFallback(for: colorScheme))
                    .frame(width: 8, height: 8)
            }
        }
    }

    // MARK: - Subject Picker

    private var subjectPicker: some View {
        Menu {
            ForEach(viewModel.subjects) { subject in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedSubject = subject
                    }
                } label: {
                    Label(subject.wrappedName, systemImage: subject.wrappedIcon)
                }
            }

            if viewModel.subjects.isEmpty {
                Text("No subjects — add one in the Subjects tab")
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
                    Image(systemName: "book.fill")
                        .font(.body)
                    Text("Select Subject")
                        .font(Typography.bodyBold)
                }
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .foregroundStyle(Theme.textPrimaryFallback(for: colorScheme))
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        }
    }

    // MARK: - Controls

    private var controlsSection: some View {
        HStack(spacing: Spacing.lg) {
            switch timerService.state {
            case .idle:
                SFButton("Start", icon: "play.fill", variant: .primary) {
                    viewModel.startTimer()
                }
                .frame(maxWidth: 220)

            case .running:
                SFButton("Pause", icon: "pause.fill", variant: .secondary) {
                    viewModel.pauseTimer()
                }
                .frame(maxWidth: 160)

                SFButton("Cancel", variant: .ghost) {
                    viewModel.cancelTimer()
                }

            case .paused:
                SFButton("Resume", icon: "play.fill", variant: .primary) {
                    viewModel.resumeTimer()
                }
                .frame(maxWidth: 160)

                SFButton("Skip", variant: .ghost) {
                    viewModel.skipTimer()
                }

            case .onBreak:
                SFButton("Skip Break", icon: "forward.fill", variant: .secondary) {
                    viewModel.skipTimer()
                }
                .frame(maxWidth: 220)

            case .completed:
                SFButton("Break", icon: "cup.and.saucer.fill", variant: .secondary) {
                    viewModel.startBreak()
                }
                .frame(maxWidth: 160)

                SFButton("Next", icon: "play.fill", variant: .primary) {
                    viewModel.startTimer()
                }
                .frame(maxWidth: 160)
            }
        }
        .padding(.horizontal, Spacing.xxl)
    }

    // MARK: - Today Summary

    private var todaySummarySection: some View {
        HStack(spacing: 0) {
            statItem(label: "Today", value: viewModel.formattedTodayTotal, icon: "clock")
            Spacer()
            divider
            Spacer()
            statItem(label: "Sessions", value: "\(viewModel.todaySessionCount)", icon: "checkmark.circle")
            Spacer()
            divider
            Spacer()
            statItem(label: "Streak", value: "\(viewModel.currentStreak)d", icon: "flame")
        }
        .sfCardStyle()
    }

    private var divider: some View {
        Rectangle()
            .fill(Theme.borderSubtleFallback(for: colorScheme))
            .frame(width: 1, height: 28)
    }

    private func statItem(label: String, value: String, icon: String) -> some View {
        VStack(spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(label)
                    .font(Typography.caption)
            }
            .foregroundStyle(Theme.textMutedFallback(for: colorScheme))

            Text(value)
                .font(Typography.monoStats)
                .foregroundStyle(Theme.textPrimaryFallback(for: colorScheme))
        }
    }

    // MARK: - Helpers

    private var ringColor: Color {
        switch timerService.state {
        case .onBreak: Color(hex: "10B981")
        default: viewModel.subjectColor
        }
    }

    private var stateLabel: String {
        switch timerService.state {
        case .idle: "Ready"
        case .running: "Focus"
        case .paused: "Paused"
        case .onBreak(let isLong): isLong ? "Long Break" : "Short Break"
        case .completed: "Complete"
        }
    }
}

#Preview {
    TimerView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(TimerService())
}
