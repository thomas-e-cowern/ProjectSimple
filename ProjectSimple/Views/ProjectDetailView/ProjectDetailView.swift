import SwiftUI
import TipKit

struct ProjectDetailView: View {
    @Environment(ProjectStore.self) private var store
    let project: Project
    @State private var showAddTask = false
    @State private var showEditProject = false
    @State private var editingTaskID: UUID?
    @State private var taskToDelete: ProjectTask?

    private var currentProject: Project {
        // Read refreshToken to force re-evaluation when CloudKit data arrives.
        _ = store.refreshToken
        return store.projects.first(where: { $0.safeID == project.safeID }) ?? project
    }

    var body: some View {
        List {
            projectInfoSection
            progressSection
            tasksSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle(currentProject.safeName)
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                Button {
                    store.undo()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                }
                .disabled(!store.canUndo)
                .accessibilityLabel("Undo")

                Button {
                    store.redo()
                } label: {
                    Image(systemName: "arrow.uturn.forward")
                }
                .disabled(!store.canRedo)
                .accessibilityLabel("Redo")
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showAddTask = true
                    } label: {
                        Label("Add Task", systemImage: "plus")
                    }

                    Button {
                        showEditProject = true
                    } label: {
                        Label("Edit Project", systemImage: "pencil")
                    }

                    Button {
                        store.archiveProject(project.safeID)
                    } label: {
                        Label("Archive Project", systemImage: "archivebox")
                    }

                    Divider()

                    Button {
                        exportPDF()
                    } label: {
                        Label("Export as PDF", systemImage: "arrow.up.doc")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Project actions")
            }
        }
        .sheet(isPresented: $showAddTask) {
            AddTaskView(projectID: project.safeID)
        }
        .sheet(isPresented: $showEditProject) {
            EditProjectView(project: currentProject)
        }
        .sheet(isPresented: Binding(
            get: { editingTaskID != nil },
            set: { if !$0 { editingTaskID = nil } }
        )) {
            if let taskID = editingTaskID,
               let task = currentProject.safeTasks.first(where: { $0.safeID == taskID }) {
                EditTaskView(task: task, projectID: project.safeID)
            }
        }
        .alert("Delete Task", isPresented: Binding(
            get: { taskToDelete != nil },
            set: { if !$0 { taskToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                taskToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let task = taskToDelete {
                    store.deleteTask(task.safeID, from: project.safeID)
                }
                taskToDelete = nil
            }
        } message: {
            Text("Are you sure you want to permanently delete this task?")
        }

    }

    // MARK: - Project Info

    private var projectInfoSection: some View {
        Section("Details") {
            if !currentProject.safeDescription.isEmpty {
                Text(currentProject.safeDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            LabeledContent("Category") {
                Label(currentProject.safeCategory.rawValue, systemImage: currentProject.safeCategory.icon)
            }

            LabeledContent("Start Date") {
                Text(currentProject.safeStartDate, style: .date)
            }

            LabeledContent("End Date") {
                Text(currentProject.safeEndDate, style: .date)
            }
        }
    }

    // MARK: - Progress

    private var progressSection: some View {
        Section("Progress") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(completedCount) of \(currentProject.activeTasks.count) tasks completed")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(currentProject.completionPercentage * 100))%")
                        .font(.subheadline.weight(.semibold))
                }

                ProgressView(value: currentProject.completionPercentage)
                    .tint(color(for: currentProject.safeColorName))
                    .accessibilityLabel("Completion progress")
                    .accessibilityValue("\(Int(currentProject.completionPercentage * 100)) percent")

                HStack(spacing: 16) {
                    statusBadge(count: notStartedCount, label: "To Do", color: .gray)
                    statusBadge(count: inProgressCount, label: "In Progress", color: .blue)
                    statusBadge(count: completedCount, label: "Done", color: .green)
                }
                .padding(.top, 4)
            }
            .padding(.vertical, 4)
        }
    }

    private func statusBadge(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(count) \(label)")
    }

    // MARK: - Tasks

    private var tasksSection: some View {
        let swipeTip = SwipeTaskTip()
        return Section("Tasks") {
            if currentProject.activeTasks.isEmpty {
                ContentUnavailableView {
                    Label("No Tasks", systemImage: "checklist")
                } description: {
                    Text("Tap the menu to add tasks to this project.")
                }
            } else {
                TipView(swipeTip)
                ForEach(sortedTasks) { task in
                    TaskRow(task: task, projectID: project.safeID)
                        .rowSwipeActions(onDelete: {
                            taskToDelete = task
                        }, onArchive: {
                            store.archiveTask(task.safeID, in: project.safeID)
                        }, onEdit: {
                            editingTaskID = task.safeID
                        })
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var sortedTasks: [ProjectTask] {
        currentProject.activeTasks.sorted { a, b in
            if a.safeStatus == .completed && b.safeStatus != .completed { return false }
            if a.safeStatus != .completed && b.safeStatus == .completed { return true }
            if a.safePriority != b.safePriority { return a.safePriority < b.safePriority }
            return a.safeDueDate < b.safeDueDate
        }
    }

    private var completedCount: Int {
        currentProject.activeTasks.filter { $0.safeStatus == .completed }.count
    }

    private var inProgressCount: Int {
        currentProject.activeTasks.filter { $0.safeStatus == .inProgress }.count
    }

    private var notStartedCount: Int {
        currentProject.activeTasks.filter { $0.safeStatus == .notStarted }.count
    }

    private func exportPDF() {
        let info = PDFProjectInfo(from: currentProject)
        let generator = PDFGenerator()
        let data = generator.generatePDF(for: info)
        let itemSource = PDFActivityItemSource(data: data, projectName: currentProject.safeName)

        let activityVC = UIActivityViewController(activityItems: [itemSource], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.keyWindow?.rootViewController {
            var presenter = rootVC
            while let presented = presenter.presentedViewController {
                presenter = presented
            }
            activityVC.popoverPresentationController?.sourceView = presenter.view
            activityVC.popoverPresentationController?.sourceRect = CGRect(x: presenter.view.bounds.midX, y: 0, width: 0, height: 0)
            presenter.present(activityVC, animated: true)
        }
    }

    private func color(for name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "purple": return .purple
        case "orange": return .orange
        case "red": return .red
        case "green": return .green
        case "pink": return .pink
        default: return .blue
        }
    }
}

#Preview {
    NavigationStack {
        ProjectDetailView(project: Project(name: "Sample", descriptionText: "A sample project", tasks: [
            ProjectTask(title: "Task 1", dueDate: .now, status: .completed, priority: .high),
            ProjectTask(title: "Task 2", dueDate: .now, status: .inProgress, priority: .medium),
            ProjectTask(title: "Task 3", dueDate: .now, priority: .low),
        ]))
    }
    .environment(ProjectStore.preview())
}
