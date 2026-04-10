import SwiftUI

struct SFProgressRing: View {
    let progress: Double // 0.0 to 1.0
    let lineWidth: CGFloat
    let accentColor: Color
    let size: CGFloat

    init(
        progress: Double,
        accentColor: Color = Color(hex: "3B82F6"),
        size: CGFloat = 240,
        lineWidth: CGFloat = 8
    ) {
        self.progress = min(max(progress, 0), 1)
        self.accentColor = accentColor
        self.size = size
        self.lineWidth = lineWidth
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(
                    accentColor.opacity(0.15),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    accentColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: Spacing.xxl) {
        SFProgressRing(progress: 0.65)

        SFProgressRing(
            progress: 0.3,
            accentColor: Color(hex: "10B981"),
            size: 120,
            lineWidth: 6
        )
    }
    .padding()
    .preferredColorScheme(.dark)
}
