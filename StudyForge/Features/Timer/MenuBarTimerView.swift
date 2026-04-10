#if os(macOS)
import SwiftUI

struct MenuBarTimerView: View {
    @EnvironmentObject private var timerService: TimerService

    var body: some View {
        VStack(spacing: Spacing.md) {
            if timerService.isActive {
                activeTimerView
            } else {
                idleView
            }

            Divider()

            Button("Quit StudyForge") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(Spacing.md)
        .frame(width: 240)
    }

    private var activeTimerView: some View {
        VStack(spacing: Spacing.md) {
            // State label
            Text(stateLabel)
                .font(Typography.caption)
                .foregroundStyle(.secondary)

            // Timer display
            Text(timerService.formattedTime)
                .font(Typography.monoTimerCompact)

            // Progress bar
            SFProgressBar(
                progress: timerService.progress,
                accentColor: timerService.state == .onBreak(isLong: false) || timerService.state == .onBreak(isLong: true)
                    ? Color(hex: "10B981")
                    : Color(hex: "3B82F6"),
                height: 4
            )

            // Controls
            HStack(spacing: Spacing.md) {
                switch timerService.state {
                case .running:
                    Button("Pause") { timerService.pause() }
                    Button("Cancel") { timerService.cancel() }

                case .paused:
                    Button("Resume") { timerService.resume() }
                    Button("Skip") { timerService.skip() }

                case .onBreak:
                    Button("Skip Break") { timerService.skip() }

                default:
                    EmptyView()
                }
            }
            .buttonStyle(.borderless)
        }
    }

    private var idleView: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "book.fill")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("StudyForge")
                .font(Typography.bodyBold)

            Text("Open the app to start a session")
                .font(Typography.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var stateLabel: String {
        switch timerService.state {
        case .running: "Focus Session"
        case .paused: "Paused"
        case .onBreak(let isLong): isLong ? "Long Break" : "Short Break"
        default: "StudyForge"
        }
    }
}

#Preview {
    MenuBarTimerView()
        .environmentObject(TimerService())
}
#endif
