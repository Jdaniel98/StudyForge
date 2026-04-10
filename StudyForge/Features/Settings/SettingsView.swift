import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            Form {
                // Timer Durations
                Section("Timer") {
                    durationRow(
                        label: "Focus Duration",
                        value: $viewModel.focusDurationMinutes,
                        range: 5...120,
                        step: 5,
                        unit: "min"
                    )

                    durationRow(
                        label: "Short Break",
                        value: $viewModel.shortBreakMinutes,
                        range: 1...30,
                        step: 1,
                        unit: "min"
                    )

                    durationRow(
                        label: "Long Break",
                        value: $viewModel.longBreakMinutes,
                        range: 5...60,
                        step: 5,
                        unit: "min"
                    )

                    durationRow(
                        label: "Pomodoros Before Long Break",
                        value: $viewModel.pomosBeforeLongBreak,
                        range: 2...8,
                        step: 1,
                        unit: ""
                    )
                }

                // Auto-start
                Section("Behavior") {
                    Toggle("Auto-start breaks", isOn: $viewModel.autoStartBreaks)
                        .onChange(of: viewModel.autoStartBreaks) { _, _ in viewModel.savePreferences() }

                    Toggle("Auto-start focus after break", isOn: $viewModel.autoStartFocus)
                        .onChange(of: viewModel.autoStartFocus) { _, _ in viewModel.savePreferences() }
                }

                // Feedback
                Section("Feedback") {
                    Toggle("Sound", isOn: $viewModel.soundEnabled)
                        .onChange(of: viewModel.soundEnabled) { _, _ in viewModel.savePreferences() }

                    #if os(iOS)
                    Toggle("Haptics", isOn: $viewModel.hapticsEnabled)
                        .onChange(of: viewModel.hapticsEnabled) { _, _ in viewModel.savePreferences() }
                    #endif
                }

                // Data
                Section("Data") {
                    Toggle("iCloud Sync", isOn: $viewModel.iCloudSyncEnabled)
                        .onChange(of: viewModel.iCloudSyncEnabled) { _, _ in viewModel.savePreferences() }

                    Text("Sync personal data across your Apple devices")
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                viewModel.loadPreferences()
            }
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

    private func durationRow(
        label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        unit: String
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(label)
                Spacer()
                Text(unit.isEmpty ? "\(Int(value.wrappedValue))" : "\(Int(value.wrappedValue)) \(unit)")
                    .font(Typography.bodyBold)
                    .foregroundStyle(.secondary)
            }

            Slider(value: value, in: range, step: step) {
                Text(label)
            } onEditingChanged: { editing in
                if !editing {
                    viewModel.savePreferences()
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
