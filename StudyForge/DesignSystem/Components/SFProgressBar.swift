import SwiftUI

struct SFProgressBar: View {
    let progress: Double // 0.0 to 1.0
    let accentColor: Color
    let height: CGFloat
    let showPercentage: Bool

    init(
        progress: Double,
        accentColor: Color = Color(hex: "3B82F6"),
        height: CGFloat = 8,
        showPercentage: Bool = false
    ) {
        self.progress = min(max(progress, 0), 1)
        self.accentColor = accentColor
        self.height = height
        self.showPercentage = showPercentage
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: Spacing.xs) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(accentColor.opacity(0.15))
                        .frame(height: height)

                    // Progress fill
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(accentColor)
                        .frame(width: geometry.size.width * progress, height: height)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: height)

            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    VStack(spacing: Spacing.xl) {
        SFProgressBar(progress: 0.7)
        SFProgressBar(progress: 0.45, accentColor: Color(hex: "10B981"), showPercentage: true)
        SFProgressBar(progress: 1.0, accentColor: Color(hex: "F59E0B"), height: 12)
    }
    .padding()
    .preferredColorScheme(.dark)
}
