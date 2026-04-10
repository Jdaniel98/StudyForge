import SwiftUI

struct SFTag: View {
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(text)
                .font(Typography.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}

#Preview {
    HStack(spacing: Spacing.sm) {
        SFTag(text: "Mathematics", color: .blue)
        SFTag(text: "CS Theory", color: .orange)
        SFTag(text: "Finance", color: Color(hex: "10B981"))
    }
    .padding()
    .preferredColorScheme(.dark)
}
