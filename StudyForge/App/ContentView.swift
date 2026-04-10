import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var timerService: TimerService

    var body: some View {
        #if os(iOS)
        TabView {
            TimerView()
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }

            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }

            SubjectsListView()
                .tabItem {
                    Label("Subjects", systemImage: "book.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        #else
        NavigationSplitView {
            List {
                NavigationLink {
                    TimerView()
                } label: {
                    Label("Timer", systemImage: "timer")
                }

                NavigationLink {
                    DashboardView()
                } label: {
                    Label("Dashboard", systemImage: "chart.bar")
                }

                NavigationLink {
                    HistoryView()
                } label: {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }

                NavigationLink {
                    SubjectsListView()
                } label: {
                    Label("Subjects", systemImage: "book.fill")
                }

                Divider()

                NavigationLink {
                    SettingsView()
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }
            .navigationTitle("StudyForge")
            .listStyle(.sidebar)
        } detail: {
            TimerView()
        }
        #endif
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(TimerService())
}
