import SwiftUI

@main
struct StudyForgeApp: App {
    let persistenceController = PersistenceController.shared

    @StateObject private var timerService = TimerService()
    @StateObject private var authService = AuthService()
    @StateObject private var syncService = SessionSyncService()
    @State private var showOnboarding = false

    init() {
        seedDataIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
                .environmentObject(timerService)
                .environmentObject(authService)
                .environmentObject(syncService)
                .onReceive(NotificationCenter.default.publisher(for: .willEnterForeground)) { _ in
                    timerService.appWillEnterForeground()
                    Task { await syncService.syncPendingSessions() }
                }
                .onReceive(NotificationCenter.default.publisher(for: .didEnterBackground)) { _ in
                    timerService.appDidEnterBackground()
                }
                .onAppear {
                    if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
                        showOnboarding = true
                        UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
                    }
                }
                .preferredColorScheme(.dark)
                .sheet(isPresented: $showOnboarding) {
                    WelcomeView()
                }
        }

        #if os(macOS)
        MenuBarExtra {
            MenuBarTimerView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
                .environmentObject(timerService)
        } label: {
            menuBarLabel
        }
        #endif
    }

    #if os(macOS)
    private var menuBarLabel: some View {
        Group {
            if timerService.isActive {
                Label(timerService.formattedTime, systemImage: "timer")
            } else {
                Label("StudyForge", systemImage: "book.fill")
            }
        }
    }
    #endif

    private func seedDataIfNeeded() {
        let context = persistenceController.viewContext
        guard SeedDataService.needsSeeding(context: context) else { return }
        try? SeedDataService.seedDefaults(context: context)
    }
}

// MARK: - Notification Names (cross-platform)

extension Notification.Name {
    #if os(iOS)
    static let willEnterForeground = UIApplication.willEnterForegroundNotification
    static let didEnterBackground = UIApplication.didEnterBackgroundNotification
    #else
    static let willEnterForeground = NSApplication.willBecomeActiveNotification
    static let didEnterBackground = NSApplication.didResignActiveNotification
    #endif
    static let sessionDidComplete = Notification.Name("sf_sessionDidComplete")
}
