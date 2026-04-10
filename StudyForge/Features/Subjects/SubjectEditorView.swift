import SwiftUI

struct SubjectEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

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
                nameSection
                categorySection
                colorSection
                iconSection
                targetSection
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
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { populateFields() }
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        Section {
            TextField("Subject name", text: $name)
            TextField("Short name (for timer display)", text: $shortName)
        } header: {
            Text("Name")
        } footer: {
            Text("Short name is displayed on the timer and charts. Defaults to the full name if empty.")
        }
    }

    private var categorySection: some View {
        Section("Category") {
            Picker("Category", selection: $selectedCategory) {
                ForEach(SubjectCategory.allCases) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            #if os(iOS)
            .pickerStyle(.navigationLink)
            #endif
            .onChange(of: selectedCategory) { _, newValue in
                icon = newValue.defaultIcon
                selectedColor = SubjectColor.defaultColor(for: newValue)
            }
        }
    }

    private var colorSection: some View {
        Section("Color") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: Spacing.md) {
                ForEach(SubjectColor.allCases) { color in
                    Circle()
                        .fill(color.color)
                        .frame(width: 38, height: 38)
                        .overlay(
                            Circle()
                                .stroke(.white, lineWidth: selectedColor == color ? 2.5 : 0)
                                .padding(2)
                        )
                        .overlay(
                            Circle()
                                .stroke(color.color.opacity(0.3), lineWidth: selectedColor == color ? 2 : 0)
                        )
                        .scaleEffect(selectedColor == color ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedColor)
                        .onTapGesture { selectedColor = color }
                }
            }
            .padding(.vertical, Spacing.sm)
        }
    }

    private var iconSection: some View {
        Section("Icon") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: Spacing.md) {
                ForEach(commonIcons, id: \.self) { iconName in
                    Image(systemName: iconName)
                        .font(.title3)
                        .foregroundStyle(icon == iconName
                                         ? selectedColor.color
                                         : Theme.textSecondaryFallback(for: colorScheme))
                        .frame(width: 48, height: 48)
                        .background(
                            icon == iconName
                            ? selectedColor.color.opacity(0.15)
                            : Theme.surfaceTertiaryFallback(for: colorScheme)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radiusMedium)
                                .stroke(icon == iconName ? selectedColor.color : .clear, lineWidth: 1.5)
                        )
                        .onTapGesture { icon = iconName }
                }
            }
            .padding(.vertical, Spacing.sm)
        }
    }

    private var targetSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Text("Weekly target")
                    Spacer()
                    Text("\(Int(weeklyTargetHours))h / week")
                        .font(Typography.bodyBold)
                        .foregroundStyle(selectedColor.color)
                }

                Slider(value: $weeklyTargetHours, in: 1...40, step: 1)
                    .tint(selectedColor.color)

                HStack {
                    Text("Light")
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Intensive")
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Goal")
        } footer: {
            Text("Aim for a realistic weekly commitment. You can adjust this anytime.")
        }
    }

    // MARK: - Logic

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
                    id: id, name: trimmedName, shortName: finalShortName,
                    color: selectedColor.rawValue, icon: icon,
                    category: selectedCategory.rawValue, weeklyTargetMinutes: targetMinutes
                )
            } else {
                await viewModel.createSubject(
                    name: trimmedName, shortName: finalShortName,
                    color: selectedColor.rawValue, icon: icon,
                    category: selectedCategory.rawValue, weeklyTargetMinutes: targetMinutes
                )
            }
            dismiss()
        }
    }
}

#Preview {
    SubjectEditorView(subject: nil, viewModel: SubjectsViewModel())
        .preferredColorScheme(.dark)
}
