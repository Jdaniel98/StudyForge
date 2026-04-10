import SwiftUI

struct WelcomeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: Spacing.xxxl) {
            Spacer()

            // App icon + title
            VStack(spacing: Spacing.lg) {
                Image(systemName: "book.and.wrench.fill")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(Theme.accentFocus)

                Text("Welcome to StudyForge")
                    .font(Typography.largeTitle)
                    .foregroundStyle(Theme.textPrimaryFallback(for: colorScheme))

                Text("Track deep work, build streaks, and hit your weekly goals.")
                    .font(Typography.body)
                    .foregroundStyle(Theme.textSecondaryFallback(for: colorScheme))
                    .multilineTextAlignment(.center)
            }

            // Feature highlights
            VStack(alignment: .leading, spacing: Spacing.xl) {
                featureRow(
                    icon: "timer",
                    color: .blue,
                    title: "Pomodoro Timer",
                    subtitle: "Focus sessions with breaks built in"
                )
                featureRow(
                    icon: "flame.fill",
                    color: .orange,
                    title: "Streaks & Heatmap",
                    subtitle: "Visualize your consistency over time"
                )
                featureRow(
                    icon: "chart.bar.fill",
                    color: .purple,
                    title: "Weekly Goals",
                    subtitle: "Set targets per subject and track progress"
                )
            }
            .padding(.horizontal, Spacing.lg)

            Spacer()

            // CTA
            VStack(spacing: Spacing.md) {
                SFButton("Get Started", icon: "arrow.right", variant: .primary) {
                    dismiss()
                }

                Text("We've added some sample subjects to get you started.\nYou can edit or remove them anytime.")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textMutedFallback(for: colorScheme))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xxl)
        }
        .padding(.horizontal, Spacing.lg)
        .background(Theme.surfacePrimaryFallback(for: colorScheme).ignoresSafeArea())
        .interactiveDismissDisabled()
    }

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
                    .foregroundStyle(Theme.textPrimaryFallback(for: colorScheme))
                Text(subtitle)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textSecondaryFallback(for: colorScheme))
            }
        }
    }
}

#Preview {
    WelcomeView()
        .preferredColorScheme(.dark)
}
