import SwiftUI

struct HeatmapView: View {
    let data: [Date: Int]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Study Activity")
                .font(Typography.title3Bold)

            SFHeatmapGrid(data: data, days: 180, cellSize: 11, spacing: 2)
        }
    }
}

#Preview {
    let sampleData: [Date: Int] = {
        var data: [Date: Int] = [:]
        let calendar = Calendar.current
        for i in 0..<180 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                data[date.startOfDay] = [0, 0, 1, 1, 2, 2, 3, 4].randomElement() ?? 0
            }
        }
        return data
    }()

    HeatmapView(data: sampleData)
        .padding()
        .preferredColorScheme(.dark)
}
