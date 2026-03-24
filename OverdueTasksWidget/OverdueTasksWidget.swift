import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Timeline Entry

struct OverdueTasksEntry: TimelineEntry {
    let date: Date
    let overdueCount: Int
    let taskTitles: [String]
}

// MARK: - Timeline Provider

struct OverdueTasksProvider: TimelineProvider {
    func placeholder(in context: Context) -> OverdueTasksEntry {
        OverdueTasksEntry(date: .now, overdueCount: 3, taskTitles: ["Sample task 1", "Sample task 2"])
    }

    func getSnapshot(in context: Context, completion: @escaping (OverdueTasksEntry) -> Void) {
        if context.isPreview {
            completion(OverdueTasksEntry(date: .now, overdueCount: 3, taskTitles: ["Review proposal", "Submit report"]))
        } else {
            completion(fetchOverdueTasks())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<OverdueTasksEntry>) -> Void) {
        let entry = fetchOverdueTasks()

        // Refresh at midnight when new tasks may become overdue
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: .now)!)

        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }

    private func fetchOverdueTasks() -> OverdueTasksEntry {
        do {
            let container = try SharedModelContainer.createForWidget()
            let context = ModelContext(container)

            let descriptor = FetchDescriptor<Project>(
                predicate: #Predicate<Project> { $0.isArchived != true }
            )
            let projects = (try? context.fetch(descriptor)) ?? []

            let calendar = Calendar.current
            let startOfToday = calendar.startOfDay(for: .now)

            var overdueTasks: [(title: String, dueDate: Date)] = []
            for project in projects {
                for task in project.activeTasks {
                    if task.safeStatus != .completed && task.safeDueDate < startOfToday {
                        overdueTasks.append((title: task.safeTitle, dueDate: task.safeDueDate))
                    }
                }
            }

            overdueTasks.sort { $0.dueDate < $1.dueDate }

            let titles = Array(overdueTasks.prefix(3).map(\.title))
            return OverdueTasksEntry(date: .now, overdueCount: overdueTasks.count, taskTitles: titles)
        } catch {
            return OverdueTasksEntry(date: .now, overdueCount: 0, taskTitles: [])
        }
    }
}

// MARK: - Circular Widget View

struct OverdueCircularView: View {
    let entry: OverdueTasksEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Image(systemName: "checklist.unchecked")
                    .font(.caption)
                    .widgetAccentable()
                Text("\(entry.overdueCount)")
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
    }
}

// MARK: - Rectangular Widget View

struct OverdueRectangularView: View {
    let entry: OverdueTasksEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: "checklist.unchecked")
                    .font(.caption)
                    .widgetAccentable()
                Text("ProjectSimple")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(entry.overdueCount) Overdue")
                    .font(.caption2.weight(.semibold))
                    .widgetAccentable()
            }

            if entry.taskTitles.isEmpty {
                Text("No overdue tasks")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(entry.taskTitles.prefix(2), id: \.self) { title in
                    Text(title)
                        .font(.caption)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Widget Entry View

struct OverdueTasksWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: OverdueTasksProvider.Entry

    var body: some View {
        switch family {
        case .accessoryCircular:
            OverdueCircularView(entry: entry)
        case .accessoryRectangular:
            OverdueRectangularView(entry: entry)
        default:
            OverdueCircularView(entry: entry)
        }
    }
}

// MARK: - Widget Definition

struct OverdueTasksWidget: Widget {
    let kind: String = "OverdueTasksWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OverdueTasksProvider()) { entry in
            OverdueTasksWidgetEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
                .widgetURL(URL(string: "projectsimple://overdue"))
        }
        .configurationDisplayName("Overdue Tasks")
        .description("Shows your overdue task count and details.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

#Preview(as: .accessoryCircular) {
    OverdueTasksWidget()
} timeline: {
    OverdueTasksEntry(date: .now, overdueCount: 3, taskTitles: ["Review proposal", "Submit report"])
}

#Preview(as: .accessoryRectangular) {
    OverdueTasksWidget()
} timeline: {
    OverdueTasksEntry(date: .now, overdueCount: 3, taskTitles: ["Review proposal", "Submit report"])
}
