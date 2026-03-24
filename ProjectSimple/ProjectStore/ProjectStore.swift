import Foundation
import SwiftUI
import SwiftData
import CoreData
import WidgetKit
import Combine

@MainActor
@Observable
class ProjectStore {
    let modelContext: ModelContext
    var notificationManager: NotificationManager?
    private(set) var projects: [Project] = []
    var errorMessage: String?
    private var remoteChangeObserver: AnyCancellable?

    /// Bumped on every remote-change refresh so views that read it
    /// re-evaluate even when the `projects` array identity is unchanged.
    private(set) var refreshToken: Int = 0

    // MARK: - Snapshot-based Undo / Redo

    /// A lightweight snapshot of all projects, used for undo/redo.
    private var undoStack: [[ExportableProject]] = []
    private var redoStack: [[ExportableProject]] = []
    private static let maxUndoLevels = 30

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    /// The live list of projects, excluding any that are mid-deletion.
    private var liveProjects: [Project] {
        projects.filter { $0.isAccessible }
    }

    var activeProjects: [Project] {
        liveProjects.filter { !$0.safeIsArchived }
    }

    var archivedProjects: [Project] {
        liveProjects.filter { $0.safeIsArchived }
    }

    var completedProjects: [Project] {
        liveProjects.filter { !$0.safeIsArchived && $0.completionPercentage == 1.0 }
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        refreshProjects()
        loadSampleDataIfFirstLaunch()
        observeRemoteChanges()
        startSyncPolling()
    }

    /// Listens for CloudKit remote-change notifications so the UI stays
    /// up to date when data arrives from another device.
    private func observeRemoteChanges() {
        remoteChangeObserver = NotificationCenter.default
            .publisher(for: .NSPersistentStoreRemoteChange)
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                print("📡 NSPersistentStoreRemoteChange received")
                self?.refreshAfterRemoteChange()
            }
    }

    /// Polls for CloudKit changes on a timer as a fallback, since
    /// NSPersistentStoreRemoteChange may not always fire reliably.
    private func startSyncPolling() {
        Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                self?.pollForChanges()
            }
        }
    }

    /// The last fingerprint we computed so we can detect changes on the
    /// next poll without creating a separate ModelContext.
    private var lastKnownFingerprint: String = ""

    /// Checks if the store has new data by re-fetching from the main
    /// context and comparing the fingerprint to the last known state.
    private func pollForChanges() {
        // Build a fingerprint from a fresh fetch on the MAIN context.
        // This avoids creating a second ModelContext, which triggers
        // "unsafeForcedSync" warnings from Swift Concurrency.
        let projectDescriptor = FetchDescriptor<Project>()
        let freshProjects = (try? modelContext.fetch(projectDescriptor)) ?? []

        let taskDescriptor = FetchDescriptor<ProjectTask>()
        let freshTasks = (try? modelContext.fetch(taskDescriptor)) ?? []

        let freshFingerprint = buildFingerprint(projects: freshProjects, tasks: freshTasks)

        if freshFingerprint != lastKnownFingerprint {
            if !lastKnownFingerprint.isEmpty {
                print("📡 Poll detected changes")
                refreshAfterRemoteChange()
            }
            lastKnownFingerprint = freshFingerprint
        }
    }

    /// Builds a string fingerprint from fetched data.
    private func buildFingerprint(projects: [Project], tasks: [ProjectTask]) -> String {
        let projectPart = projects
            .filter { !$0.isDeleted }
            .sorted { ($0.id?.uuidString ?? "") < ($1.id?.uuidString ?? "") }
            .map { "\($0.id?.uuidString ?? ""):\($0.name ?? ""):\($0.isArchived ?? false)" }
            .joined(separator: "|")

        let taskPart = tasks
            .filter { !$0.isDeleted }
            .sorted { ($0.id?.uuidString ?? "") < ($1.id?.uuidString ?? "") }
            .map { "\($0.id?.uuidString ?? ""):\($0.status?.rawValue ?? ""):\($0.isArchived ?? false):\($0.title ?? ""):\($0.steps?.count ?? 0)" }
            .joined(separator: "|")

        return "\(projects.count);\(tasks.count);\(projectPart);\(taskPart)"
    }

    /// Forces the context to pick up any pending external changes
    /// (e.g. from CloudKit) and re-fetches the project list.
    func refreshAfterRemoteChange() {
        // Persist any in-flight local edits first.
        try? modelContext.save()
        // Re-fetch from the main context. Do NOT call rollback() — it
        // detaches in-memory objects while SwiftUI views still hold
        // references, causing "backing data was detached" crashes.
        refreshProjects()
        // Update the poll fingerprint so we don't double-trigger.
        let projectDescriptor = FetchDescriptor<Project>()
        let allProjects = (try? modelContext.fetch(projectDescriptor)) ?? []
        let taskDescriptor = FetchDescriptor<ProjectTask>()
        let allTasks = (try? modelContext.fetch(taskDescriptor)) ?? []
        lastKnownFingerprint = buildFingerprint(projects: allProjects, tasks: allTasks)
        // Bump the token so views that read it re-evaluate, even when
        // the same Project objects are returned with different task data.
        refreshToken += 1
        let live = liveProjects
        print("🔄 Refreshed (token \(refreshToken)): \(live.count) projects, \(live.map { $0.safeTasks.count }.reduce(0, +)) total tasks")
    }

    private func refreshProjects() {
        let projectDescriptor = FetchDescriptor<Project>(sortBy: [SortDescriptor(\.name)])
        let fetchedProjects = (try? modelContext.fetch(projectDescriptor)) ?? []

        // Also fetch all tasks so their properties are current in the
        // context — ensures CloudKit changes to task status, steps, etc.
        // are reflected when views access the relationship arrays.
        let taskDescriptor = FetchDescriptor<ProjectTask>()
        _ = try? modelContext.fetch(taskDescriptor)

        // Filter out any deleted objects to prevent SwiftUI from
        // accessing detached backing data.
        projects = fetchedProjects.filter { !$0.isDeleted }
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
        refreshProjects()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Takes a snapshot of the current state before a mutation.
    /// Call this before directly modifying a SwiftData object's properties.
    func pushUndo() {
        let snapshot = projects.map { ExportableProject(from: $0) }
        undoStack.append(snapshot)
        if undoStack.count > Self.maxUndoLevels {
            undoStack.removeFirst()
        }
        redoStack.removeAll()
    }

    /// Replaces all persisted data with the given snapshot.
    private func restore(from snapshot: [ExportableProject]) {
        // Detach tasks from projects by clearing the relationship array,
        // then delete everything. This avoids the "mandatory OTO nullify
        // inverse" batch-delete constraint violation in CoreData.
        for project in projects {
            let tasks = project.tasks ?? []
            project.tasks?.removeAll()
            for task in tasks {
                modelContext.delete(task)
            }
        }
        for project in projects {
            modelContext.delete(project)
        }
        // Re-insert from snapshot
        for exportable in snapshot {
            let project = exportable.toProject()
            modelContext.insert(project)
            for task in project.safeTasks {
                modelContext.insert(task)
            }
        }
        save()
    }

    private func scheduleNotifications() {
        guard let manager = notificationManager else { return }
        let currentProjects = activeProjects
        Task {
            await manager.rescheduleAll(for: currentProjects)
        }
    }

    // MARK: - Undo / Redo

    func undo() {
        guard let snapshot = undoStack.popLast() else { return }
        // Save current state to redo stack before restoring
        let currentSnapshot = projects.map { ExportableProject(from: $0) }
        redoStack.append(currentSnapshot)
        restore(from: snapshot)
        scheduleNotifications()
    }

    func redo() {
        guard let snapshot = redoStack.popLast() else { return }
        // Save current state to undo stack before restoring
        let currentSnapshot = projects.map { ExportableProject(from: $0) }
        undoStack.append(currentSnapshot)
        restore(from: snapshot)
        scheduleNotifications()
    }

    // MARK: - Project Operations

    func addProject(_ project: Project) {
        pushUndo()
        modelContext.insert(project)
        save()
        scheduleNotifications()
    }

    func updateProject(_ project: Project) {
        save()
        scheduleNotifications()
    }

    func deleteProject(at offsets: IndexSet) {
        pushUndo()
        let active = activeProjects
        for index in offsets {
            modelContext.delete(active[index])
        }
        save()
        scheduleNotifications()
    }

    func deleteProject(_ projectID: UUID) {
        if let project = projects.first(where: { $0.safeID == projectID }) {
            pushUndo()
            modelContext.delete(project)
            save()
        }
        scheduleNotifications()
    }

    func archiveProject(_ projectID: UUID) {
        if let project = projects.first(where: { $0.safeID == projectID }) {
            pushUndo()
            project.isArchived = true
            save()
        }
        scheduleNotifications()
    }

    func unarchiveProject(_ projectID: UUID) {
        if let project = projects.first(where: { $0.safeID == projectID }) {
            pushUndo()
            project.isArchived = false
            save()
        }
        scheduleNotifications()
    }

    // MARK: - Task Operations

    func addTask(_ task: ProjectTask, to projectID: UUID) {
        if let project = projects.first(where: { $0.safeID == projectID }) {
            pushUndo()
            modelContext.insert(task)
            if project.tasks == nil { project.tasks = [] }
            project.tasks?.append(task)
            save()
        }
        scheduleNotifications()
    }

    func updateTask(_ task: ProjectTask, in projectID: UUID) {
        generateNextOccurrenceIfNeeded(for: task, in: projectID)
        save()
        scheduleNotifications()
    }

    // MARK: - Recurrence

    private func generateNextOccurrenceIfNeeded(for task: ProjectTask, in projectID: UUID) {
        guard task.safeStatus == .completed,
              task.safeRecurrenceRule != .none,
              !task.safeHasGeneratedNextOccurrence,
              let nextDate = task.safeRecurrenceRule.nextDueDate(from: task.safeDueDate),
              let project = projects.first(where: { $0.safeID == projectID })
        else { return }

        let nextTask = ProjectTask(
            title: task.safeTitle,
            details: task.safeDetails,
            dueDate: nextDate,
            priority: task.safePriority,
            recurrenceRule: task.safeRecurrenceRule,
            steps: task.stepsResetForRecurrence
        )

        task.hasGeneratedNextOccurrence = true
        modelContext.insert(nextTask)
        if project.tasks == nil { project.tasks = [] }
        project.tasks?.append(nextTask)
    }

    func deleteTask(_ taskID: UUID, from projectID: UUID) {
        if let project = projects.first(where: { $0.safeID == projectID }),
           let task = project.safeTasks.first(where: { $0.safeID == taskID }) {
            pushUndo()
            modelContext.delete(task)
            save()
        }
        scheduleNotifications()
    }

    func archiveTask(_ taskID: UUID, in projectID: UUID) {
        if let project = projects.first(where: { $0.safeID == projectID }),
           let task = project.safeTasks.first(where: { $0.safeID == taskID }) {
            pushUndo()
            task.isArchived = true
            save()
        }
        scheduleNotifications()
    }

    func unarchiveTask(_ taskID: UUID, in projectID: UUID) {
        if let project = projects.first(where: { $0.safeID == projectID }),
           let task = project.safeTasks.first(where: { $0.safeID == taskID }) {
            pushUndo()
            task.isArchived = false
            save()
        }
        scheduleNotifications()
    }

    // MARK: - Calendar Helpers

    func tasks(for date: Date) -> [(project: Project, task: ProjectTask)] {
        let calendar = Calendar.current
        var results: [(project: Project, task: ProjectTask)] = []
        for project in activeProjects {
            for task in project.activeTasks {
                if calendar.isDate(task.safeDueDate, inSameDayAs: date) && task.safeStatus != .completed {
                    results.append((project: project, task: task))
                }
            }
        }
        return results
    }

    func overdueTasks() -> [(project: Project, task: ProjectTask)] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)
        var results: [(project: Project, task: ProjectTask)] = []
        for project in activeProjects {
            for task in project.activeTasks {
                if task.safeStatus != .completed && task.safeDueDate < startOfToday {
                    results.append((project: project, task: task))
                }
            }
        }
        return results.sorted { $0.task.safeDueDate < $1.task.safeDueDate }
    }

    func allTasks() -> [(project: Project, task: ProjectTask)] {
        var results: [(project: Project, task: ProjectTask)] = []
        for project in activeProjects {
            for task in project.activeTasks {
                results.append((project: project, task: task))
            }
        }
        return results
    }

    // MARK: - Export / Import

    func exportAllAsJSON() throws -> Data {
        let backup = AppBackup(projects: projects)
        return try AppBackup.encoder.encode(backup)
    }

    func exportToTemporaryFile() throws -> URL {
        let data = try exportAllAsJSON()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: .now)
        let fileName = "ProjectSimple_Backup_\(dateString).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: url)
        return url
    }

    func importFromJSON(_ data: Data) throws -> Int {
        let backup = try AppBackup.decoder.decode(AppBackup.self, from: data)
        var importedCount = 0
        for exportableProject in backup.projects {
            let project = exportableProject.toProject()
            modelContext.insert(project)
            for task in project.safeTasks {
                modelContext.insert(task)
            }
            importedCount += 1
        }
        save()
        // Clear undo/redo stacks — import is not undoable
        undoStack.removeAll()
        redoStack.removeAll()
        scheduleNotifications()
        return importedCount
    }

    // MARK: - Preview Helper

    static func preview() -> ProjectStore {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Project.self, ProjectTask.self, configurations: config)
        return ProjectStore(modelContext: container.mainContext)
    }

    // MARK: - Sample Data

    /// Loads sample data on the very first launch. Uses a UserDefaults
    /// flag so it only runs once per install. Safe with CloudKit because
    /// it never deletes anything — it only inserts when the store is empty.
    private func loadSampleDataIfFirstLaunch() {
        let key = "hasLoadedSampleData"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        let descriptor = FetchDescriptor<Project>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard count == 0 else {
            // Data already exists (e.g. synced from CloudKit), mark as done.
            UserDefaults.standard.set(true, forKey: key)
            return
        }

        loadSampleData()
        UserDefaults.standard.set(true, forKey: key)
    }

    func loadSampleData() {
        let calendar = Calendar.current
        let today = Date.now

        let gettingStartedTasks = [
            ProjectTask(
                title: "Explore this project",
                details: "Tap this project to see its tasks. You're looking at one now! Each task has a status, priority, and due date.",
                dueDate: calendar.date(byAdding: .day, value: 1, to: today)!,
                status: .inProgress,
                priority: .high
            ),
            ProjectTask(
                title: "Mark a task complete",
                details: "Open any task and change its status to Completed. Try it with the 'Explore this project' task once you're done reading it.",
                dueDate: calendar.date(byAdding: .day, value: 2, to: today)!,
                status: .notStarted,
                priority: .high
            ),
            ProjectTask(
                title: "Add your own task",
                details: "Tap the + button at the top of the project to add a new task. Give it a title, due date, and priority.",
                dueDate: calendar.date(byAdding: .day, value: 3, to: today)!,
                status: .notStarted,
                priority: .medium
            ),
            ProjectTask(
                title: "Try the Search tab",
                details: "Switch to the Search tab to find tasks across all projects. You can filter by priority and category using the filter button.",
                dueDate: calendar.date(byAdding: .day, value: 4, to: today)!,
                status: .notStarted,
                priority: .medium
            ),
            ProjectTask(
                title: "Check the Calendar tab",
                details: "The Calendar tab shows tasks by due date. Tap any date to see what's due. Overdue tasks appear at the top.",
                dueDate: calendar.date(byAdding: .day, value: 5, to: today)!,
                status: .notStarted,
                priority: .low
            ),
            ProjectTask(
                title: "Create your first project",
                details: "Go back to the Projects tab and tap + to create a new project. Choose a name, color, category, and date range. Once you're comfortable, feel free to delete this Getting Started project.",
                dueDate: calendar.date(byAdding: .day, value: 7, to: today)!,
                status: .notStarted,
                priority: .low
            ),
        ]

        let gettingStarted = Project(
            name: "Getting Started",
            descriptionText: "Welcome! This project walks you through the basics of the app. Complete each task to learn how things work.",
            startDate: today,
            endDate: calendar.date(byAdding: .month, value: 1, to: today)!,
            tasks: gettingStartedTasks,
            colorName: "blue",
            category: .personal
        )

        modelContext.insert(gettingStarted)
        for task in gettingStartedTasks {
            modelContext.insert(task)
        }
        save()
    }
}
