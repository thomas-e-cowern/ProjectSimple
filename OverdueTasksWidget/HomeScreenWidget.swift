import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Timeline Entry

struct HomeScreenEntry: TimelineEntry {
    let date: Date
    let overdueCount: Int
    let todayTasks: [TaskSnippet]
    let totalActiveCount: Int
}

struct TaskSnippet: Identifiable {
    let id: UUID
    let title: String
    let priorityColor: String
    let isOverdue: Bool
    let projectName: String
}

// MARK: - Timeline Provider

struct HomeScreenProvider: TimelineProvider {
    func placeholder(in context: Context) -> HomeScreenEntry {
        HomeScreenEntry(
            date: .now,
            overdueCount: 2,
            todayTasks: [
                TaskSnippet(id: UUID(), title: "Review proposal", priorityColor: "red", isOverdue: true, projectName: "Work"),
                TaskSnippet(id: UUID(), title: "Update docs", priorityColor: "orange", isOverdue: false, projectName: "Personal"),
                TaskSnippet(id: UUID(), title: "Send invoice", priorityColor: "green", isOverdue: false, projectName: "Finance")
            ],
            totalActiveCount: 8
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (HomeScreenEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
        } else {
            completion(fetchTasks())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HomeScreenEntry>) -> Void) {
        let entry = fetchTasks()

        // Refresh at midnight when new tasks may become overdue
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: .now)!)

        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }

    private func fetchTasks() -> HomeScreenEntry {
        do {
            let container = try SharedModelContainer.createForWidget()
            let context = ModelContext(container)

            let descriptor = FetchDescriptor<Project>(
                predicate: #Predicate<Project> { $0.isArchived != true }
            )
            let projects = (try? context.fetch(descriptor)) ?? []

            let calendar = Calendar.current
            let startOfToday = calendar.startOfDay(for: .now)
            let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

            var overdueTasks: [TaskSnippet] = []
            var todayTasks: [TaskSnippet] = []
            var totalActive = 0

            for project in projects {
                for task in project.activeTasks where task.safeStatus != .completed {
                    totalActive += 1

                    if task.safeDueDate < startOfToday {
                        overdueTasks.append(TaskSnippet(
                            id: task.safeID,
                            title: task.safeTitle,
                            priorityColor: task.safePriority.color,
                            isOverdue: true,
                            projectName: project.safeName
                        ))
                    } else if task.safeDueDate >= startOfToday && task.safeDueDate < endOfToday {
                        todayTasks.append(TaskSnippet(
                            id: task.safeID,
                            title: task.safeTitle,
                            priorityColor: task.safePriority.color,
                            isOverdue: false,
                            projectName: project.safeName
                        ))
                    }
                }
            }

            // Sort overdue by priority color (red first), then today tasks
            overdueTasks.sort { prioritySortOrder($0.priorityColor) < prioritySortOrder($1.priorityColor) }
            todayTasks.sort { prioritySortOrder($0.priorityColor) < prioritySortOrder($1.priorityColor) }

            // Combine: overdue first, then today's tasks
            let combined = overdueTasks + todayTasks

            return HomeScreenEntry(
                date: .now,
                overdueCount: overdueTasks.count,
                todayTasks: combined,
                totalActiveCount: totalActive
            )
        } catch {
            return HomeScreenEntry(date: .now, overdueCount: 0, todayTasks: [], totalActiveCount: 0)
        }
    }

    private func prioritySortOrder(_ color: String) -> Int {
        switch color {
        case "red": return 0
        case "orange": return 1
        case "green": return 2
        default: return 3
        }
    }
}

// MARK: - Small Widget View

struct HomeScreenSmallView: View {
    let entry: HomeScreenEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack {
                Image(systemName: "checklist.unchecked")
                    .font(.caption)
                    .foregroundStyle(.blue)
                Text("ProjectSimple")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if entry.todayTasks.isEmpty {
                Spacer()
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle")
                        .font(.title2)
                        .foregroundStyle(.green)
                    Text("All caught up!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                // Overdue badge
                if entry.overdueCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(.red)
                        Text("\(entry.overdueCount) overdue")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.red)
                    }
                }

                // Task list (up to 3 items)
                ForEach(Array(entry.todayTasks.prefix(3))) { task in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(taskColor(task.priorityColor)))
                            .frame(width: 6, height: 6)
                        Text(task.title)
                            .font(.caption2)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)

                // Footer count
                if entry.totalActiveCount > 3 {
                    Text("\(entry.totalActiveCount) active tasks")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func taskColor(_ colorName: String) -> Color {
        switch colorName {
        case "red": return .red
        case "orange": return .orange
        case "green": return .green
        default: return .blue
        }
    }
}

// MARK: - Medium Widget View

struct HomeScreenMediumView: View {
    let entry: HomeScreenEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header row
            HStack {
                Image(systemName: "checklist.unchecked")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                Text("ProjectSimple")
                    .font(.subheadline.weight(.semibold))

                Spacer()

                if entry.overdueCount > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                        Text("\(entry.overdueCount) overdue")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(.red)
                }

                Text("\(entry.totalActiveCount) active")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Divider()

            if entry.todayTasks.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                            .font(.title3)
                            .foregroundStyle(.green)
                        Text("No tasks due today — you're all caught up!")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                // Task rows (up to 4)
                ForEach(Array(entry.todayTasks.prefix(4))) { task in
                    HomeScreenTaskRow(task: task)
                }

                Spacer(minLength: 0)

                if entry.todayTasks.count > 4 {
                    Text("+\(entry.todayTasks.count - 4) more")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct HomeScreenTaskRow: View {
    let task: TaskSnippet

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(taskColor(task.priorityColor))
                .frame(width: 8, height: 8)

            Text(task.title)
                .font(.caption)
                .lineLimit(1)

            Spacer()

            if task.isOverdue {
                Text("OVERDUE")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(.red, in: Capsule())
            }

            Text(task.projectName)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private func taskColor(_ colorName: String) -> Color {
        switch colorName {
        case "red": return .red
        case "orange": return .orange
        case "green": return .green
        default: return .blue
        }
    }
}

// MARK: - Widget Entry View

struct HomeScreenWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: HomeScreenProvider.Entry

    var body: some View {
        switch family {
        case .systemSmall:
            HomeScreenSmallView(entry: entry)
        case .systemMedium:
            HomeScreenMediumView(entry: entry)
        default:
            HomeScreenSmallView(entry: entry)
        }
    }
}

// MARK: - Widget Definition

struct HomeScreenWidget: Widget {
    let kind: String = "HomeScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HomeScreenProvider()) { entry in
            HomeScreenWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .widgetURL(URL(string: "projectsimple://overdue"))
        }
        .configurationDisplayName("Today's Tasks")
        .description("Shows overdue and today's tasks at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    HomeScreenWidget()
} timeline: {
    HomeScreenEntry(
        date: .now,
        overdueCount: 2,
        todayTasks: [
            TaskSnippet(id: UUID(), title: "Review proposal", priorityColor: "red", isOverdue: true, projectName: "Work"),
            TaskSnippet(id: UUID(), title: "Update docs", priorityColor: "orange", isOverdue: false, projectName: "Personal"),
            TaskSnippet(id: UUID(), title: "Send invoice", priorityColor: "green", isOverdue: false, projectName: "Finance")
        ],
        totalActiveCount: 8
    )
}

#Preview(as: .systemMedium) {
    HomeScreenWidget()
} timeline: {
    HomeScreenEntry(
        date: .now,
        overdueCount: 2,
        todayTasks: [
            TaskSnippet(id: UUID(), title: "Review proposal", priorityColor: "red", isOverdue: true, projectName: "Work"),
            TaskSnippet(id: UUID(), title: "Call client", priorityColor: "red", isOverdue: true, projectName: "Work"),
            TaskSnippet(id: UUID(), title: "Update documentation", priorityColor: "orange", isOverdue: false, projectName: "Personal"),
            TaskSnippet(id: UUID(), title: "Send invoice", priorityColor: "green", isOverdue: false, projectName: "Finance"),
            TaskSnippet(id: UUID(), title: "Team standup", priorityColor: "orange", isOverdue: false, projectName: "Work")
        ],
        totalActiveCount: 12
    )
}
