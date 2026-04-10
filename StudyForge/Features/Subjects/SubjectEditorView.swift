import SwiftUI

struct SubjectEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let subject: Subject?
    let viewModel: SubjectsViewModel

    @State private var name: String = ""
    @State private var shortName: String = ""
    @State private var selectedColor: SubjectColor = .blue
    @State private var icon: String = "book.fill"
    @State private var selectedCategory: SubjectCategory = .custom
    @State private var weeklyTargetHours: Double = 10

    private var isEditing: Bool { subject != nil }

    private let commonIcons = [
        "book.fill", "function", "cpu", "brain",
        "terminal", "chart.line.uptrend.xyaxis",
        "atom", "character.book.closed", "text.book.closed",
        "graduationcap", "pencil.and.ruler", "music.note",
        "paintpalette", "globe", "flask", "stethoscope"
    ]

    var body: some View {
        NavigationStack {
            Form {
                // Name section
                Section("Name") {
                    TextField("Subject name", text: $name)
                        .textFieldStyle(.plain)

                    TextField("Short name (for display)", text: $shortName)
                        .textFieldStyle(.plain)
                }

                // Category
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(SubjectCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .onChange(of: selectedCategory) { _, newValue in
                        icon = newValue.defaultIcon
                        selectedColor = SubjectColor.defaultColor(for: newValue)
                    }
                }

                // Color
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: Spacing.md) {
                        ForEach(SubjectColor.allCases) { color in
                            Circle()
                                .fill(color.color)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(.white, lineWidth: selectedColor == color ? 2 : 0)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, Spacing.sm)
                }

                // Icon
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: Spacing.md) {
                        ForEach(commonIcons, id: \.self) { iconName in
                            Image(systemName: iconName)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(icon == iconName ? selectedColor.color.opacity(0.2) : .clear)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
                                .onTapGesture {
                                    icon = iconName
                                }
                        }
                    }
                    .padding(.vertical, Spacing.sm)
                }

                // Weekly target
                Section("Weekly Target") {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("\(Int(weeklyTargetHours)) hours per week")
                            .font(Typography.bodyBold)

                        Slider(value: $weeklyTargetHours, in: 1...40, step: 1)
                            .tint(selectedColor.color)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Subject" : "New Subject")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create") {
                        saveSubject()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                populateFields()
            }
        }
    }

    private func populateFields() {
        guard let subject else { return }
        name = subject.wrappedName
        shortName = subject.wrappedShortName
        icon = subject.wrappedIcon
        weeklyTargetHours = Double(subject.weeklyTargetMinutes) / 60.0

        if let color = SubjectColor.allCases.first(where: { $0.rawValue == subject.wrappedColor }) {
            selectedColor = color
        }
        if let category = SubjectCategory(rawValue: subject.wrappedCategory) {
            selectedCategory = category
        }
    }

    private func saveSubject() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedShort = shortName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalShortName = trimmedShort.isEmpty ? trimmedName : trimmedShort
        let targetMinutes = Int32(weeklyTargetHours * 60)

        Task {
            if let subject, let id = subject.id {
                await viewModel.updateSubject(
                    id: id,
                    name: trimmedName,
                    shortName: finalShortName,
                    color: selectedColor.rawValue,
                    icon: icon,
                    category: selectedCategory.rawValue,
                    weeklyTargetMinutes: targetMinutes
                )
            } else {
                await viewModel.createSubject(
                    name: trimmedName,
                    shortName: finalShortName,
                    color: selectedColor.rawValue,
                    icon: icon,
                    category: selectedCategory.rawValue,
                    weeklyTargetMinutes: targetMinutes
                )
            }
            dismiss()
        }
    }
}

#Preview {
    SubjectEditorView(subject: nil, viewModel: SubjectsViewModel())
}
