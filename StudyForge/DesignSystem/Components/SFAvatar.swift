import SwiftUI

struct SFAvatar: View {
    let initials: String
    let size: CGFloat
    let color: Color

    init(initials: String, size: CGFloat = 40, color: Color = Theme.accentFocus) {
        self.initials = initials
        self.size = size
        self.color = color
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.2))

            Text(initials)
                .font(.system(size: size * 0.35, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Avatar for \(initials)")
    }
}

#Preview {
    HStack(spacing: Spacing.md) {
        SFAvatar(initials: "DM")
        SFAvatar(initials: "JD", size: 32, color: Color(hex: "10B981"))
        SFAvatar(initials: "AK", size: 56, color: Color(hex: "F59E0B"))
    }
    .padding()
    .preferredColorScheme(.dark)
}
