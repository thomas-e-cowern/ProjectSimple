import SwiftUI
import TipKit

struct EditTaskView: View {
    @Environment(ProjectStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let task: ProjectTask
    let projectID: UUID

    @State private var title: String
    @State private var details: String
    @State private var dueDate: Date
    @State private var priority: TaskPriority
    @State private var status: TaskStatus
    @State private var recurrenceRule: RecurrenceRule
    @State private var steps: [TaskStep]
    @State private var newStepTitle = ""

    init(task: ProjectTask, projectID: UUID) {
        self.task = task
        self.projectID = projectID
        _title = State(initialValue: task.safeTitle)
        _details = State(initialValue: task.safeDetails)
        _dueDate = State(initialValue: task.safeDueDate)
        _priority = State(initialValue: task.safePriority)
        _status = State(initialValue: task.safeStatus)
        _recurrenceRule = State(initialValue: task.safeRecurrenceRule)
        _steps = State(initialValue: task.safeSteps)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task Info") {
                    TextField("Task Title", text: $title)
                    TextField("Details", text: $details, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Schedule") {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                }

                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(TaskStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                }

                Section("Recurrence") {
                    Picker("Repeat", selection: $recurrenceRule) {
                        ForEach(RecurrenceRule.allCases, id: \.self) { rule in
                            Text(rule.rawValue).tag(rule)
                        }
                    }
                }

                Section("Steps") {
                    TipView(AddStepTip())
                    ForEach($steps) { $step in
                        HStack {
                            Button {
                                step.isCompleted.toggle()
                                HapticManager.stepToggled()
                            } label: {
                                Image(systemName: step.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(step.isCompleted ? .green : .gray)
                            }
                            .buttonStyle(.plain)

                            TextField("Step", text: $step.title)
                                .strikethrough(step.isCompleted)
                        }
                    }
                    .onDelete { offsets in
                        steps.remove(atOffsets: offsets)
                    }
                    .onMove { from, to in
                        steps.move(fromOffsets: from, toOffset: to)
                    }

                    HStack {
                        TextField("Add a step", text: $newStepTitle)
                        Button {
                            steps.append(TaskStep(title: newStepTitle))
                            newStepTitle = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newStepTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                CancelToolbarItem()

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.pushUndo()
                        let wasCompleted = task.safeStatus == .completed
                        let updated = task
                        updated.title = title
                        updated.details = details
                        updated.dueDate = dueDate
                        updated.priority = priority
                        updated.status = status
                        updated.recurrenceRule = recurrenceRule
                        updated.steps = steps
                        if status == .completed && !wasCompleted {
                            updated.completedDate = Date.now
                        } else if status != .completed {
                            updated.completedDate = nil
                        }
                        store.updateTask(updated, in: projectID)

                        if status == .completed && !wasCompleted {
                            HapticManager.taskCompleted()
                            if let project = store.projects.first(where: { $0.safeID == projectID }),
                               project.completionPercentage == 1.0 {
                                HapticManager.milestoneReached()
                            }
                        }

                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    EditTaskView(
        task: ProjectTask(title: "Sample Task", dueDate: .now, priority: .high),
        projectID: UUID()
    )
    .environment(ProjectStore.preview())
}
