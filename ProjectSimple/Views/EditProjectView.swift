import SwiftUI

struct EditProjectView: View {
    @Environment(ProjectStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let project: Project

    @State private var name: String
    @State private var description: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var selectedColor: String
    @State private var selectedCategory: ProjectCategory

    private let colorOptions = [
        ("blue", Color.blue),
        ("purple", Color.purple),
        ("orange", Color.orange),
        ("red", Color.red),
        ("green", Color.green),
        ("pink", Color.pink),
    ]

    init(project: Project) {
        self.project = project
        _name = State(initialValue: project.safeName)
        _description = State(initialValue: project.safeDescription)
        _startDate = State(initialValue: project.safeStartDate)
        _endDate = State(initialValue: project.safeEndDate)
        _selectedColor = State(initialValue: project.safeColorName)
        _selectedCategory = State(initialValue: project.safeCategory)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Project Info") {
                    TextField("Project Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Dates") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                }

                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(ProjectCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                }

                Section("Color") {
                    HStack(spacing: 12) {
                        ForEach(colorOptions, id: \.0) { option in
                            Circle()
                                .fill(option.1)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColor == option.0 ? 3 : 0)
                                        .padding(-3)
                                )
                                .onTapGesture {
                                    selectedColor = option.0
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                CancelToolbarItem()

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.pushUndo()
                        let updated = project
                        updated.name = name
                        updated.descriptionText = description
                        updated.startDate = startDate
                        updated.endDate = endDate
                        updated.colorName = selectedColor
                        updated.category = selectedCategory
                        store.updateProject(updated)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    EditProjectView(project: Project(name: "Sample", descriptionText: "A sample project"))
        .environment(ProjectStore.preview())
}
