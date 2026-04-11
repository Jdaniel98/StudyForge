import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = SettingsViewModel()
    @State private var exportURL: URL?
    @State private var showExportShare = false

    var body: some View {
        NavigationStack {
            Form {
                timerSection
                behaviorSection
                feedbackSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
            .onAppear { viewModel.loadPreferences() }
            .alert(
                "Error",
                isPresented: Binding(
                    get: { viewModel.error != nil },
                    set: { if !$0 { viewModel.error = nil } }
                ),
                presenting: viewModel.error
            ) { _ in
                Button("OK") { viewModel.error = nil }
            } message: { error in
                Text(error.localizedDescription)
            }
        }
    }

    // MARK: - Timer

    private var timerSection: some View {
        Section {
            durationRow(label: "Focus", value: $viewModel.focusDurationMinutes, range: 5...120, step: 5)
            durationRow(label: "Short break", value: $viewModel.shortBreakMinutes, range: 1...30, step: 1)
            durationRow(label: "Long break", value: $viewModel.longBreakMinutes, range: 5...60, step: 5)
            durationRow(label: "Pomodoros before long break", value: $viewModel.pomosBeforeLongBreak, range: 2...8, step: 1, isMins: false)
        } header: {
            Label("Timer", systemImage: "timer")
        }
    }

    // MARK: - Behavior

    private var behaviorSection: some View {
        Section {
            Toggle("Auto-start breaks", isOn: $viewModel.autoStartBreaks)
                .onChange(of: viewModel.autoStartBreaks) { _, _ in viewModel.savePreferences() }

            Toggle("Auto-start focus after break", isOn: $viewModel.autoStartFocus)
                .onChange(of: viewModel.autoStartFocus) { _, _ in viewModel.savePreferences() }
        } header: {
            Label("Behavior", systemImage: "gearshape.2")
        }
    }

    // MARK: - Feedback

    private var feedbackSection: some View {
        Section {
            Toggle("Sounds", isOn: $viewModel.soundEnabled)
                .onChange(of: viewModel.soundEnabled) { _, _ in viewModel.savePreferences() }

            #if os(iOS)
            Toggle("Haptics", isOn: $viewModel.hapticsEnabled)
                .onChange(of: viewModel.hapticsEnabled) { _, _ in viewModel.savePreferences() }
            #endif
        } header: {
            Label("Feedback", systemImage: "bell")
        }
    }

    // MARK: - Data

    private var dataSection: some View {
        Section {
            Toggle("iCloud Sync", isOn: $viewModel.iCloudSyncEnabled)
                .onChange(of: viewModel.iCloudSyncEnabled) { _, _ in viewModel.savePreferences() }

            Button {
                do {
                    let url = try ExportService().exportToFile()
                    exportURL = url
                    showExportShare = true
                } catch {
                    viewModel.error = .persistenceFetchFailed("Failed to export: \(error.localizedDescription)")
                }
            } label: {
                Label("Export Sessions (CSV)", systemImage: "square.and.arrow.up")
            }
            #if os(iOS)
            .sheet(isPresented: $showExportShare) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            #endif
        } header: {
            Label("Data", systemImage: "icloud")
        } footer: {
            Text("Sync personal study data across your Apple devices via iCloud. Export saves all sessions as a CSV file.")
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Build")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Label("About", systemImage: "info.circle")
        }
    }

    // MARK: - Duration Row

    private func durationRow(label: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, isMins: Bool = true) -> some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Text(label)
                Spacer()
                Text(isMins ? "\(Int(value.wrappedValue)) min" : "\(Int(value.wrappedValue))")
                    .font(Typography.bodyBold)
                    .monospacedDigit()
                    .foregroundStyle(.blue)
            }

            Slider(value: value, in: range, step: step) {
                Text(label)
            } onEditingChanged: { editing in
                if !editing { viewModel.savePreferences() }
            }
            .tint(.blue)
        }
    }
}

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .preferredColorScheme(.dark)
}
