import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct WeeklyGoalProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeeklyGoalEntry {
        WeeklyGoalEntry(
            date: Date(),
            completedMinutes: 420,
            targetMinutes: 600,
            streak: 12
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WeeklyGoalEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeeklyGoalEntry>) -> Void) {
        let entry = currentEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func currentEntry() -> WeeklyGoalEntry {
        WeeklyGoalEntry(
            date: Date(),
            completedMinutes: WidgetDataProvider.weeklyCompletedMinutes,
            targetMinutes: max(WidgetDataProvider.weeklyTargetMinutes, 1),
            streak: WidgetDataProvider.currentStreak
        )
    }
}

// MARK: - Entry

struct WeeklyGoalEntry: TimelineEntry {
    let date: Date
    let completedMinutes: Int
    let targetMinutes: Int
    let streak: Int

    var progress: Double {
        guard targetMinutes > 0 else { return 0 }
        return min(Double(completedMinutes) / Double(targetMinutes), 1.0)
    }

    var formattedCompleted: String {
        let hours = completedMinutes / 60
        let mins = completedMinutes % 60
        if hours > 0 { return "\(hours)h \(mins)m" }
        return "\(mins)m"
    }

    var formattedTarget: String {
        let hours = targetMinutes / 60
        let mins = targetMinutes % 60
        if hours > 0 && mins > 0 { return "\(hours)h \(mins)m" }
        if hours > 0 { return "\(hours)h" }
        return "\(mins)m"
    }
}

// MARK: - Widget View

struct WeeklyGoalWidgetEntryView: View {
    var entry: WeeklyGoalEntry

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "target")
                    .font(.caption)
                    .foregroundStyle(Color(hex: "3B82F6"))
                Text("Weekly Goal")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Spacer()

            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color(hex: "3B82F6").opacity(0.2), lineWidth: 6)

                Circle()
                    .trim(from: 0, to: entry.progress)
                    .stroke(Color(hex: "3B82F6"), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(Int(entry.progress * 100))%")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }
            }
            .frame(width: 56, height: 56)

            Spacer()

            VStack(spacing: 2) {
                Text(entry.formattedCompleted)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary)

                Text("of \(entry.formattedTarget)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(for: .widget) {
            Color(hex: "0F172A")
        }
    }
}

// MARK: - Widget

struct WeeklyGoalWidget: Widget {
    let kind = "WeeklyGoalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeeklyGoalProvider()) { entry in
            WeeklyGoalWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Weekly Goal")
        .description("Track progress toward your weekly study target.")
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    WeeklyGoalWidget()
} timeline: {
    WeeklyGoalEntry(date: .now, completedMinutes: 420, targetMinutes: 600, streak: 12)
}
