import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var timerService: TimerService
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        #if os(iOS)
        TabView {
            TimerView()
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }

            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
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
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(Theme.accentFocus)
        #else
        NavigationSplitView {
            List {
                Section("Study") {
                    NavigationLink {
                        TimerView()
                    } label: {
                        Label("Timer", systemImage: "timer")
                    }

                    NavigationLink {
                        DashboardView()
                    } label: {
                        Label("Dashboard", systemImage: "chart.bar.fill")
                    }

                    NavigationLink {
                        HistoryView()
                    } label: {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
                }

                Section("Manage") {
                    NavigationLink {
                        SubjectsListView()
                    } label: {
                        Label("Subjects", systemImage: "book.fill")
                    }

                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
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
        .preferredColorScheme(.dark)
}
