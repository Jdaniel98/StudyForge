import SwiftUI

struct SFEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        subtitle: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.secondary)

            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(Typography.title3Bold)

                Text(subtitle)
                    .font(Typography.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                SFButton(actionTitle, variant: .primary, action: action)
                    .frame(maxWidth: 200)
            }
        }
        .padding(Spacing.xxxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}

#Preview {
    SFEmptyState(
        icon: "book.closed",
        title: "No Subjects Yet",
        subtitle: "Create your first subject to start tracking study sessions.",
        actionTitle: "Add Subject"
    ) {}
    .preferredColorScheme(.dark)
}
