import SwiftUI

struct SFHeatmapCell: View {
    let intensity: Int // 0-4
    let size: CGFloat

    init(intensity: Int, size: CGFloat = 14) {
        self.intensity = min(max(intensity, 0), 4)
        self.size = size
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(fillColor)
            .frame(width: size, height: size)
    }

    private var fillColor: Color {
        switch intensity {
        case 0: Color(hex: "1E293B") // empty — dark slate
        case 1: Color(hex: "166534").opacity(0.4)
        case 2: Color(hex: "166534").opacity(0.6)
        case 3: Color(hex: "22C55E").opacity(0.8)
        case 4: Color(hex: "22C55E")
        default: Color(hex: "1E293B")
        }
    }
}

// MARK: - Heatmap Grid

struct SFHeatmapGrid: View {
    let data: [Date: Int] // date → intensity (0-4)
    let days: Int
    let cellSize: CGFloat
    let spacing: CGFloat

    init(data: [Date: Int], days: Int = 180, cellSize: CGFloat = 12, spacing: CGFloat = 3) {
        self.data = data
        self.days = days
        self.cellSize = cellSize
        self.spacing = spacing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Month labels
            monthLabels

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: weekdayRows, spacing: spacing) {
                    ForEach(allDates, id: \.self) { date in
                        SFHeatmapCell(
                            intensity: data[date.startOfDay] ?? 0,
                            size: cellSize
                        )
                        .help(tooltipText(for: date))
                    }
                }
                .padding(.leading, Spacing.xl) // space for weekday labels
            }

            // Legend
            legend
        }
    }

    // MARK: - Grid Layout

    private var weekdayRows: [GridItem] {
        Array(repeating: GridItem(.fixed(cellSize), spacing: spacing), count: 7)
    }

    private var allDates: [Date] {
        let calendar = Calendar.current
        let today = Date().startOfDay
        return (0..<days).reversed().compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: today)
        }
    }

    // MARK: - Month Labels

    private var monthLabels: some View {
        HStack(spacing: 0) {
            Spacer()
                .frame(width: Spacing.xl)

            ForEach(monthPositions, id: \.label) { month in
                Text(month.label)
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var monthPositions: [(label: String, offset: Int)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        var months: [(label: String, offset: Int)] = []
        var lastMonth = -1

        for (index, date) in allDates.enumerated() {
            let month = calendar.component(.month, from: date)
            if month != lastMonth {
                months.append((label: formatter.string(from: date), offset: index))
                lastMonth = month
            }
        }

        return months
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: Spacing.xs) {
            Spacer()
            Text("Less")
                .font(Typography.caption)
                .foregroundStyle(.secondary)
            ForEach(0..<5) { level in
                SFHeatmapCell(intensity: level, size: cellSize)
            }
            Text("More")
                .font(Typography.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func tooltipText(for date: Date) -> String {
        let intensity = data[date.startOfDay] ?? 0
        let dateStr = date.relativeFormatted
        if intensity == 0 {
            return "\(dateStr): No study"
        }
        return "\(dateStr): Level \(intensity)"
    }
}

#Preview {
    let sampleData: [Date: Int] = {
        var data: [Date: Int] = [:]
        let calendar = Calendar.current
        for i in 0..<180 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                data[date.startOfDay] = Int.random(in: 0...4)
            }
        }
        return data
    }()

    SFHeatmapGrid(data: sampleData)
        .padding()
        .preferredColorScheme(.dark)
}
