import Foundation

struct ExportableTask: Codable {
    let id: UUID
    let title: String
    let details: String
    let dueDate: Date
    let status: TaskStatus
    let priority: TaskPriority
    let isArchived: Bool
    let recurrenceRule: RecurrenceRule
    let hasGeneratedNextOccurrence: Bool
    let steps: [TaskStep]
    let completedDate: Date?

    init(from task: ProjectTask) {
        self.id = task.safeID
        self.title = task.safeTitle
        self.details = task.safeDetails
        self.dueDate = task.safeDueDate
        self.status = task.safeStatus
        self.priority = task.safePriority
        self.isArchived = task.safeIsArchived
        self.recurrenceRule = task.safeRecurrenceRule
        self.hasGeneratedNextOccurrence = task.safeHasGeneratedNextOccurrence
        self.steps = task.safeSteps
        self.completedDate = task.completedDate
    }

    func toProjectTask() -> ProjectTask {
        let task = ProjectTask(
            id: id,
            title: title,
            details: details,
            dueDate: dueDate,
            status: status,
            priority: priority,
            isArchived: isArchived,
            recurrenceRule: recurrenceRule,
            steps: steps,
            completedDate: completedDate
        )
        task.hasGeneratedNextOccurrence = hasGeneratedNextOccurrence
        return task
    }
}

struct ExportableProject: Codable {
    let id: UUID
    let name: String
    let descriptionText: String
    let startDate: Date
    let endDate: Date
    let colorName: String
    let category: ProjectCategory
    let isArchived: Bool
    let tasks: [ExportableTask]

    init(from project: Project) {
        self.id = project.safeID
        self.name = project.safeName
        self.descriptionText = project.safeDescription
        self.startDate = project.safeStartDate
        self.endDate = project.safeEndDate
        self.colorName = project.safeColorName
        self.category = project.safeCategory
        self.isArchived = project.safeIsArchived
        self.tasks = project.safeTasks.map { ExportableTask(from: $0) }
    }

    func toProject() -> Project {
        let tasks = tasks.map { $0.toProjectTask() }
        return Project(
            id: id,
            name: name,
            descriptionText: descriptionText,
            startDate: startDate,
            endDate: endDate,
            tasks: tasks,
            colorName: colorName,
            category: category,
            isArchived: isArchived
        )
    }
}

struct AppBackup: Codable {
    let exportDate: Date
    let projects: [ExportableProject]

    init(projects: [Project]) {
        self.exportDate = .now
        self.projects = projects.map { ExportableProject(from: $0) }
    }

    static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
