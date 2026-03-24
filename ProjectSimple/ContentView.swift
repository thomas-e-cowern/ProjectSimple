//
//  ContentView.swift
//  ProjectSimple
//
//  Created by Thomas Cowern on 3/10/26.
//

import SwiftUI

    enum AppTab: String {
        case calendar, projects, search, statistics, archive
    }

struct ContentView: View {
    @Environment(ProjectStore.self) private var store
    @Environment(QuickActionState.self) private var quickActionState
    @State private var showQuickAddProject = false
    @State private var showQuickAddTask = false
    @State private var quickAddTaskProjectID: UUID?
    @State private var selectedTab: AppTab = .calendar

    var body: some View {
        @Bindable var store = store
        // Read refreshToken so every tab re-evaluates when CloudKit
        // data arrives (projects archived, tasks changed, etc.).
        let _ = store.refreshToken

        TabView(selection: $selectedTab) {
            Tab("Calendar", systemImage: "calendar", value: AppTab.calendar) {
                CalendarView()
            }

            Tab("Projects", systemImage: "folder.fill", value: AppTab.projects) {
                ProjectListView()
            }

            Tab("Search", systemImage: "magnifyingglass", value: AppTab.search) {
                SearchView()
            }

            Tab("Statistics", systemImage: "chart.bar.fill", value: AppTab.statistics) {
                StatisticsView()
            }

            Tab("Archive", systemImage: "archivebox", value: AppTab.archive) {
                ArchiveView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .alert("Error", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("OK") {
                store.errorMessage = nil
            }
        } message: {
            Text(store.errorMessage ?? "")
        }
        .sheet(isPresented: $showQuickAddProject) {
            AddProjectView()
        }
        .sheet(isPresented: $showQuickAddTask) {
            if let projectID = quickAddTaskProjectID {
                AddTaskView(projectID: projectID)
            }
        }
        .onChange(of: quickActionState.pendingAction) {
            handleQuickAction()
        }
        .onAppear {
            handleQuickAction()
        }
    }

    private func handleQuickAction() {
        guard let action = quickActionState.pendingAction else { return }
        quickActionState.pendingAction = nil

        switch action {
        case "com.projectsimple.newProject":
            selectedTab = .projects
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showQuickAddProject = true
            }
        case "com.projectsimple.addTask":
            if let projectID = quickActionState.pendingProjectID {
                quickActionState.pendingProjectID = nil
                quickAddTaskProjectID = projectID
                selectedTab = .projects
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showQuickAddTask = true
                }
            }
        case "com.projectsimple.showOverdue":
            selectedTab = .calendar
        default:
            break
        }
    }
}

#Preview {
    ContentView()
        .environment(ProjectStore.preview())
        .environment(QuickActionState())
}
