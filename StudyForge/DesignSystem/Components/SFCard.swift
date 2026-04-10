import SwiftUI

struct SFCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            content()
        }
        .sfCardStyle()
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        SFCard {
            Text("Study Session")
                .font(Typography.title3Bold)
            Text("45 minutes of Linear Algebra")
                .font(Typography.body)
        }

        SFCard {
            HStack {
                Text("Today's Total")
                Spacer()
                Text("3h 20m")
                    .font(Typography.monoStats)
            }
        }
    }
    .padding()
    .preferredColorScheme(.dark)
}
