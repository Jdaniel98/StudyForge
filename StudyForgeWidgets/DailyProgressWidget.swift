import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct DailyProgressProvider: TimelineProvider {
    func placeholder(in context: Context) -> DailyProgressEntry {
        DailyProgressEntry(
            date: Date(),
            todayMinutes: 87,
            sessionCount: 4,
            streak: 12,
            lastSubjectName: "Linear Algebra",
            lastSubjectColor: "3B82F6"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyProgressEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyProgressEntry>) -> Void) {
        let entry = currentEntry()
        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func currentEntry() -> DailyProgressEntry {
        DailyProgressEntry(
            date: Date(),
            todayMinutes: WidgetDataProvider.todayMinutes,
            sessionCount: WidgetDataProvider.todaySessionCount,
            streak: WidgetDataProvider.currentStreak,
            lastSubjectName: WidgetDataProvider.lastSubjectName,
            lastSubjectColor: WidgetDataProvider.lastSubjectColor
        )
    }
}

// MARK: - Entry

struct DailyProgressEntry: TimelineEntry {
    let date: Date
    let todayMinutes: Int
    let sessionCount: Int
    let streak: Int
    let lastSubjectName: String?
    let lastSubjectColor: String?

    var formattedTime: String {
        let hours = todayMinutes / 60
        let mins = todayMinutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
}

// MARK: - Widget Views

struct DailyProgressWidgetEntryView: View {
    var entry: DailyProgressEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    // MARK: - Small Widget

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Text("\(entry.streak)d streak")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Spacer()

            Text(entry.formattedTime)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.7)

            Text("studied today")
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(Color(hex: "3B82F6"))
                Text("\(entry.sessionCount) sessions")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(for: .widget) {
            Color(hex: "0F172A")
        }
    }

    // MARK: - Medium Widget

    private var mediumView: some View {
        HStack(spacing: 16) {
            // Left: today's stats
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text("\(entry.streak)d streak")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(entry.formattedTime)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text("studied today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Right: session info
            VStack(alignment: .trailing, spacing: 8) {
                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color(hex: "3B82F6"))
                        Text("\(entry.sessionCount)")
                            .font(.title2.weight(.bold))
                    }
                    Text("sessions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let name = entry.lastSubjectName {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: entry.lastSubjectColor ?? "3B82F6"))
                            .frame(width: 6, height: 6)
                        Text(name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .containerBackground(for: .widget) {
            Color(hex: "0F172A")
        }
    }
}

// MARK: - Widget

struct DailyProgressWidget: Widget {
    let kind = "DailyProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyProgressProvider()) { entry in
            DailyProgressWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Progress")
        .description("Track your study time and sessions for today.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    DailyProgressWidget()
} timeline: {
    DailyProgressEntry(date: .now, todayMinutes: 87, sessionCount: 4, streak: 12, lastSubjectName: "Linear Algebra", lastSubjectColor: "3B82F6")
}

#Preview(as: .systemMedium) {
    DailyProgressWidget()
} timeline: {
    DailyProgressEntry(date: .now, todayMinutes: 145, sessionCount: 6, streak: 12, lastSubjectName: "Data Structures", lastSubjectColor: "10B981")
}
