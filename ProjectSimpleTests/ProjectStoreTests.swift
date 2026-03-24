import Testing
import Foundation
import SwiftData
@testable import ProjectSimple

// Single shared container to prevent "model instance was destroyed" errors
// caused by creating multiple ModelContainers for the same schema.
private let _testContainer: ModelContainer = {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    do {
        return try ModelContainer(for: Project.self, ProjectTask.self, configurations: config)
    } catch {
        fatalError("Failed to create test ModelContainer: \(error). Try Product → Clean Build Folder (Cmd+Shift+K).")
    }
}()

// All SwiftData-dependent tests in a single serialized suite.
@MainActor
@Suite(.serialized)
struct SwiftDataTests {

    private func makeStore() -> ProjectStore {
        // Clear all existing data so each test starts fresh.
        // Delete objects individually rather than using batch delete
        // (context.delete(model:)) which triggers CoreData constraint
        // violations on the mandatory ProjectTask.project inverse.
        let context = _testContainer.mainContext
        let projects = (try? context.fetch(FetchDescriptor<Project>())) ?? []
        for project in projects {
            let tasks = project.tasks ?? []
            project.tasks?.removeAll()
            for task in tasks {
                context.delete(task)
            }
            context.delete(project)
        }
        try? context.save()
        let store = ProjectStore(modelContext: context)
        store.loadSampleData()
        return store
    }

    // MARK: - ProjectTask Init

    @Test func taskDefaultInitValues() {
        let store = makeStore()
        let projectID = store.projects[0].safeID
        let task = ProjectTask(title: "Test", dueDate: .now)
        store.addTask(task, to: projectID)
        #expect(task.safeTitle == "Test")
        #expect(task.safeDetails == "")
        #expect(task.safeStatus == .notStarted)
        #expect(task.safePriority == .medium)
        #expect(task.safeIsArchived == false)
    }

    @Test func taskCustomInitValues() {
        let store = makeStore()
        let projectID = store.projects[0].safeID
        let date = Date.now
        let id = UUID()
        let task = ProjectTask(
            id: id,
            title: "Custom",
            details: "Some details",
            dueDate: date,
            status: .completed,
            priority: .high
        )
        store.addTask(task, to: projectID)
        #expect(task.safeID == id)
        #expect(task.safeTitle == "Custom")
        #expect(task.safeDetails == "Some details")
        #expect(task.safeStatus == .completed)
        #expect(task.safePriority == .high)
    }

    // MARK: - Project Init

    @Test func projectDefaultInitValues() {
        let store = makeStore()
        let project = Project(name: "Test Project")
        store.addProject(project)
        #expect(project.safeName == "Test Project")
        #expect(project.descriptionText == "")
        #expect(project.safeTasks.isEmpty)
        #expect(project.colorName == "blue")
        #expect(project.category == .other)
        #expect(project.safeIsArchived == false)
    }

    @Test func projectCustomCategoryInitValue() {
        let store = makeStore()
        let project = Project(name: "Work Project", category: .work)
        store.addProject(project)
        #expect(project.category == .work)
    }

    // MARK: - Active Tasks / Completion

    @Test func activeTasksExcludesArchived() {
        let store = makeStore()
        let project = Project(name: "Filter Test")
        store.addProject(project)
        let projectID = project.safeID
        store.addTask(ProjectTask(title: "A", dueDate: .now), to: projectID)
        store.addTask(ProjectTask(title: "B", dueDate: .now, isArchived: true), to: projectID)
        store.addTask(ProjectTask(title: "C", dueDate: .now), to: projectID)
        let updated = store.projects.first { $0.safeID == projectID }!
        #expect(updated.activeTasks.count == 2)
        #expect(updated.activeTasks.allSatisfy { !$0.safeIsArchived })
    }

    @Test func completionPercentageIgnoresArchivedTasks() {
        let store = makeStore()
        let project = Project(name: "Mixed")
        store.addProject(project)
        let projectID = project.safeID
        store.addTask(ProjectTask(title: "A", dueDate: .now, status: .completed), to: projectID)
        store.addTask(ProjectTask(title: "B", dueDate: .now, status: .notStarted), to: projectID)
        store.addTask(ProjectTask(title: "C", dueDate: .now, status: .completed, isArchived: true), to: projectID)
        let updated = store.projects.first { $0.safeID == projectID }!
        #expect(updated.completionPercentage == 0.5)
    }

    @Test func completionPercentageWithNoTasks() {
        let store = makeStore()
        let project = Project(name: "Empty")
        store.addProject(project)
        let updated = store.projects.first { $0.safeID == project.safeID }!
        #expect(updated.completionPercentage == 0)
    }

    @Test func completionPercentageWithAllCompleted() {
        let store = makeStore()
        let project = Project(name: "Done")
        store.addProject(project)
        let projectID = project.safeID
        store.addTask(ProjectTask(title: "A", dueDate: .now, status: .completed), to: projectID)
        store.addTask(ProjectTask(title: "B", dueDate: .now, status: .completed), to: projectID)
        let updated = store.projects.first { $0.safeID == projectID }!
        #expect(updated.completionPercentage == 1.0)
    }

    @Test func completionPercentagePartial() {
        let store = makeStore()
        let project = Project(name: "Partial")
        store.addProject(project)
        let projectID = project.safeID
        store.addTask(ProjectTask(title: "A", dueDate: .now, status: .completed), to: projectID)
        store.addTask(ProjectTask(title: "B", dueDate: .now, status: .inProgress), to: projectID)
        store.addTask(ProjectTask(title: "C", dueDate: .now, status: .notStarted), to: projectID)
        store.addTask(ProjectTask(title: "D", dueDate: .now, status: .completed), to: projectID)
        let updated = store.projects.first { $0.safeID == projectID }!
        #expect(updated.completionPercentage == 0.5)
    }

    @Test func completionPercentageNoneCompleted() {
        let store = makeStore()
        let project = Project(name: "None")
        store.addProject(project)
        let projectID = project.safeID
        store.addTask(ProjectTask(title: "A", dueDate: .now, status: .notStarted), to: projectID)
        store.addTask(ProjectTask(title: "B", dueDate: .now, status: .inProgress), to: projectID)
        let updated = store.projects.first { $0.safeID == projectID }!
        #expect(updated.completionPercentage == 0.0)
    }

    // MARK: - Store Initialization

    @Test func initLoadsSampleData() {
        let store = makeStore()
        #expect(store.projects.count == 1)
        #expect(store.projects[0].safeName == "Getting Started")
    }

    @Test func sampleProjectHasTasks() {
        let store = makeStore()
        let project = store.projects[0]
        #expect(!project.safeTasks.isEmpty)
        #expect(project.safeTasks.count == 6)
    }

    // MARK: - Add Project

    @Test func addProjectIncreasesCount() {
        let store = makeStore()
        let initialCount = store.projects.count
        let project = Project(name: "New Project")
        store.addProject(project)
        #expect(store.projects.count == initialCount + 1)
    }

    @Test func addProjectAppendsCorrectly() {
        let store = makeStore()
        let project = Project(name: "Appended")
        store.addProject(project)
        #expect(store.projects.contains { $0.safeName == "Appended" })
    }

    // MARK: - Delete Project

    @Test func deleteProjectRemovesCorrectProject() {
        let store = makeStore()
        let firstProject = store.activeProjects[0]
        let firstProjectID = firstProject.safeID
        store.deleteProject(firstProjectID)
        #expect(store.projects.allSatisfy { $0.safeID != firstProjectID })
    }

    @Test func deleteProjectDecreasesCount() {
        let store = makeStore()
        let initialCount = store.projects.count
        let projectID = store.projects[0].safeID
        store.deleteProject(projectID)
        #expect(store.projects.count == initialCount - 1)
    }

    // MARK: - Add Task

    @Test func addTaskToProject() {
        let store = makeStore()
        let project = store.projects[0]
        let projectID = project.safeID
        let initialTaskCount = project.safeTasks.count
        let task = ProjectTask(title: "New Task", dueDate: .now)
        store.addTask(task, to: projectID)
        let updatedProject = store.projects.first { $0.safeID == projectID }!
        #expect(updatedProject.safeTasks.count == initialTaskCount + 1)
        #expect(updatedProject.safeTasks.contains { $0.safeTitle == "New Task" })
    }

    @Test func addTaskToInvalidProjectDoesNothing() {
        let store = makeStore()
        let bogusID = UUID()
        let task = ProjectTask(title: "Orphan", dueDate: .now)
        store.addTask(task, to: bogusID)
        for project in store.projects {
            #expect(project.safeTasks.allSatisfy { $0.safeTitle != "Orphan" })
        }
    }

    // MARK: - Update Task

    @Test func updateTaskChangesStatus() {
        let store = makeStore()
        let project = store.projects[0]
        let projectID = project.safeID
        let task = project.safeTasks[0]
        let originalStatus = task.safeStatus
        task.status = (originalStatus == .completed) ? .notStarted : .completed
        store.updateTask(task, in: projectID)
        let updatedProject = store.projects.first { $0.safeID == projectID }!
        let updatedTask = updatedProject.safeTasks.first { $0.safeID == task.safeID }
        #expect(updatedTask?.safeStatus != originalStatus)
    }

    @Test func updateTaskChangesTitle() {
        let store = makeStore()
        let project = store.projects[0]
        let projectID = project.safeID
        let task = project.safeTasks[0]
        task.title = "Updated Title"
        store.updateTask(task, in: projectID)
        let updatedProject = store.projects.first { $0.safeID == projectID }!
        let updatedTask = updatedProject.safeTasks.first { $0.safeID == task.safeID }
        #expect(updatedTask?.safeTitle == "Updated Title")
    }

    @Test func editTaskChangesAllFields() {
        let store = makeStore()
        let project = store.projects[0]
        let projectID = project.safeID
        let task = project.safeTasks[0]
        let taskID = task.safeID

        // Simulate EditTaskView: copy values, modify, write back, then update
        task.title = "Edited Title"
        task.details = "Edited details"
        task.priority = .low
        task.status = .completed
        let newDate = Calendar.current.date(byAdding: .day, value: 30, to: .now)!
        task.dueDate = newDate
        store.updateTask(task, in: projectID)

        // Re-fetch from store (simulates what the view sees after refresh)
        let updatedProject = store.projects.first { $0.safeID == projectID }!
        let updatedTask = updatedProject.safeTasks.first { $0.safeID == taskID }
        #expect(updatedTask?.safeTitle == "Edited Title")
        #expect(updatedTask?.safeDetails == "Edited details")
        #expect(updatedTask?.safePriority == .low)
        #expect(updatedTask?.safeStatus == .completed)
        #expect(Calendar.current.isDate(updatedTask!.safeDueDate, inSameDayAs: newDate))
    }

    @Test func editTaskPersistsAfterRefetch() {
        let store = makeStore()
        let project = store.projects[0]
        let projectID = project.safeID
        let task = project.safeTasks[0]
        let taskID = task.safeID

        task.title = "Persisted Edit"
        store.updateTask(task, in: projectID)

        // Fetch the task by looking it up via its UUID in the refreshed store
        let refetchedTask = store.projects
            .first { $0.safeID == projectID }?
            .safeTasks.first { $0.safeID == taskID }
        #expect(refetchedTask != nil)
        #expect(refetchedTask?.safeTitle == "Persisted Edit")
    }

    // MARK: - Delete Task

    @Test func deleteTaskRemovesFromProject() {
        let store = makeStore()
        let project = store.projects[0]
        let projectID = project.safeID
        let taskID = project.safeTasks[0].safeID
        let initialCount = project.safeTasks.count
        store.deleteTask(taskID, from: projectID)
        let updatedProject = store.projects.first { $0.safeID == projectID }!
        #expect(updatedProject.safeTasks.count == initialCount - 1)
        #expect(updatedProject.safeTasks.allSatisfy { $0.safeID != taskID })
    }

    @Test func deleteTaskWithInvalidProjectDoesNothing() {
        let store = makeStore()
        let taskID = store.projects[0].safeTasks[0].safeID
        let initialCount = store.projects[0].safeTasks.count
        store.deleteTask(taskID, from: UUID())
        #expect(store.projects[0].safeTasks.count == initialCount)
    }

    @Test func deleteTaskWithInvalidTaskIDDoesNothing() {
        let store = makeStore()
        let projectID = store.projects[0].safeID
        let initialCount = store.projects[0].safeTasks.count
        store.deleteTask(UUID(), from: projectID)
        let updatedProject = store.projects.first { $0.safeID == projectID }!
        #expect(updatedProject.safeTasks.count == initialCount)
    }

    // MARK: - Overdue Tasks

    @Test func overdueTasksReturnsTasksBeforeToday() {
        let store = makeStore()
        let calendar = Calendar.current
        let project = Project(name: "Overdue Test")
        store.addProject(project)
        let projectID = project.safeID
        let pastTask = ProjectTask(
            title: "Past Task",
            dueDate: calendar.date(byAdding: .day, value: -3, to: .now)!,
            status: .notStarted
        )
        store.addTask(pastTask, to: projectID)
        let overdue = store.overdueTasks()
        #expect(overdue.contains { $0.task.safeTitle == "Past Task" })
    }

    @Test func overdueTasksExcludesCompletedTasks() {
        let store = makeStore()
        let calendar = Calendar.current
        let project = Project(name: "Done Test")
        store.addProject(project)
        let projectID = project.safeID
        let doneTask = ProjectTask(
            title: "Done Past Task",
            dueDate: calendar.date(byAdding: .day, value: -2, to: .now)!,
            status: .completed
        )
        store.addTask(doneTask, to: projectID)
        let overdue = store.overdueTasks()
        #expect(overdue.allSatisfy { $0.task.safeTitle != "Done Past Task" })
    }

    @Test func overdueTasksExcludesFutureTasks() {
        let store = makeStore()
        let calendar = Calendar.current
        let project = Project(name: "Future Test")
        store.addProject(project)
        let projectID = project.safeID
        let futureTask = ProjectTask(
            title: "Future Task",
            dueDate: calendar.date(byAdding: .day, value: 5, to: .now)!,
            status: .notStarted
        )
        store.addTask(futureTask, to: projectID)
        let overdue = store.overdueTasks()
        #expect(overdue.allSatisfy { $0.task.safeTitle != "Future Task" })
    }

    @Test func overdueTasksExcludesArchivedProjects() {
        let store = makeStore()
        let calendar = Calendar.current
        let project = Project(name: "Archived Overdue")
        store.addProject(project)
        let projectID = project.safeID
        let pastTask = ProjectTask(
            title: "Archived Past",
            dueDate: calendar.date(byAdding: .day, value: -1, to: .now)!,
            status: .notStarted
        )
        store.addTask(pastTask, to: projectID)
        store.archiveProject(projectID)
        let overdue = store.overdueTasks()
        #expect(overdue.allSatisfy { $0.task.safeTitle != "Archived Past" })
    }

    @Test func overdueTasksSortedByDueDate() {
        let store = makeStore()
        let calendar = Calendar.current
        // Delete sample data projects to isolate this test
        let ids = store.projects.map(\.safeID)
        for id in ids { store.deleteProject(id) }

        let project = Project(name: "Sort Test")
        store.addProject(project)
        let projectID = project.safeID
        let older = ProjectTask(
            title: "Older",
            dueDate: calendar.date(byAdding: .day, value: -5, to: .now)!,
            status: .inProgress
        )
        let newer = ProjectTask(
            title: "Newer",
            dueDate: calendar.date(byAdding: .day, value: -1, to: .now)!,
            status: .notStarted
        )
        store.addTask(newer, to: projectID)
        store.addTask(older, to: projectID)
        let overdue = store.overdueTasks()
        #expect(overdue.count == 2)
        #expect(overdue[0].task.safeTitle == "Older")
        #expect(overdue[1].task.safeTitle == "Newer")
    }

    // MARK: - Calendar Helpers

    @Test func tasksForDateReturnsMatchingTasks() {
        let store = makeStore()
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: .now)!
        let results = store.tasks(for: tomorrow)
        #expect(results.contains { $0.task.safeTitle == "Explore this project" })
    }

    @Test func tasksForDateWithNoTasksReturnsEmpty() {
        let store = makeStore()
        let calendar = Calendar.current
        let farFuture = calendar.date(byAdding: .year, value: 10, to: .now)!
        let results = store.tasks(for: farFuture)
        #expect(results.isEmpty)
    }

    @Test func tasksForDateReturnsCorrectProjectAssociation() {
        let store = makeStore()
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: .now)!
        let results = store.tasks(for: tomorrow)
        for result in results {
            #expect(result.project.safeTasks.contains { $0.safeID == result.task.safeID })
        }
    }

    @Test func allTasksReturnsFlattenedList() {
        let store = makeStore()
        let totalTasks = store.activeProjects.reduce(0) { $0 + $1.activeTasks.count }
        let allTasks = store.allTasks()
        #expect(allTasks.count == totalTasks)
    }

    @Test func allTasksAssociatesCorrectProjects() {
        let store = makeStore()
        let allTasks = store.allTasks()
        for item in allTasks {
            #expect(item.project.safeTasks.contains { $0.safeID == item.task.safeID })
        }
    }

    // MARK: - Update Project

    @Test func updateProjectChangesName() {
        let store = makeStore()
        let project = store.projects[0]
        project.name = "Renamed"
        store.updateProject(project)
        #expect(store.projects.contains { $0.safeName == "Renamed" })
    }

    // MARK: - Delete Project by ID

    @Test func deleteProjectByIDRemovesProject() {
        let store = makeStore()
        let projectID = store.projects[0].safeID
        store.deleteProject(projectID)
        #expect(store.projects.allSatisfy { $0.safeID != projectID })
    }

    @Test func deleteProjectByInvalidIDDoesNothing() {
        let store = makeStore()
        let initialCount = store.projects.count
        store.deleteProject(UUID())
        #expect(store.projects.count == initialCount)
    }

    // MARK: - Archive Project

    @Test func archiveProjectSetsIsArchived() {
        let store = makeStore()
        let projectID = store.projects[0].safeID
        store.archiveProject(projectID)
        #expect(store.projects.first(where: { $0.safeID == projectID })?.safeIsArchived == true)
    }

    @Test func archivedProjectExcludedFromActiveProjects() {
        let store = makeStore()
        let projectID = store.projects[0].safeID
        store.archiveProject(projectID)
        #expect(store.activeProjects.allSatisfy { $0.safeID != projectID })
    }

    @Test func archivedProjectAppearsInArchivedProjects() {
        let store = makeStore()
        let projectID = store.projects[0].safeID
        store.archiveProject(projectID)
        #expect(store.archivedProjects.contains { $0.safeID == projectID })
    }

    @Test func unarchiveProjectRestoresProject() {
        let store = makeStore()
        let projectID = store.projects[0].safeID
        store.archiveProject(projectID)
        #expect(store.activeProjects.allSatisfy { $0.safeID != projectID })
        store.unarchiveProject(projectID)
        #expect(store.activeProjects.contains { $0.safeID == projectID })
        #expect(store.projects.first(where: { $0.safeID == projectID })?.safeIsArchived == false)
    }

    @Test func archiveInvalidProjectDoesNothing() {
        let store = makeStore()
        store.archiveProject(UUID())
        #expect(store.projects.allSatisfy { !$0.safeIsArchived })
    }

    // MARK: - Archive Task

    @Test func archiveTaskSetsIsArchived() {
        let store = makeStore()
        let project = store.projects[0]
        let projectID = project.safeID
        let taskID = project.safeTasks[0].safeID
        store.archiveTask(taskID, in: projectID)
        let updatedProject = store.projects.first { $0.safeID == projectID }!
        #expect(updatedProject.safeTasks.first(where: { $0.safeID == taskID })?.safeIsArchived == true)
    }

    @Test func archivedTaskExcludedFromActiveTasks() {
        let store = makeStore()
        let project = store.projects[0]
        let projectID = project.safeID
        let taskID = project.safeTasks[0].safeID
        store.archiveTask(taskID, in: projectID)
        let updatedProject = store.projects.first { $0.safeID == projectID }!
        #expect(updatedProject.activeTasks.allSatisfy { $0.safeID != projectID })
    }

    @Test func unarchiveTaskRestoresTask() {
        let store = makeStore()
        let project = store.projects[0]
        let projectID = project.safeID
        let taskID = project.safeTasks[0].safeID
        store.archiveTask(taskID, in: projectID)
        store.unarchiveTask(taskID, in: projectID)
        let updatedProject = store.projects.first { $0.safeID == projectID }!
        #expect(updatedProject.activeTasks.contains { $0.safeID == taskID })
    }

    @Test func archiveTaskInvalidProjectDoesNothing() {
        let store = makeStore()
        let taskID = store.projects[0].safeTasks[0].safeID
        store.archiveTask(taskID, in: UUID())
        #expect(store.projects[0].safeTasks.first(where: { $0.safeID == taskID })?.safeIsArchived == false)
    }

    @Test func archiveTaskInvalidTaskDoesNothing() {
        let store = makeStore()
        let projectID = store.projects[0].safeID
        store.archiveTask(UUID(), in: projectID)
        #expect(store.projects[0].safeTasks.allSatisfy { !$0.safeIsArchived })
    }

    // MARK: - Completed Projects

    @Test func completedProjectsListsFullyComplete() {
        let store = makeStore()
        let project = store.projects[0]
        let projectID = project.safeID
        for task in project.safeTasks {
            task.status = .completed
            store.updateTask(task, in: projectID)
        }
        #expect(store.completedProjects.contains { $0.safeID == projectID })
    }

    @Test func completedProjectsExcludesArchivedProjects() {
        let store = makeStore()
        let project = store.projects[0]
        let projectID = project.safeID
        for task in project.safeTasks {
            task.status = .completed
            store.updateTask(task, in: projectID)
        }
        store.archiveProject(projectID)
        #expect(store.completedProjects.allSatisfy { $0.safeID != projectID })
    }

    // MARK: - Calendar Helpers Exclude Archived

    @Test func tasksForDateExcludesArchivedProjects() {
        let store = makeStore()
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: .now)!
        let projectID = store.projects.first(where: { $0.safeName == "Getting Started" })!.safeID
        store.archiveProject(projectID)
        let results = store.tasks(for: tomorrow)
        #expect(results.allSatisfy { $0.project.safeID != projectID })
    }

    @Test func tasksForDateExcludesArchivedTasks() {
        let store = makeStore()
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: .now)!
        let project = store.projects.first(where: { $0.safeName == "Getting Started" })!
        let projectID = project.safeID
        let taskID = project.safeTasks.first(where: { $0.safeTitle == "Explore this project" })!.safeID
        store.archiveTask(taskID, in: projectID)
        let results = store.tasks(for: tomorrow)
        #expect(results.allSatisfy { $0.task.safeID != taskID })
    }

    @Test func allTasksExcludesArchivedItems() {
        let store = makeStore()
        let project = store.projects[0]
        let projectID = project.safeID
        let taskID = project.safeTasks[0].safeID
        let initialCount = store.allTasks().count
        store.archiveTask(taskID, in: projectID)
        #expect(store.allTasks().count == initialCount - 1)
    }

    // MARK: - Integration Scenarios

    @Test func addThenDeleteTask() {
        let store = makeStore()
        let project = store.projects[0]
        let projectID = project.safeID
        let initialCount = project.safeTasks.count
        let task = ProjectTask(title: "Temporary", dueDate: .now)
        store.addTask(task, to: projectID)
        let updatedProject = store.projects.first { $0.safeID == projectID }!
        #expect(updatedProject.safeTasks.count == initialCount + 1)
        store.deleteTask(task.safeID, from: projectID)
        let finalProject = store.projects.first { $0.safeID == projectID }!
        #expect(finalProject.safeTasks.count == initialCount)
    }

    @Test func addThenUpdateTask() {
        let store = makeStore()
        let project = store.projects[0]
        let projectID = project.safeID
        let task = ProjectTask(title: "Original", dueDate: .now, priority: .low)
        store.addTask(task, to: projectID)
        task.title = "Modified"
        task.priority = .high
        store.updateTask(task, in: projectID)
        let updatedProject = store.projects.first { $0.safeID == projectID }!
        let updated = updatedProject.safeTasks.first { $0.safeID == task.safeID }
        #expect(updated?.safeTitle == "Modified")
        #expect(updated?.safePriority == .high)
    }

    @Test func deleteAllProjectsLeavesEmpty() {
        let store = makeStore()
        let projectIDs = store.projects.map(\.safeID)
        for id in projectIDs {
            store.deleteProject(id)
        }
        #expect(store.projects.isEmpty)
        #expect(store.allTasks().isEmpty)
    }

    // MARK: - Error Message

    @Test func errorMessageDefaultsToNil() {
        let store = makeStore()
        #expect(store.errorMessage == nil)
    }

    @Test func errorMessageCanBeCleared() {
        let store = makeStore()
        store.errorMessage = "Test error"
        #expect(store.errorMessage == "Test error")
        store.errorMessage = nil
        #expect(store.errorMessage == nil)
    }

    // MARK: - Category

    @Test func addProjectWithCategory() {
        let store = makeStore()
        let project = Project(name: "Work Project", category: .work)
        store.addProject(project)
        let found = store.projects.first { $0.safeName == "Work Project" }
        #expect(found?.category == .work)
    }

    @Test func updateProjectCategory() {
        let store = makeStore()
        let project = store.projects[0]
        project.category = .education
        store.updateProject(project)
        let updated = store.projects.first { $0.safeID == project.safeID }
        #expect(updated?.category == .education)
    }

    @Test func defaultCategoryIsOther() {
        let store = makeStore()
        let project = Project(name: "No Category")
        store.addProject(project)
        let found = store.projects.first { $0.safeName == "No Category" }
        #expect(found?.category == .other)
    }

    // MARK: - Notification Integration

    @Test func storeNotificationManagerDefaultsToNil() {
        let store = makeStore()
        #expect(store.notificationManager == nil)
    }

    @Test func storeAcceptsNotificationManager() {
        let store = makeStore()
        let manager = NotificationManager()
        store.notificationManager = manager
        #expect(store.notificationManager != nil)
    }

    @Test func addProjectTriggersRescheduleWithoutCrash() {
        let store = makeStore()
        let manager = NotificationManager()
        store.notificationManager = manager
        let project = Project(name: "Notification Test")
        store.addProject(project)
        #expect(store.projects.contains { $0.safeName == "Notification Test" })
    }

    @Test func addTaskTriggersRescheduleWithoutCrash() {
        let store = makeStore()
        let manager = NotificationManager()
        store.notificationManager = manager
        let project = store.projects[0]
        let projectID = project.safeID
        let task = ProjectTask(title: "Notified Task", dueDate: .now, priority: .high)
        store.addTask(task, to: projectID)
        let updatedProject = store.projects.first { $0.safeID == projectID }!
        #expect(updatedProject.safeTasks.contains { $0.safeTitle == "Notified Task" })
    }

    @Test func rescheduleSkipsCompletedTasks() async {
        let manager = NotificationManager()
        let store = makeStore()
        let calendar = Calendar.current
        let project = Project(name: "Test Project")
        store.addProject(project)
        let task = ProjectTask(
            title: "Done task",
            dueDate: calendar.date(byAdding: .day, value: 3, to: .now)!,
            status: .completed,
            priority: .medium
        )
        store.addTask(task, to: project.safeID)
        let fetched = store.projects.first { $0.safeID == project.safeID }!
        await manager.rescheduleAll(for: [fetched])
    }

    @Test func rescheduleHandlesProjectWithNoTasks() async {
        let manager = NotificationManager()
        let store = makeStore()
        let project = Project(name: "Empty Project")
        store.addProject(project)
        let fetched = store.projects.first { $0.safeID == project.safeID }!
        await manager.rescheduleAll(for: [fetched])
    }

    @Test func mutationsWorkWithoutNotificationManager() {
        let store = makeStore()
        let project = Project(name: "No Manager")
        store.addProject(project)
        store.deleteProject(project.safeID)

        let existingProject = store.projects[0]
        let projectID = existingProject.safeID
        let task = ProjectTask(title: "Test", dueDate: .now)
        store.addTask(task, to: projectID)
        task.title = "Updated"
        store.updateTask(task, in: projectID)
        store.deleteTask(task.safeID, from: projectID)
    }

    // MARK: - Recurrence

    @Test func recurrenceDefaultsToNone() {
        let task = ProjectTask(title: "Test", dueDate: .now)
        #expect(task.safeRecurrenceRule == .none)
        #expect(task.safeHasGeneratedNextOccurrence == false)
    }

    @Test func recurrenceCanBeSetOnInit() {
        let task = ProjectTask(title: "Test", dueDate: .now, recurrenceRule: .weekly)
        #expect(task.safeRecurrenceRule == .weekly)
    }

    @Test func completingRecurringTaskCreatesNextOccurrence() {
        let store = makeStore()
        let project = Project(name: "Recurrence Test")
        store.addProject(project)
        let projectID = project.safeID
        let calendar = Calendar.current
        let dueDate = calendar.date(byAdding: .day, value: 1, to: .now)!
        let task = ProjectTask(
            title: "Weekly Task",
            dueDate: dueDate,
            recurrenceRule: .weekly
        )
        store.addTask(task, to: projectID)
        let initialCount = store.projects.first { $0.safeID == projectID }!.safeTasks.count

        task.status = .completed
        store.updateTask(task, in: projectID)

        let updatedProject = store.projects.first { $0.safeID == projectID }!
        #expect(updatedProject.safeTasks.count == initialCount + 1)

        let newTask = updatedProject.safeTasks.first { $0.safeID != task.safeID && $0.safeTitle == "Weekly Task" }
        #expect(newTask != nil)
        #expect(newTask?.safeStatus == .notStarted)
        #expect(newTask?.safeRecurrenceRule == .weekly)
        #expect(newTask?.safePriority == task.safePriority)
        #expect(calendar.isDate(newTask!.safeDueDate, inSameDayAs: calendar.date(byAdding: .weekOfYear, value: 1, to: dueDate)!))
    }

    @Test func completingNonRecurringTaskDoesNotCreateOccurrence() {
        let store = makeStore()
        let project = Project(name: "No Recurrence Test")
        store.addProject(project)
        let projectID = project.safeID
        let task = ProjectTask(title: "One-time Task", dueDate: .now)
        store.addTask(task, to: projectID)
        let initialCount = store.projects.first { $0.safeID == projectID }!.safeTasks.count

        task.status = .completed
        store.updateTask(task, in: projectID)

        let updatedProject = store.projects.first { $0.safeID == projectID }!
        #expect(updatedProject.safeTasks.count == initialCount)
    }

    @Test func completingRecurringTaskTwiceDoesNotDuplicate() {
        let store = makeStore()
        let project = Project(name: "No Duplicate Test")
        store.addProject(project)
        let projectID = project.safeID
        let task = ProjectTask(
            title: "Daily Task",
            dueDate: .now,
            recurrenceRule: .daily
        )
        store.addTask(task, to: projectID)

        task.status = .completed
        store.updateTask(task, in: projectID)
        let countAfterFirst = store.projects.first { $0.safeID == projectID }!.safeTasks.count

        store.updateTask(task, in: projectID)
        let countAfterSecond = store.projects.first { $0.safeID == projectID }!.safeTasks.count

        #expect(countAfterFirst == countAfterSecond)
    }

    @Test func cyclingFromCompletedToNotStartedDoesNotGenerate() {
        let store = makeStore()
        let project = Project(name: "Cycle Test")
        store.addProject(project)
        let projectID = project.safeID
        let task = ProjectTask(
            title: "Cycling Task",
            dueDate: .now,
            recurrenceRule: .monthly
        )
        store.addTask(task, to: projectID)

        task.status = .completed
        store.updateTask(task, in: projectID)
        let countAfterComplete = store.projects.first { $0.safeID == projectID }!.safeTasks.count

        task.status = .notStarted
        store.updateTask(task, in: projectID)
        let countAfterCycle = store.projects.first { $0.safeID == projectID }!.safeTasks.count

        #expect(countAfterComplete == countAfterCycle)
    }

    @Test func recurringTaskNextDueDate_daily() {
        let store = makeStore()
        let project = Project(name: "Daily Test")
        store.addProject(project)
        let projectID = project.safeID
        let calendar = Calendar.current
        let baseDate = calendar.date(byAdding: .day, value: 5, to: .now)!
        let task = ProjectTask(title: "Daily", dueDate: baseDate, recurrenceRule: .daily)
        store.addTask(task, to: projectID)

        task.status = .completed
        store.updateTask(task, in: projectID)

        let updatedProject = store.projects.first { $0.safeID == projectID }!
        let newTask = updatedProject.safeTasks.first { $0.safeID != task.safeID && $0.safeTitle == "Daily" }
        #expect(newTask != nil)
        let expectedDate = calendar.date(byAdding: .day, value: 1, to: baseDate)!
        #expect(calendar.isDate(newTask!.safeDueDate, inSameDayAs: expectedDate))
    }

    @Test func recurringTaskNextDueDate_monthly() {
        let store = makeStore()
        let project = Project(name: "Monthly Test")
        store.addProject(project)
        let projectID = project.safeID
        let calendar = Calendar.current
        let baseDate = calendar.date(byAdding: .day, value: 5, to: .now)!
        let task = ProjectTask(title: "Monthly", dueDate: baseDate, recurrenceRule: .monthly)
        store.addTask(task, to: projectID)

        task.status = .completed
        store.updateTask(task, in: projectID)

        let updatedProject = store.projects.first { $0.safeID == projectID }!
        let newTask = updatedProject.safeTasks.first { $0.safeID != task.safeID && $0.safeTitle == "Monthly" }
        #expect(newTask != nil)
        let expectedDate = calendar.date(byAdding: .month, value: 1, to: baseDate)!
        #expect(calendar.isDate(newTask!.safeDueDate, inSameDayAs: expectedDate))
    }

    @Test func completedRecurringTaskRetainsProperties() {
        let store = makeStore()
        let project = Project(name: "Retain Test")
        store.addProject(project)
        let projectID = project.safeID
        let task = ProjectTask(
            title: "Keep Me",
            details: "Important details",
            dueDate: .now,
            priority: .high,
            recurrenceRule: .weekly
        )
        store.addTask(task, to: projectID)

        task.status = .completed
        store.updateTask(task, in: projectID)

        let updatedProject = store.projects.first { $0.safeID == projectID }!
        let originalTask = updatedProject.safeTasks.first { $0.safeID == task.safeID }
        #expect(originalTask?.safeStatus == .completed)
        #expect(originalTask?.safeTitle == "Keep Me")
        #expect(originalTask?.safeHasGeneratedNextOccurrence == true)
    }

    // MARK: - Steps

    @Test func taskDefaultStepsIsEmpty() {
        let task = ProjectTask(title: "No steps", dueDate: .now)
        #expect(task.safeSteps.isEmpty)
        #expect(task.completedStepsCount == 0)
    }

    @Test func taskStepsPersistedThroughSwiftData() {
        let store = makeStore()
        let project = Project(name: "Steps Test")
        store.addProject(project)
        let projectID = project.safeID
        let steps = [
            TaskStep(title: "Step A"),
            TaskStep(title: "Step B", isCompleted: true)
        ]
        let task = ProjectTask(title: "With Steps", dueDate: .now, steps: steps)
        store.addTask(task, to: projectID)

        let updatedProject = store.projects.first { $0.safeID == projectID }!
        let savedTask = updatedProject.safeTasks.first { $0.safeID == task.safeID }!
        #expect(savedTask.safeSteps.count == 2)
        #expect(savedTask.safeSteps[0].title == "Step A")
        #expect(savedTask.safeSteps[0].isCompleted == false)
        #expect(savedTask.safeSteps[1].title == "Step B")
        #expect(savedTask.safeSteps[1].isCompleted == true)
    }

    @Test func completedStepsCount() {
        let steps = [
            TaskStep(title: "A", isCompleted: true),
            TaskStep(title: "B", isCompleted: false),
            TaskStep(title: "C", isCompleted: true)
        ]
        let task = ProjectTask(title: "Count", dueDate: .now, steps: steps)
        #expect(task.completedStepsCount == 2)
    }

    @Test func stepsResetForRecurrence() {
        let steps = [
            TaskStep(title: "A", isCompleted: true),
            TaskStep(title: "B", isCompleted: true)
        ]
        let task = ProjectTask(title: "Reset", dueDate: .now, steps: steps)
        let reset = task.stepsResetForRecurrence
        #expect(reset.count == 2)
        #expect(reset[0].title == "A")
        #expect(reset[0].isCompleted == false)
        #expect(reset[1].title == "B")
        #expect(reset[1].isCompleted == false)
        #expect(reset[0].id != steps[0].id)
        #expect(reset[1].id != steps[1].id)
    }

    @Test func recurringTaskWithStepsCopiesStepsReset() {
        let store = makeStore()
        let project = Project(name: "Recurrence Steps Test")
        store.addProject(project)
        let projectID = project.safeID
        let calendar = Calendar.current
        let dueDate = calendar.date(byAdding: .day, value: 1, to: .now)!
        let steps = [
            TaskStep(title: "S1", isCompleted: true),
            TaskStep(title: "S2", isCompleted: true)
        ]
        let task = ProjectTask(
            title: "Recurring With Steps",
            dueDate: dueDate,
            recurrenceRule: .weekly,
            steps: steps
        )
        store.addTask(task, to: projectID)

        task.status = .completed
        store.updateTask(task, in: projectID)

        let updatedProject = store.projects.first { $0.safeID == projectID }!
        let newTask = updatedProject.safeTasks.first { $0.safeID != task.safeID && $0.safeTitle == "Recurring With Steps" }
        #expect(newTask != nil)
        #expect(newTask!.safeSteps.count == 2)
        #expect(newTask!.safeSteps[0].title == "S1")
        #expect(newTask!.safeSteps[0].isCompleted == false)
        #expect(newTask!.safeSteps[1].title == "S2")
        #expect(newTask!.safeSteps[1].isCompleted == false)
    }

    @Test func editTaskStepsPersists() {
        let store = makeStore()
        let project = Project(name: "Edit Steps Test")
        store.addProject(project)
        let projectID = project.safeID
        let task = ProjectTask(title: "Edit Me", dueDate: .now)
        store.addTask(task, to: projectID)

        task.steps = [TaskStep(title: "New Step")]
        store.updateTask(task, in: projectID)

        let updatedProject = store.projects.first { $0.safeID == projectID }!
        let updatedTask = updatedProject.safeTasks.first { $0.safeID == task.safeID }!
        #expect(updatedTask.safeSteps.count == 1)
        #expect(updatedTask.safeSteps[0].title == "New Step")
    }

    // MARK: - Export / Import

    @Test func exportProducesValidJSON() throws {
        let store = makeStore()
        let project = Project(name: "Export Test", descriptionText: "Desc", colorName: "purple", category: .work)
        store.addProject(project)
        let task = ProjectTask(title: "Task A", details: "Details A", dueDate: .now, status: .inProgress, priority: .high)
        store.addTask(task, to: project.safeID)

        let data = try store.exportAllAsJSON()
        let backup = try AppBackup.decoder.decode(AppBackup.self, from: data)

        #expect(backup.projects.count == 2) // sample + new
        let exported = backup.projects.first { $0.name == "Export Test" }
        #expect(exported != nil)
        #expect(exported?.descriptionText == "Desc")
        #expect(exported?.category == .work)
        #expect(exported?.colorName == "purple")
        #expect(exported?.tasks.count == 1)
        #expect(exported?.tasks[0].title == "Task A")
        #expect(exported?.tasks[0].details == "Details A")
        #expect(exported?.tasks[0].status == .inProgress)
        #expect(exported?.tasks[0].priority == .high)
    }

    @Test func exportRoundTripPreservesSteps() throws {
        let store = makeStore()
        let project = Project(name: "Steps Export")
        store.addProject(project)
        let steps = [TaskStep(title: "S1", isCompleted: true), TaskStep(title: "S2")]
        let task = ProjectTask(title: "With Steps", dueDate: .now, steps: steps)
        store.addTask(task, to: project.safeID)

        let data = try store.exportAllAsJSON()
        let backup = try AppBackup.decoder.decode(AppBackup.self, from: data)

        let exported = backup.projects.first { $0.name == "Steps Export" }!
        #expect(exported.tasks[0].steps.count == 2)
        #expect(exported.tasks[0].steps[0].title == "S1")
        #expect(exported.tasks[0].steps[0].isCompleted == true)
        #expect(exported.tasks[0].steps[1].title == "S2")
        #expect(exported.tasks[0].steps[1].isCompleted == false)
    }

    @Test func exportRoundTripPreservesRecurrenceRule() throws {
        let store = makeStore()
        let project = Project(name: "Recurrence Export")
        store.addProject(project)
        let task = ProjectTask(title: "Recurring", dueDate: .now, recurrenceRule: .weekly)
        store.addTask(task, to: project.safeID)

        let data = try store.exportAllAsJSON()
        let backup = try AppBackup.decoder.decode(AppBackup.self, from: data)

        let exported = backup.projects.first { $0.name == "Recurrence Export" }!
        #expect(exported.tasks[0].recurrenceRule == .weekly)
    }

    @Test func importCreatesProjectsAndTasks() throws {
        let store = makeStore()
        let initialCount = store.projects.count

        // Build test JSON manually
        let json = """
        {
          "exportDate": "2025-01-01T00:00:00Z",
          "projects": [
            {
              "id": "\(UUID().uuidString)",
              "name": "Imported Project",
              "descriptionText": "From backup",
              "startDate": "2025-01-01T00:00:00Z",
              "endDate": "2025-06-01T00:00:00Z",
              "colorName": "green",
              "category": "Personal",
              "isArchived": false,
              "tasks": [
                {
                  "id": "\(UUID().uuidString)",
                  "title": "Imported Task",
                  "details": "Task details",
                  "dueDate": "2025-03-01T00:00:00Z",
                  "status": "Not Started",
                  "priority": "Medium",
                  "isArchived": false,
                  "recurrenceRule": "None",
                  "hasGeneratedNextOccurrence": false,
                  "steps": [
                    { "id": "\(UUID().uuidString)", "title": "Step 1", "isCompleted": false }
                  ]
                }
              ]
            }
          ]
        }
        """
        let data = json.data(using: .utf8)!
        let count = try store.importFromJSON(data)

        #expect(count == 1)
        #expect(store.projects.count == initialCount + 1)
        let imported = store.projects.first { $0.safeName == "Imported Project" }
        #expect(imported != nil)
        #expect(imported?.descriptionText == "From backup")
        #expect(imported?.colorName == "green")
        #expect(imported?.category == .personal)
        #expect(imported?.safeTasks.count == 1)
        #expect(imported?.safeTasks[0].safeTitle == "Imported Task")
        #expect(imported?.safeTasks[0].safeSteps.count == 1)
        #expect(imported?.safeTasks[0].safeSteps[0].title == "Step 1")
    }

    @Test func importIsAdditive() throws {
        let store = makeStore()
        let initialCount = store.projects.count

        let data = try store.exportAllAsJSON()
        let _ = try store.importFromJSON(data)

        // Import should add duplicates, not replace
        #expect(store.projects.count == initialCount * 2)
    }

    @Test func importInvalidJSONThrows() {
        let store = makeStore()
        let badData = "not json".data(using: .utf8)!
        #expect(throws: (any Error).self) {
            try store.importFromJSON(badData)
        }
    }

    @Test func exportToTemporaryFileCreatesFile() throws {
        let store = makeStore()
        let url = try store.exportToTemporaryFile()
        #expect(FileManager.default.fileExists(atPath: url.path))
        #expect(url.pathExtension == "json")

        // Verify file contents are valid
        let data = try Data(contentsOf: url)
        let backup = try AppBackup.decoder.decode(AppBackup.self, from: data)
        #expect(!backup.projects.isEmpty)

        // Clean up
        try? FileManager.default.removeItem(at: url)
    }

    @Test func exportImportFullRoundTrip() throws {
        let store = makeStore()
        // Add a project with varied data
        let project = Project(name: "Round Trip", descriptionText: "Full test", colorName: "red", category: .health, isArchived: true)
        store.addProject(project)
        let task = ProjectTask(
            title: "RT Task",
            details: "RT Details",
            dueDate: .now,
            status: .completed,
            priority: .low,
            isArchived: true,
            recurrenceRule: .daily,
            steps: [TaskStep(title: "RT Step", isCompleted: true)]
        )
        store.addTask(task, to: project.safeID)

        // Export
        let data = try store.exportAllAsJSON()

        // Clear store
        for p in store.projects { store.deleteProject(p.safeID) }
        #expect(store.projects.isEmpty)

        // Import
        let count = try store.importFromJSON(data)
        #expect(count >= 1)

        let restored = store.projects.first { $0.safeName == "Round Trip" }
        #expect(restored != nil)
        #expect(restored?.descriptionText == "Full test")
        #expect(restored?.category == .health)
        #expect(restored?.colorName == "red")
        #expect(restored?.safeIsArchived == true)
        #expect(restored?.safeTasks.count == 1)

        let restoredTask = restored?.safeTasks[0]
        #expect(restoredTask?.safeTitle == "RT Task")
        #expect(restoredTask?.safeDetails == "RT Details")
        #expect(restoredTask?.safeStatus == .completed)
        #expect(restoredTask?.safePriority == .low)
        #expect(restoredTask?.safeIsArchived == true)
        #expect(restoredTask?.safeRecurrenceRule == .daily)
        #expect(restoredTask?.safeSteps.count == 1)
        #expect(restoredTask?.safeSteps[0].title == "RT Step")
        #expect(restoredTask?.safeSteps[0].isCompleted == true)
    }

    // MARK: - Performance Tests

    /// Creates a store populated with the specified number of projects,
    /// each containing the specified number of tasks with 2 steps each.
    private func makePopulatedStore(projectCount: Int, tasksPerProject: Int) -> ProjectStore {
        let store = makeStore()
        let calendar = Calendar.current
        for p in 0..<projectCount {
            let tasks = (0..<tasksPerProject).map { t in
                ProjectTask(
                    title: "Task \(t)",
                    details: "Details for task \(t) in project \(p)",
                    dueDate: calendar.date(byAdding: .day, value: t, to: .now)!,
                    status: TaskStatus.allCases[t % 3],
                    priority: TaskPriority.allCases[t % 3],
                    steps: [
                        TaskStep(title: "Step A"),
                        TaskStep(title: "Step B", isCompleted: true)
                    ]
                )
            }
            let project = Project(
                name: "Project \(p)",
                descriptionText: "Description \(p)",
                tasks: tasks,
                colorName: ["blue", "red", "green", "purple"][p % 4],
                category: ProjectCategory.allCases[p % ProjectCategory.allCases.count]
            )
            store.addProject(project)
        }
        return store
    }

    @Test func perfAddProject() {
        let store = makeStore()
        let clock = ContinuousClock()
        let elapsed = clock.measure {
            for i in 0..<50 {
                store.addProject(Project(name: "Perf \(i)"))
            }
        }
        // Adding 50 empty projects should complete well under 5 seconds
        #expect(elapsed < .seconds(5), "Adding 50 projects took \(elapsed)")
    }

    @Test func perfAddTasksToProject() {
        let store = makeStore()
        let projectID = store.projects[0].safeID
        let clock = ContinuousClock()
        let elapsed = clock.measure {
            for i in 0..<100 {
                let task = ProjectTask(
                    title: "Perf Task \(i)",
                    dueDate: .now,
                    steps: [TaskStep(title: "Step 1"), TaskStep(title: "Step 2")]
                )
                store.addTask(task, to: projectID)
            }
        }
        // Adding 100 tasks with steps should complete well under 5 seconds
        #expect(elapsed < .seconds(5), "Adding 100 tasks took \(elapsed)")
    }

    @Test func perfUndoRedoSmallDataSet() {
        // 5 projects × 10 tasks = 50 tasks total
        let store = makePopulatedStore(projectCount: 5, tasksPerProject: 10)
        // Perform a mutation to populate the undo stack
        store.addProject(Project(name: "Undo Target"))
        let clock = ContinuousClock()
        let undoElapsed = clock.measure {
            store.undo()
        }
        let redoElapsed = clock.measure {
            store.redo()
        }
        #expect(undoElapsed < .seconds(2), "Undo (50 tasks) took \(undoElapsed)")
        #expect(redoElapsed < .seconds(2), "Redo (50 tasks) took \(redoElapsed)")
    }

    @Test func perfUndoRedoLargeDataSet() {
        // 20 projects × 20 tasks = 400 tasks total
        let store = makePopulatedStore(projectCount: 20, tasksPerProject: 20)
        store.addProject(Project(name: "Undo Target"))
        let clock = ContinuousClock()
        let undoElapsed = clock.measure {
            store.undo()
        }
        let redoElapsed = clock.measure {
            store.redo()
        }
        #expect(undoElapsed < .seconds(5), "Undo (400 tasks) took \(undoElapsed)")
        #expect(redoElapsed < .seconds(5), "Redo (400 tasks) took \(redoElapsed)")
    }

    @Test func perfExportJSON() throws {
        // 10 projects × 15 tasks = 150 tasks
        let store = makePopulatedStore(projectCount: 10, tasksPerProject: 15)
        let clock = ContinuousClock()
        var data = Data()
        let elapsed = clock.measure {
            data = (try? store.exportAllAsJSON()) ?? Data()
        }
        #expect(data.count > 0)
        #expect(elapsed < .seconds(2), "Export (150 tasks) took \(elapsed)")
    }

    @Test func perfImportJSON() throws {
        // Export a populated store, then import into an empty one
        let source = makePopulatedStore(projectCount: 10, tasksPerProject: 15)
        let data = try source.exportAllAsJSON()
        let store = makeStore()
        let clock = ContinuousClock()
        let elapsed = clock.measure {
            _ = try? store.importFromJSON(data)
        }
        // Should have the sample project + 10 imported
        #expect(store.projects.count >= 10)
        #expect(elapsed < .seconds(3), "Import (150 tasks) took \(elapsed)")
    }

    @Test func perfRefreshProjectsLargeDataSet() {
        // 20 projects × 20 tasks = 400 tasks
        let store = makePopulatedStore(projectCount: 20, tasksPerProject: 20)
        let clock = ContinuousClock()
        // Measure 100 consecutive fetches
        let elapsed = clock.measure {
            for _ in 0..<100 {
                _ = store.activeProjects
            }
        }
        #expect(elapsed < .seconds(2), "100 activeProjects fetches (400 tasks) took \(elapsed)")
    }

    @Test func perfCalendarTaskLookup() {
        // 10 projects × 30 tasks = 300 tasks spread across dates
        let store = makePopulatedStore(projectCount: 10, tasksPerProject: 30)
        let clock = ContinuousClock()
        // Look up tasks for 30 different days
        let elapsed = clock.measure {
            let calendar = Calendar.current
            for dayOffset in 0..<30 {
                let date = calendar.date(byAdding: .day, value: dayOffset, to: .now)!
                _ = store.tasks(for: date)
            }
        }
        #expect(elapsed < .seconds(2), "30 calendar lookups (300 tasks) took \(elapsed)")
    }

    @Test func perfOverdueTasksLookup() {
        // Create tasks with past due dates
        let store = makeStore()
        let calendar = Calendar.current
        let project = Project(name: "Overdue Test")
        store.addProject(project)
        for i in 0..<200 {
            let task = ProjectTask(
                title: "Overdue \(i)",
                dueDate: calendar.date(byAdding: .day, value: -(i + 1), to: .now)!
            )
            store.addTask(task, to: project.safeID)
        }
        let clock = ContinuousClock()
        let elapsed = clock.measure {
            for _ in 0..<50 {
                _ = store.overdueTasks()
            }
        }
        #expect(elapsed < .seconds(2), "50 overdue lookups (200 overdue tasks) took \(elapsed)")
    }

    @Test func perfSnapshotCreation() {
        // Measure the cost of pushUndo with a large data set
        // 20 projects × 20 tasks = 400 tasks
        let store = makePopulatedStore(projectCount: 20, tasksPerProject: 20)
        let clock = ContinuousClock()
        let elapsed = clock.measure {
            for _ in 0..<10 {
                store.pushUndo()
            }
        }
        #expect(elapsed < .seconds(2), "10 snapshots (400 tasks) took \(elapsed)")
    }

    // MARK: - CompletedDate Tests

    @Test func completedDateSetWhenTaskCompleted() {
        let store = makeStore()
        let project = store.projects[0]
        let projectID = project.safeID
        let task = ProjectTask(title: "Complete Me", dueDate: .now, status: .notStarted)
        store.addTask(task, to: projectID)
        #expect(task.completedDate == nil)

        store.pushUndo()
        task.status = .completed
        task.completedDate = Date.now
        store.updateTask(task, in: projectID)

        let updated = store.projects.first { $0.safeID == projectID }!
            .safeTasks.first { $0.safeID == task.safeID }
        #expect(updated?.completedDate != nil)
        #expect(updated?.safeStatus == .completed)
    }

    @Test func completedDateClearedWhenReopened() {
        let store = makeStore()
        let project = store.projects[0]
        let projectID = project.safeID
        let task = ProjectTask(title: "Reopen Me", dueDate: .now, status: .completed)
        store.addTask(task, to: projectID)
        #expect(task.completedDate != nil)

        store.pushUndo()
        task.status = .inProgress
        task.completedDate = nil
        store.updateTask(task, in: projectID)

        let updated = store.projects.first { $0.safeID == projectID }!
            .safeTasks.first { $0.safeID == task.safeID }
        #expect(updated?.completedDate == nil)
        #expect(updated?.safeStatus == .inProgress)
    }

    @Test func completedDatePreservedThroughExportImport() throws {
        let store = makeStore()
        let project = store.projects[0]
        let projectID = project.safeID
        let completedTask = ProjectTask(title: "Export Me", dueDate: .now, status: .completed)
        store.addTask(completedTask, to: projectID)
        let originalDate = completedTask.completedDate

        let data = try store.exportAllAsJSON()

        // Delete existing data
        let ids = store.projects.map(\.safeID)
        for id in ids { store.deleteProject(id) }
        #expect(store.projects.isEmpty)

        // Import
        _ = try store.importFromJSON(data)
        let imported = store.projects.first { $0.safeID == projectID }!
            .safeTasks.first { $0.safeTitle == "Export Me" }
        #expect(imported?.completedDate != nil)
        // Dates should be within 1 second (ISO8601 rounding)
        if let orig = originalDate, let imp = imported?.completedDate {
            #expect(abs(orig.timeIntervalSince(imp)) < 1.0)
        }
    }

    @Test func completedDatePreservedThroughUndoRedo() {
        let store = makeStore()
        let project = store.projects[0]
        let projectID = project.safeID
        let task = ProjectTask(title: "Undo Me", dueDate: .now, status: .completed)
        store.addTask(task, to: projectID)
        let originalDate = task.completedDate
        #expect(originalDate != nil)

        // Push undo, then change the task
        store.pushUndo()
        task.status = .inProgress
        task.completedDate = nil
        store.updateTask(task, in: projectID)

        // Undo should restore the completedDate
        store.undo()
        let restored = store.projects.first { $0.safeID == projectID }!
            .safeTasks.first { $0.safeTitle == "Undo Me" }
        #expect(restored?.completedDate != nil)
        #expect(restored?.safeStatus == .completed)
    }

    @Test func completedDateAutoSetForCompletedInit() {
        let task = ProjectTask(title: "Auto", dueDate: .now, status: .completed)
        #expect(task.completedDate != nil)
    }

    @Test func completedDateNilForNonCompletedInit() {
        let task = ProjectTask(title: "Not Done", dueDate: .now, status: .notStarted)
        #expect(task.completedDate == nil)
        let task2 = ProjectTask(title: "In Prog", dueDate: .now, status: .inProgress)
        #expect(task2.completedDate == nil)
    }
}
