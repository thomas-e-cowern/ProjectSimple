import SwiftUI

struct WatchTaskRow: View {
    @Environment(WatchProjectStore.self) private var store
    let task: ProjectTask
    let projectName: String

    var body: some View {
        NavigationLink(destination: WatchTaskDetailView(task: task, projectName: projectName)) {
            HStack(spacing: 8) {
                Button {
                    store.cycleTaskStatus(task)
                } label: {
                    Image(systemName: task.safeStatus.icon)
                        .foregroundStyle(statusColor)
                        .font(.body)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 2) {
                    Text(task.safeTitle)
                        .font(.caption)
                        .lineLimit(2)
                        .strikethrough(task.safeStatus == .completed)
                        .foregroundStyle(task.safeStatus == .completed ? .secondary : .primary)

                    HStack(spacing: 4) {
                        Text(task.safePriority.rawValue)
                            .font(.caption2)
                            .foregroundStyle(priorityColor)

                        if !task.safeSteps.isEmpty {
                            Text("\(task.completedStepsCount)/\(task.safeSteps.count)")
                                .font(.caption2)
                                .foregroundStyle(task.completedStepsCount == task.safeSteps.count ? .green : .secondary)
                        }
                    }
                }
            }
        }
    }

    private var statusColor: Color {
        switch task.safeStatus {
        case .notStarted: return .gray
        case .inProgress: return .blue
        case .completed: return .green
        }
    }

    private var priorityColor: Color {
        switch task.safePriority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
}
