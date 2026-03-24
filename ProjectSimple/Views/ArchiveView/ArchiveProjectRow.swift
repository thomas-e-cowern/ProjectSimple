import SwiftUI

struct ArchiveView: View {
    @Environment(ProjectStore.self) private var store
    @State private var selectedSection: ArchiveSection = .archived

    enum ArchiveSection: String, CaseIterable {
        case archived = "Archived"
        case completed = "Completed"
    }

    var body: some View {
        // Read refreshToken to re-evaluate when data changes via sync.
        let _ = store.refreshToken
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Section", selection: $selectedSection) {
                    ForEach(ArchiveSection.allCases, id: \.self) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .accessibilityLabel("Archive section")
                .accessibilityHint("Switch between archived and completed items")

                Group {
                    switch selectedSection {
                    case .archived:
                        archivedContent
                    case .completed:
                        completedContent
                    }
                }
            }
            .navigationTitle("Archive")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
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
            }
        }
    }

    // MARK: - Archived Content

    @ViewBuilder
    private var archivedContent: some View {
        let archivedProjects = store.archivedProjects
        let projectsWithArchivedTasks = store.activeProjects.filter { project in
            project.safeTasks.contains { $0.safeIsArchived }
        }

        if archivedProjects.isEmpty && projectsWithArchivedTasks.isEmpty {
            ContentUnavailableView {
                Label("No Archived Items", systemImage: "archivebox")
            } description: {
                Text("Swipe left on projects or tasks to archive them.")
            }
        } else {
            List {
                if !archivedProjects.isEmpty {
                    Section("Archived Projects") {
                        ForEach(archivedProjects) { project in
                            ArchivedProjectRow(project: project)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        store.deleteProject(project.safeID)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        store.unarchiveProject(project.safeID)
                                    } label: {
                                        Label("Unarchive", systemImage: "arrow.uturn.backward")
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                }

                ForEach(projectsWithArchivedTasks) { project in
                    Section("Archived Tasks — \(project.safeName)") {
                        ForEach(project.safeTasks.filter(\.safeIsArchived)) { task in
                            ArchivedTaskRow(task: task, projectName: project.safeName)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        store.deleteTask(task.safeID, from: project.safeID)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        store.unarchiveTask(task.safeID, in: project.safeID)
                                    } label: {
                                        Label("Unarchive", systemImage: "arrow.uturn.backward")
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    // MARK: - Completed Content

    @ViewBuilder
    private var completedContent: some View {
        let fullyCompletedProjects = store.completedProjects
        let projectsWithCompletedTasks = store.activeProjects.filter { project in
            project.activeTasks.contains { $0.safeStatus == .completed }
        }

        if fullyCompletedProjects.isEmpty && projectsWithCompletedTasks.isEmpty {
            ContentUnavailableView {
                Label("No Completed Items", systemImage: "checkmark.circle")
            } description: {
                Text("Completed projects and tasks will appear here.")
            }
        } else {
            List {
                if !fullyCompletedProjects.isEmpty {
                    Section("Completed Projects") {
                        ForEach(fullyCompletedProjects) { project in
                            ArchivedProjectRow(project: project)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button {
                                        store.archiveProject(project.safeID)
                                    } label: {
                                        Label("Archive", systemImage: "archivebox")
                                    }
                                    .tint(.orange)
                                }
                        }
                    }
                }

                ForEach(projectsWithCompletedTasks) { project in
                    Section("Completed Tasks — \(project.safeName)") {
                        ForEach(project.activeTasks.filter { $0.safeStatus == .completed }) { task in
                            ArchivedTaskRow(task: task, projectName: project.safeName)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button {
                                        store.archiveTask(task.safeID, in: project.safeID)
                                    } label: {
                                        Label("Archive", systemImage: "archivebox")
                                    }
                                    .tint(.orange)
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        store.pushUndo()
                                        let updated = task
                                        updated.status = .inProgress
                                        updated.completedDate = nil
                                        store.updateTask(updated, in: project.safeID)
                                    } label: {
                                        Label("Reopen", systemImage: "arrow.uturn.backward")
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

#Preview {
    ArchiveView()
        .environment(ProjectStore.preview())
}
