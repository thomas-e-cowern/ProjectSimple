import SwiftUI
import UniformTypeIdentifiers

struct ProjectListView: View {
    @Environment(ProjectStore.self) private var store
    @State private var showAddProject = false
    @State private var projectToEdit: Project?
    @State private var projectToDelete: Project?
    @State private var selectedProjectID: UUID?
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @State private var showFileImporter = false
    @State private var importResultMessage: String?
    @State private var showImportResult = false

    var body: some View {
        // Read refreshToken to re-evaluate when data changes via sync.
        let _ = store.refreshToken
        NavigationSplitView {
            Group {
                if store.activeProjects.isEmpty {
                    ContentUnavailableView {
                        Label("No Projects", systemImage: "folder")
                    } description: {
                        Text("Tap + to create your first project.")
                    } actions: {
                        Button("Load Sample Project") {
                            store.loadSampleData()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List(selection: $selectedProjectID) {
                        ForEach(store.activeProjects) { project in
                            NavigationLink(value: project.safeID) {
                                ProjectRow(project: project)
                            }
                            .rowSwipeActions(onDelete: {
                                projectToDelete = project
                            }, onArchive: {
                                store.archiveProject(project.safeID)
                            }, onEdit: {
                                projectToEdit = project
                            })
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            exportData()
                        } label: {
                            Label("Export Data", systemImage: "square.and.arrow.up")
                        }
                        Button {
                            showFileImporter = true
                        } label: {
                            Label("Import Data", systemImage: "square.and.arrow.down")
                        }
                        Divider()
                        Button {
                            showUserGuide()
                        } label: {
                            Label("User Guide", systemImage: "book")
                        }
                        Divider()
                        Toggle(isOn: $hapticsEnabled) {
                            Label("Haptic Feedback", systemImage: "hand.tap")
                        }
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
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

                    Button {
                        showAddProject = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add project")
                }
            }
            .sheet(isPresented: $showAddProject) {
                AddProjectView()
            }
            .sheet(item: $projectToEdit) { project in
                EditProjectView(project: project)
            }
            .alert("Delete Project", isPresented: Binding(
                get: { projectToDelete != nil },
                set: { if !$0 { projectToDelete = nil } }
            )) {
                Button("Cancel", role: .cancel) {
                    projectToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let project = projectToDelete {
                        store.deleteProject(project.safeID)
                    }
                    projectToDelete = nil
                }
            } message: {
                Text("Are you sure you want to permanently delete this project and all its tasks?")
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [UTType.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .alert("Import", isPresented: $showImportResult) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(importResultMessage ?? "")
            }
        } detail: {
            if let selectedProjectID,
               let project = store.projects.first(where: { $0.safeID == selectedProjectID }) {
                ProjectDetailView(project: project)
            } else {
                ContentUnavailableView {
                    Label("No Project Selected", systemImage: "folder")
                } description: {
                    Text("Select a project from the sidebar.")
                }
            }
        }
    }

    private func exportData() {
        do {
            let fileURL = try store.exportToTemporaryFile()
            let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.keyWindow?.rootViewController {
                var presenter = rootVC
                while let presented = presenter.presentedViewController {
                    presenter = presented
                }
                activityVC.popoverPresentationController?.sourceView = presenter.view
                activityVC.popoverPresentationController?.sourceRect = CGRect(x: presenter.view.bounds.midX, y: 0, width: 0, height: 0)
                activityVC.popoverPresentationController?.permittedArrowDirections = .up
                presenter.present(activityVC, animated: true)
            }
        } catch {
            importResultMessage = "Export failed: \(error.localizedDescription)"
            showImportResult = true
        }
    }

    private func showUserGuide() {
        let generator = UserGuidePDFGenerator()
        let data = generator.generate()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ProjectSimple_User_Guide.pdf")
        try? data.write(to: url)

        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.keyWindow?.rootViewController {
            var presenter = rootVC
            while let presented = presenter.presentedViewController {
                presenter = presented
            }
            activityVC.popoverPresentationController?.sourceView = presenter.view
            activityVC.popoverPresentationController?.sourceRect = CGRect(x: presenter.view.bounds.midX, y: 0, width: 0, height: 0)
            activityVC.popoverPresentationController?.permittedArrowDirections = .up
            presenter.present(activityVC, animated: true)
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing { url.stopAccessingSecurityScopedResource() }
            }
            do {
                let data = try Data(contentsOf: url)
                let count = try store.importFromJSON(data)
                importResultMessage = "Successfully imported \(count) project\(count == 1 ? "" : "s")."
            } catch {
                importResultMessage = "Import failed: \(error.localizedDescription)"
            }
            showImportResult = true
        case .failure(let error):
            importResultMessage = "Could not open file: \(error.localizedDescription)"
            showImportResult = true
        }
    }
}



#Preview {
    ProjectListView()
        .environment(ProjectStore.preview())
}
