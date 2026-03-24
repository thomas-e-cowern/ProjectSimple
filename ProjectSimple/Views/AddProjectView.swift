import SwiftUI

struct AddProjectView: View {
    @Environment(ProjectStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var startDate = Date.now
    @State private var endDate = Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now
    @State private var selectedColor = "blue"
    @State private var selectedCategory: ProjectCategory = .other

    private let colorOptions = [
        ("blue", Color.blue),
        ("purple", Color.purple),
        ("orange", Color.orange),
        ("red", Color.red),
        ("green", Color.green),
        ("pink", Color.pink),
    ]

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
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                CancelToolbarItem()

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let project = Project(
                            name: name,
                            descriptionText: description,
                            startDate: startDate,
                            endDate: endDate,
                            colorName: selectedColor,
                            category: selectedCategory
                        )
                        store.addProject(project)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddProjectView()
        .environment(ProjectStore.preview())
}
