import ActivityKit
import SwiftUI
import WidgetKit

struct StudyForgeLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StudyForgeActivityAttributes.self) { context in
            // Lock Screen / StandBy banner
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view — shown when long-pressed
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: context.attributes.subjectIcon)
                            .font(.caption)
                            .foregroundStyle(Color(hex: context.attributes.subjectColorHex))
                        Text(context.attributes.subjectName)
                            .font(.caption.bold())
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    pomodoroDotsView(count: context.state.pomodorosCompleted)
                }

                DynamicIslandExpandedRegion(.center) {
                    timerCountdown(context: context, font: .title2.monospacedDigit().bold())
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.state.stateLabel.uppercased())
                            .font(.caption2)
                            .tracking(1)
                            .foregroundStyle(.secondary)

                        Spacer()

                        ProgressView(
                            timerInterval: progressInterval(context: context),
                            countsDown: true
                        )
                        .progressViewStyle(.linear)
                        .tint(Color(hex: context.attributes.subjectColorHex))
                        .frame(maxWidth: 120)
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                // Compact leading — subject icon with color
                Image(systemName: context.attributes.subjectIcon)
                    .font(.caption)
                    .foregroundStyle(Color(hex: context.attributes.subjectColorHex))
            } compactTrailing: {
                // Compact trailing — countdown timer
                timerCountdown(context: context, font: .caption.monospacedDigit().bold())
            } minimal: {
                // Minimal — just the timer icon
                Image(systemName: "timer")
                    .font(.caption)
                    .foregroundStyle(Color(hex: context.attributes.subjectColorHex))
            }
        }
    }

    // MARK: - Lock Screen View

    private func lockScreenView(context: ActivityViewContext<StudyForgeActivityAttributes>) -> some View {
        HStack(spacing: 12) {
            // Subject icon
            Image(systemName: context.attributes.subjectIcon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Color(hex: context.attributes.subjectColorHex))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(context.attributes.subjectName)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)

                Text(context.state.stateLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Timer countdown
            timerCountdown(context: context, font: .title2.monospacedDigit().bold())

            // Pomodoro dots
            pomodoroDotsView(count: context.state.pomodorosCompleted)
        }
        .padding(16)
        .activityBackgroundTint(Color.black.opacity(0.7))
    }

    // MARK: - Shared Components

    @ViewBuilder
    private func timerCountdown(
        context: ActivityViewContext<StudyForgeActivityAttributes>,
        font: Font
    ) -> some View {
        if context.state.isPaused {
            Text("--:--")
                .font(font)
                .foregroundStyle(.secondary)
        } else {
            Text(timerInterval: progressInterval(context: context), countsDown: true)
                .font(font)
                .monospacedDigit()
                .foregroundStyle(Color(hex: context.attributes.subjectColorHex))
        }
    }

    private func pomodoroDotsView(count: Int) -> some View {
        HStack(spacing: 3) {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(index < count ? Color.orange : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }

    private func progressInterval(context: ActivityViewContext<StudyForgeActivityAttributes>) -> ClosedRange<Date> {
        let now = Date.now
        let end = context.state.endDate
        if end > now {
            return now...end
        }
        return now...now
    }
}

// MARK: - Color+Hex for Widget Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 59, 130, 246) // fallback blue
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
