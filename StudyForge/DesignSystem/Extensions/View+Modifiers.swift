import SwiftUI

// MARK: - Card Style

struct SFCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(Spacing.lg)
            .background(Theme.surfaceSecondaryFallback(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusLarge)
                    .stroke(Theme.borderSubtleFallback(for: colorScheme), lineWidth: 1)
            )
    }
}

// MARK: - Section Style

struct SFSectionModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(Spacing.xl)
            .background(Theme.surfaceSecondaryFallback(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLarge))
    }
}

// MARK: - View Extensions

extension View {
    func sfCardStyle() -> some View {
        modifier(SFCardModifier())
    }

    func sfSectionStyle() -> some View {
        modifier(SFSectionModifier())
    }
}
