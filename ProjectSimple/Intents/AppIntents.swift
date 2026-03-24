import AppIntents
import SwiftData

// MARK: - Helpers

/// Creates a ModelContext from the shared container for use in intents
private func makeContext() throws -> ModelContext {
    let container = try SharedModelContainer.create()
    return ModelContext(container)
}

// MARK: - Project Entity

struct ProjectEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Project")
    static var defaultQuery = ProjectEntityQuery()

    var id: UUID
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct ProjectEntityQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [ProjectEntity] {
        let context = try makeContext()
        let descriptor = FetchDescriptor<Project>()
        let projects = (try? context.fetch(descriptor)) ?? []
        return projects
            .filter { identifiers.contains($0.safeID) && !$0.safeIsArchived }
            .map { ProjectEntity(id: $0.safeID, name: $0.safeName) }
    }

    @MainActor
    func suggestedEntities() async throws -> [ProjectEntity] {
        let context = try makeContext()
        let descriptor = FetchDescriptor<Project>(sortBy: [SortDescriptor(\.name)])
        let projects = (try? context.fetch(descriptor)) ?? []
        return projects
            .filter { !$0.safeIsArchived }
            .map { ProjectEntity(id: $0.safeID, name: $0.safeName) }
    }
}

// MARK: - Task Entity

struct TaskEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Task")
    static var defaultQuery = TaskEntityQuery()

    var id: UUID
    var title: String
    var projectName: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(projectName)")
    }
}

struct TaskEntityQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [TaskEntity] {
        let context = try makeContext()
        let descriptor = FetchDescriptor<Project>()
        let projects = (try? context.fetch(descriptor)) ?? []
        var results: [TaskEntity] = []
        for project in projects where !project.safeIsArchived {
            for task in project.activeTasks where identifiers.contains(task.safeID) {
                results.append(TaskEntity(id: task.safeID, title: task.safeTitle, projectName: project.safeName))
            }
        }
        return results
    }

    @MainActor
    func suggestedEntities() async throws -> [TaskEntity] {
        let context = try makeContext()
        let descriptor = FetchDescriptor<Project>(sortBy: [SortDescriptor(\.name)])
        let projects = (try? context.fetch(descriptor)) ?? []
        var results: [TaskEntity] = []
        for project in projects where !project.safeIsArchived {
            for task in project.activeTasks where task.safeStatus != .completed {
                results.append(TaskEntity(id: task.safeID, title: task.safeTitle, projectName: project.safeName))
            }
        }
        return results
    }
}

// MARK: - New Project Intent

struct NewProjectIntent: AppIntent {
    static var title: LocalizedStringResource = "New Project"
    static var description = IntentDescription("Creates a new project in ProjectSimple.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        QuickActionState.shared.pendingAction = "com.projectsimple.newProject"
        return .result(dialog: "Opening ProjectSimple to create a new project.")
    }
}

// MARK: - Add Task Intent

struct AddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Task"
    static var description = IntentDescription("Opens ProjectSimple to add a new task to a project.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Project")
    var project: ProjectEntity

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        QuickActionState.shared.pendingProjectID = project.id
        QuickActionState.shared.pendingAction = "com.projectsimple.addTask"
        return .result(dialog: "Opening \(project.name) to add a task.")
    }
}

// MARK: - Show Overdue Tasks Intent

struct ShowOverdueTasksIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Overdue Tasks"
    static var description = IntentDescription("Shows your overdue tasks from ProjectSimple.")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = try makeContext()
        let descriptor = FetchDescriptor<Project>(
            predicate: #Predicate<Project> { $0.isArchived != true }
        )
        let projects = (try? context.fetch(descriptor)) ?? []

        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)

        var overdueTasks: [(title: String, projectName: String)] = []
        for project in projects {
            for task in project.activeTasks {
                if task.safeStatus != .completed && task.safeDueDate < startOfToday {
                    overdueTasks.append((title: task.safeTitle, projectName: project.safeName))
                }
            }
        }

        if overdueTasks.isEmpty {
            return .result(dialog: "You have no overdue tasks. You're all caught up!")
        }

        let count = overdueTasks.count
        let taskWord = count == 1 ? "task" : "tasks"
        let listing = overdueTasks.prefix(5)
            .map { "\($0.title) in \($0.projectName)" }
            .joined(separator: ". ")

        let summary: String
        if count <= 5 {
            summary = "You have \(count) overdue \(taskWord): \(listing)."
        } else {
            summary = "You have \(count) overdue \(taskWord). Here are the first 5: \(listing)."
        }

        return .result(dialog: "\(summary)")
    }
}

// MARK: - Get Task Count Intent

struct GetTaskCountIntent: AppIntent {
    static var title: LocalizedStringResource = "Task Summary"
    static var description = IntentDescription("Tells you how many active tasks you have in ProjectSimple.")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = try makeContext()
        let descriptor = FetchDescriptor<Project>(
            predicate: #Predicate<Project> { $0.isArchived != true }
        )
        let projects = (try? context.fetch(descriptor)) ?? []

        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

        var totalActive = 0
        var overdueCount = 0
        var dueTodayCount = 0

        for project in projects {
            for task in project.activeTasks where task.safeStatus != .completed {
                totalActive += 1
                if task.safeDueDate < startOfToday {
                    overdueCount += 1
                } else if task.safeDueDate >= startOfToday && task.safeDueDate < endOfToday {
                    dueTodayCount += 1
                }
            }
        }

        if totalActive == 0 {
            return .result(dialog: "You have no active tasks. Nice work!")
        }

        var parts: [String] = []
        parts.append("You have \(totalActive) active \(totalActive == 1 ? "task" : "tasks")")

        if overdueCount > 0 {
            parts.append("\(overdueCount) \(overdueCount == 1 ? "is" : "are") overdue")
        }
        if dueTodayCount > 0 {
            parts.append("\(dueTodayCount) \(dueTodayCount == 1 ? "is" : "are") due today")
        }

        let dialog = parts.joined(separator: ", ") + "."
        return .result(dialog: "\(dialog)")
    }
}

// MARK: - Mark Task Complete Intent

struct MarkTaskCompleteIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Task Complete"
    static var description = IntentDescription("Marks a task as completed in ProjectSimple.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Task")
    var task: TaskEntity

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = try makeContext()
        let descriptor = FetchDescriptor<Project>(
            predicate: #Predicate<Project> { $0.isArchived != true }
        )
        let projects = (try? context.fetch(descriptor)) ?? []

        for project in projects {
            if let matchingTask = project.activeTasks.first(where: { $0.safeID == task.id }) {
                matchingTask.status = .completed
                matchingTask.completedDate = Date.now

                // Handle recurrence
                if matchingTask.safeRecurrenceRule != .none && !matchingTask.safeHasGeneratedNextOccurrence,
                   let nextDate = matchingTask.safeRecurrenceRule.nextDueDate(from: matchingTask.safeDueDate) {
                    let nextTask = ProjectTask(
                        title: matchingTask.safeTitle,
                        details: matchingTask.safeDetails,
                        dueDate: nextDate,
                        priority: matchingTask.safePriority,
                        recurrenceRule: matchingTask.safeRecurrenceRule,
                        steps: matchingTask.stepsResetForRecurrence
                    )
                    matchingTask.hasGeneratedNextOccurrence = true
                    if project.tasks == nil { project.tasks = [] }
                    project.tasks?.append(nextTask)
                }

                try? context.save()
                return .result(dialog: "Done! I've marked \"\(task.title)\" as completed.")
            }
        }

        return .result(dialog: "I couldn't find that task. It may have been deleted or archived.")
    }
}

// MARK: - App Shortcuts Provider

struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: NewProjectIntent(),
            phrases: [
                "Create a new project in \(.applicationName)",
                "Add a project in \(.applicationName)",
                "New project in \(.applicationName)",
                "Start a project in \(.applicationName)"
            ],
            shortTitle: "New Project",
            systemImageName: "folder.badge.plus"
        )
        AppShortcut(
            intent: AddTaskIntent(),
            phrases: [
                "Add a task in \(.applicationName)",
                "New task in \(.applicationName)",
                "Create a task in \(.applicationName)"
            ],
            shortTitle: "Add Task",
            systemImageName: "plus.circle"
        )
        AppShortcut(
            intent: ShowOverdueTasksIntent(),
            phrases: [
                "Show overdue tasks in \(.applicationName)",
                "What's overdue in \(.applicationName)",
                "Check overdue in \(.applicationName)"
            ],
            shortTitle: "Overdue Tasks",
            systemImageName: "exclamationmark.triangle"
        )
        AppShortcut(
            intent: GetTaskCountIntent(),
            phrases: [
                "Task summary in \(.applicationName)",
                "How many tasks in \(.applicationName)",
                "What's due in \(.applicationName)"
            ],
            shortTitle: "Task Summary",
            systemImageName: "number.circle"
        )
        AppShortcut(
            intent: MarkTaskCompleteIntent(),
            phrases: [
                "Complete a task in \(.applicationName)",
                "Mark task done in \(.applicationName)",
                "Finish a task in \(.applicationName)"
            ],
            shortTitle: "Complete Task",
            systemImageName: "checkmark.circle"
        )
    }
}
