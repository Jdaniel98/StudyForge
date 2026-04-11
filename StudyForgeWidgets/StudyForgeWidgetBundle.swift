import SwiftUI
import WidgetKit

@main
struct StudyForgeWidgetBundle: WidgetBundle {
    var body: some Widget {
        DailyProgressWidget()
        WeeklyGoalWidget()
        StudyForgeLiveActivity()
    }
}
