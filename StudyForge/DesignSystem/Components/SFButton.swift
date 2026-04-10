import SwiftUI

enum SFButtonVariant {
    case primary
    case secondary
    case ghost
    case destructive
}

struct SFButton: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let icon: String?
    let variant: SFButtonVariant
    let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        variant: SFButtonVariant = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.variant = variant
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.body)
                }
                Text(title)
                    .font(Typography.bodyBold)
            }
            .frame(maxWidth: variant == .ghost ? nil : .infinity)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusMedium)
                    .stroke(borderColor, lineWidth: variant == .secondary ? 1 : 0)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private var backgroundColor: Color {
        switch variant {
        case .primary:
            Color(hex: "3B82F6")
        case .secondary:
            .clear
        case .ghost:
            .clear
        case .destructive:
            Color(hex: "EF4444")
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary, .destructive:
            .white
        case .secondary:
            Theme.textPrimaryFallback(for: colorScheme)
        case .ghost:
            Theme.textSecondaryFallback(for: colorScheme)
        }
    }

    private var borderColor: Color {
        switch variant {
        case .secondary:
            Theme.borderSubtleFallback(for: colorScheme)
        default:
            .clear
        }
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        SFButton("Start Session", icon: "play.fill", variant: .primary) {}
        SFButton("Pause", icon: "pause.fill", variant: .secondary) {}
        SFButton("Skip", variant: .ghost) {}
        SFButton("Delete", icon: "trash", variant: .destructive) {}
    }
    .padding()
    .preferredColorScheme(.dark)
}
