//
//  ContentView.swift
//  Project​Simple​Watch Watch App
//
//  Created by Thomas Cowern on 3/21/26.
//

import SwiftUI

struct WatchContentView: View {
    @Environment(WatchProjectStore.self) private var store

    var body: some View {
        NavigationStack {
            List {
                overdueSection
                todaySection
                projectsSection
            }
            .navigationTitle("ProjectSimple")
            .refreshable {
                store.refreshProjects()
            }
        }
    }

    // MARK: - Overdue Section

    @ViewBuilder
    private var overdueSection: some View {
        let overdue = store.overdueTasks()
        if !overdue.isEmpty {
            Section {
                ForEach(overdue, id: \.task.safeID) { item in
                    WatchTaskRow(task: item.task, projectName: item.project.safeName)
                }
            } header: {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text("Overdue (\(overdue.count))")
                        .foregroundStyle(.red)
                }
            }
        }
    }

    // MARK: - Today Section

    @ViewBuilder
    private var todaySection: some View {
        let today = store.todayTasks()
        Section {
            if today.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(.green)
                    Text("No tasks due today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(today, id: \.task.safeID) { item in
                    WatchTaskRow(task: item.task, projectName: item.project.safeName)
                }
            }
        } header: {
            Text("Today")
        }
    }

    // MARK: - Projects Section

    @ViewBuilder
    private var projectsSection: some View {
        let projects = store.activeProjects
        if !projects.isEmpty {
            Section {
                ForEach(projects) { project in
                    NavigationLink(destination: WatchProjectDetailView(project: project)) {
                        WatchProjectRow(project: project)
                    }
                }
            } header: {
                Text("Projects")
            }
        }
    }
}
