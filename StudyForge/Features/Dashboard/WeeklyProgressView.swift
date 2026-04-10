import SwiftUI
import Charts

struct WeeklyProgressView: View {
    let subjectProgress: [SubjectProgress]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Weekly Progress")
                .font(Typography.title3Bold)

            if subjectProgress.isEmpty {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "book.closed")
                        .foregroundStyle(.tertiary)
                    Text("Add subjects to track weekly progress")
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, Spacing.md)
            } else {
                ForEach(subjectProgress) { subject in
                    subjectRow(subject)
                }
            }
        }
    }

    private func subjectRow(_ subject: SubjectProgress) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Circle()
                    .fill(Color(hex: subject.color))
                    .frame(width: 8, height: 8)

                Text(subject.subjectName)
                    .font(Typography.bodyBold)

                Spacer()

                Text("\(subject.formattedCurrent) / \(subject.formattedTarget)")
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
            }

            SFProgressBar(
                progress: subject.progress,
                accentColor: Color(hex: subject.color),
                height: 6
            )
        }
    }
}

// MARK: - Subject Breakdown Chart

struct SubjectBreakdownChart: View {
    let subjectProgress: [SubjectProgress]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("This Week by Subject")
                .font(Typography.title3Bold)

            if subjectProgress.isEmpty || totalMinutes == 0 {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "clock")
                        .foregroundStyle(.tertiary)
                    Text("Complete a session to see your breakdown")
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, Spacing.md)
            } else {
                Chart(subjectProgress) { subject in
                    BarMark(
                        x: .value("Minutes", subject.currentMinutes)
                    )
                    .foregroundStyle(Color(hex: subject.color))
                    .annotation(position: .trailing) {
                        if subject.currentMinutes > 0 {
                            Text(subject.formattedCurrent)
                                .font(Typography.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 32)

                // Legend
                FlowLayout(spacing: Spacing.sm) {
                    ForEach(subjectProgress.filter { $0.currentMinutes > 0 }) { subject in
                        SFTag(text: subject.subjectName, color: Color(hex: subject.color))
                    }
                }
            }
        }
    }

    private var totalMinutes: Int32 {
        subjectProgress.reduce(0) { $0 + $1.currentMinutes }
    }
}

// MARK: - FlowLayout (simple horizontal wrapping)

struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}

#Preview {
    let sampleData = [
        SubjectProgress(subjectName: "Strang", color: "3B82F6", currentMinutes: 420, targetMinutes: 600, progress: 0.7),
        SubjectProgress(subjectName: "CLRS", color: "F59E0B", currentMinutes: 300, targetMinutes: 480, progress: 0.625),
        SubjectProgress(subjectName: "Quant", color: "10B981", currentMinutes: 180, targetMinutes: 420, progress: 0.43),
    ]

    ScrollView {
        VStack(spacing: Spacing.xxl) {
            WeeklyProgressView(subjectProgress: sampleData)
            SubjectBreakdownChart(subjectProgress: sampleData)
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
