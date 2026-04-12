import SwiftUI

struct OnboardingFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @State private var currentPage = 0

    // Subject creation
    @State private var subjectName = ""
    @State private var subjectCategory: SubjectCategory = .custom
    @State private var createdSubjects: [String] = []

    // Goal setting
    @State private var weeklyHoursTarget: Double = 10

    private let totalPages = 3

    var body: some View {
        VStack(spacing: 0) {
            // Page indicator
            HStack(spacing: Spacing.sm) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Capsule()
                        .fill(index <= currentPage ? Theme.accentFocus : Theme.surfaceTertiary)
                        .frame(width: index == currentPage ? 24 : 8, height: 4)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
            }
            .padding(.top, Spacing.lg)

            // Content
            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                subjectPage.tag(1)
                goalPage.tag(2)
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
            #endif
            .animation(.easeInOut(duration: 0.3), value: currentPage)
        }
        .background(Theme.surfacePrimary.ignoresSafeArea())
        .interactiveDismissDisabled()
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: Spacing.xxxl) {
            Spacer()

            VStack(spacing: Spacing.lg) {
                Image(systemName: "book.and.wrench.fill")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(Theme.accentFocus)

                Text("Welcome to StudyForge")
                    .font(Typography.largeTitle)
                    .foregroundStyle(Theme.textPrimary)

                Text("Track deep work, build streaks, and hit your weekly goals.")
                    .font(Typography.body)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: Spacing.xl) {
                featureRow(icon: "timer", color: .blue, title: "Pomodoro Timer", subtitle: "Focus sessions with breaks built in")
                featureRow(icon: "flame.fill", color: .orange, title: "Streaks & Heatmap", subtitle: "Visualize your consistency over time")
                featureRow(icon: "chart.bar.fill", color: .purple, title: "Weekly Goals", subtitle: "Set targets per subject and track progress")
            }
            .padding(.horizontal, Spacing.lg)

            Spacer()

            SFButton("Next", icon: "arrow.right", variant: .primary) {
                currentPage = 1
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xxl)
        }
        .padding(.horizontal, Spacing.lg)
    }

    // MARK: - Page 2: Add Subjects

    private var subjectPage: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            VStack(spacing: Spacing.md) {
                Image(systemName: "book.fill")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Theme.accentFocus)

                Text("What are you studying?")
                    .font(Typography.title2Bold)
                    .foregroundStyle(Theme.textPrimary)

                Text("Add at least one subject. You can always add more later.")
                    .font(Typography.body)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Subject input
            VStack(spacing: Spacing.md) {
                TextField("Subject name", text: $subjectName)
                    .font(Typography.body)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                    .background(Theme.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
                    #if os(iOS)
                    .textInputAutocapitalization(.words)
                    #endif

                // Category picker
                Picker("Category", selection: $subjectCategory) {
                    ForEach(SubjectCategory.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.menu)
                .tint(Theme.accentFocus)

                SFButton("Add Subject", icon: "plus", variant: .secondary) {
                    addSubject()
                }
                .disabled(subjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, Spacing.lg)

            // Created subjects list
            if !createdSubjects.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    ForEach(createdSubjects, id: \.self) { name in
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Theme.accentBreak)
                                .font(.body)
                            Text(name)
                                .font(Typography.body)
                                .foregroundStyle(Theme.textPrimary)
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }

            Spacer()

            SFButton("Next", icon: "arrow.right", variant: .primary) {
                currentPage = 2
            }
            .disabled(createdSubjects.isEmpty)
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xxl)
        }
        .padding(.horizontal, Spacing.lg)
    }

    // MARK: - Page 3: Set Goal

    private var goalPage: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            VStack(spacing: Spacing.md) {
                Image(systemName: "target")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Theme.accentFocus)

                Text("Set a weekly goal")
                    .font(Typography.title2Bold)
                    .foregroundStyle(Theme.textPrimary)

                Text("How many hours per week do you want to study?")
                    .font(Typography.body)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Hours display
            Text("\(Int(weeklyHoursTarget))h")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.accentFocus)

            Text("per week")
                .font(Typography.body)
                .foregroundStyle(Theme.textMuted)

            Slider(value: $weeklyHoursTarget, in: 1...40, step: 1)
                .tint(Theme.accentFocus)
                .padding(.horizontal, Spacing.xxl)

            HStack {
                Text("1h")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textMuted)
                Spacer()
                Text("40h")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(.horizontal, Spacing.xxl)

            Spacer()

            SFButton("Get Started", icon: "arrow.right", variant: .primary) {
                applyWeeklyGoal()
                dismiss()
            }
            .padding(.horizontal, Spacing.lg)

            Text("You can change this anytime in Settings.")
                .font(Typography.caption)
                .foregroundStyle(Theme.textMuted)
                .padding(.bottom, Spacing.xxl)
        }
        .padding(.horizontal, Spacing.lg)
    }

    // MARK: - Helpers

    private func featureRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.bodyBold)
                    .foregroundStyle(Theme.textPrimary)
                Text(subtitle)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private func addSubject() {
        let name = subjectName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        let subjectRepo = SubjectRepository()
        let color = SubjectColor.defaultColor(for: subjectCategory)

        Task {
            do {
                try await subjectRepo.create(
                    name: name,
                    shortName: String(name.prefix(12)),
                    color: color.rawValue,
                    icon: subjectCategory.defaultIcon,
                    category: subjectCategory.rawValue,
                    weeklyTargetMinutes: Int32(weeklyHoursTarget * 60) / Int32(max(createdSubjects.count + 1, 1))
                )
                await MainActor.run {
                    createdSubjects.append(name)
                    subjectName = ""
                    subjectCategory = .custom
                }
            } catch {
                // Non-fatal — user can try again
            }
        }
    }

    private func applyWeeklyGoal() {
        let subjectRepo = SubjectRepository()
        guard let subjects = try? subjectRepo.fetchAll(), !subjects.isEmpty else { return }

        let perSubjectMinutes = Int32(weeklyHoursTarget * 60) / Int32(subjects.count)
        Task {
            for subject in subjects {
                guard let id = subject.id else { continue }
                try? await subjectRepo.update(
                    id,
                    name: subject.wrappedName,
                    shortName: subject.wrappedShortName,
                    color: subject.wrappedColor,
                    icon: subject.wrappedIcon,
                    category: subject.wrappedCategory,
                    weeklyTargetMinutes: perSubjectMinutes
                )
            }
        }
    }
}

#Preview {
    OnboardingFlowView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .preferredColorScheme(.dark)
}
