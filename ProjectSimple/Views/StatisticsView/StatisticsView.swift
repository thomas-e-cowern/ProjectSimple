import SwiftUI
import Charts

struct StatisticsView: View {
    @Environment(ProjectStore.self) private var store

    var body: some View {
        // Read refreshToken to re-evaluate when data changes via sync.
        let _ = store.refreshToken
        NavigationStack {
            List {
                overviewSection
                thisWeekSection
                completionTrendSection
                mostProductiveDaySection
                tasksByPrioritySection
                tasksByCategorySection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Statistics")
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

    // MARK: - Data Helpers

    private var allActiveTasks: [ProjectTask] {
        store.activeProjects.flatMap { $0.activeTasks }
    }

    private var allCompletedTasks: [ProjectTask] {
        allActiveTasks.filter { $0.safeStatus == .completed }
    }

    private var overdueTasks: [ProjectTask] {
        let startOfToday = Calendar.current.startOfDay(for: .now)
        return allActiveTasks.filter { $0.safeStatus != .completed && $0.safeDueDate < startOfToday }
    }

    private var tasksCompletedThisWeek: [ProjectTask] {
        let calendar = Calendar.current
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now)) else {
            return []
        }
        return allCompletedTasks.filter { task in
            guard let completedDate = task.completedDate else { return false }
            return completedDate >= weekStart && completedDate <= .now
        }
    }

    // MARK: - Section 1: Overview

    @ViewBuilder
    private var overviewSection: some View {
        Section("Overview") {
            let totalTasks = allActiveTasks.count
            let completedCount = allCompletedTasks.count
            let overdueCount = overdueTasks.count
            let projectCount = store.activeProjects.count
            let completionRate = totalTasks > 0 ? Double(completedCount) / Double(totalTasks) : 0

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(title: "Projects", value: "\(projectCount)", icon: "folder.fill", color: .blue)
                StatCard(title: "Total Tasks", value: "\(totalTasks)", icon: "checklist", color: .gray)
                StatCard(title: "Completed", value: "\(completedCount)", icon: "checkmark.circle.fill", color: .green)
                StatCard(title: "Overdue", value: "\(overdueCount)", icon: "exclamationmark.triangle.fill", color: .red)
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 4, trailing: 16))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Completion Rate")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(completionRate * 100))%")
                        .font(.subheadline.bold())
                }
                ProgressView(value: completionRate)
                    .tint(.green)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Section 2: This Week

    @ViewBuilder
    private var thisWeekSection: some View {
        Section("This Week") {
            let weekTasks = tasksCompletedThisWeek
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text("\(weekTasks.count) task\(weekTasks.count == 1 ? "" : "s") completed")
                        .font(.headline)
                    Text("this week")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)

            if !weekTasks.isEmpty {
                let recentTasks = weekTasks
                    .sorted { ($0.completedDate ?? .distantPast) > ($1.completedDate ?? .distantPast) }
                    .prefix(5)

                ForEach(Array(recentTasks), id: \.safeID) { task in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        VStack(alignment: .leading) {
                            Text(task.safeTitle)
                                .font(.subheadline)
                            if let project = store.activeProjects.first(where: { $0.safeTasks.contains(where: { $0.safeID == task.safeID }) }) {
                                Text(project.safeName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if let date = task.completedDate {
                            Text(date, format: .dateTime.weekday(.abbreviated))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Section 3: Completion Trend (Last 4 Weeks)

    @ViewBuilder
    private var completionTrendSection: some View {
        Section("Completion Trend") {
            let weeklyData = completionsByWeek()

            if weeklyData.isEmpty || weeklyData.allSatisfy({ $0.count == 0 }) {
                Text("No completed tasks yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Chart(weeklyData, id: \.weekLabel) { item in
                    BarMark(
                        x: .value("Week", item.weekLabel),
                        y: .value("Completed", item.count)
                    )
                    .foregroundStyle(.blue.gradient)
                    .cornerRadius(4)
                }
                .chartYAxis {
                    AxisMarks(preset: .aligned) { value in
                        if let intValue = value.as(Int.self) {
                            AxisValueLabel { Text("\(intValue)") }
                            AxisGridLine()
                        }
                    }
                }
                .frame(height: 180)
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Section 4: Most Productive Day

    @ViewBuilder
    private var mostProductiveDaySection: some View {
        Section("Most Productive Day") {
            let dayData = completionsByDayOfWeek()
            let topDay = dayData.max(by: { $0.count < $1.count })

            if let topDay, topDay.count > 0 {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.title2)
                    VStack(alignment: .leading) {
                        Text(topDay.dayName)
                            .font(.headline)
                        Text("\(topDay.count) task\(topDay.count == 1 ? "" : "s") completed")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)

                Chart(dayData, id: \.dayName) { item in
                    BarMark(
                        x: .value("Day", item.dayName),
                        y: .value("Completed", item.count)
                    )
                    .foregroundStyle(item.dayName == topDay.dayName ? Color.yellow : Color.gray.opacity(0.5))
                    .cornerRadius(4)
                }
                .chartYAxis {
                    AxisMarks(preset: .aligned) { value in
                        if let intValue = value.as(Int.self) {
                            AxisValueLabel { Text("\(intValue)") }
                            AxisGridLine()
                        }
                    }
                }
                .frame(height: 160)
                .padding(.vertical, 4)
            } else {
                Text("Complete some tasks to see your most productive day.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Section 5: Tasks by Priority

    @ViewBuilder
    private var tasksByPrioritySection: some View {
        Section("Tasks by Priority") {
            let activeTasks = allActiveTasks.filter { $0.safeStatus != .completed }
            let highCount = activeTasks.filter { $0.safePriority == .high }.count
            let mediumCount = activeTasks.filter { $0.safePriority == .medium }.count
            let lowCount = activeTasks.filter { $0.safePriority == .low }.count

            let priorityData: [(name: String, count: Int, color: Color)] = [
                ("High", highCount, .red),
                ("Medium", mediumCount, .orange),
                ("Low", lowCount, .green)
            ].filter { $0.count > 0 }

            if priorityData.isEmpty {
                Text("No active tasks.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Chart(priorityData, id: \.name) { item in
                    SectorMark(
                        angle: .value("Count", item.count),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(item.color)
                    .annotation(position: .overlay) {
                        if item.count > 0 {
                            Text("\(item.count)")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                        }
                    }
                }
                .frame(height: 180)
                .padding(.vertical, 4)

                ForEach(priorityData, id: \.name) { item in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(item.color)
                            .frame(width: 10, height: 10)
                        Text(item.name)
                            .font(.subheadline)
                        Spacer()
                        Text("\(item.count)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Section 6: Tasks by Category

    @ViewBuilder
    private var tasksByCategorySection: some View {
        Section("Tasks by Category") {
            let categoryData = taskCountsByCategory()

            if categoryData.isEmpty {
                Text("No active tasks.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Chart(categoryData, id: \.category) { item in
                    BarMark(
                        x: .value("Count", item.count),
                        y: .value("Category", item.category)
                    )
                    .foregroundStyle(.tint)
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks(preset: .aligned) { value in
                        if let intValue = value.as(Int.self) {
                            AxisValueLabel { Text("\(intValue)") }
                            AxisGridLine()
                        }
                    }
                }
                .frame(height: CGFloat(categoryData.count) * 40 + 20)
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Computation Helpers

    private struct WeekData {
        let weekLabel: String
        let count: Int
    }

    private struct DayData {
        let dayName: String
        let count: Int
    }

    private struct CategoryData {
        let category: String
        let count: Int
    }

    private func completionsByWeek() -> [WeekData] {
        let calendar = Calendar.current
        let now = Date.now
        var results: [WeekData] = []

        for weeksAgo in (0..<4).reversed() {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!) else {
                continue
            }
            guard let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) else {
                continue
            }

            let count = allCompletedTasks.filter { task in
                guard let completedDate = task.completedDate else { return false }
                return completedDate >= weekStart && completedDate < weekEnd
            }.count

            let label: String
            if weeksAgo == 0 {
                label = "This Week"
            } else if weeksAgo == 1 {
                label = "Last Week"
            } else {
                label = "\(weeksAgo)w ago"
            }
            results.append(WeekData(weekLabel: label, count: count))
        }
        return results
    }

    private func completionsByDayOfWeek() -> [DayData] {
        let calendar = Calendar.current
        let daySymbols = calendar.shortWeekdaySymbols

        var counts = [Int](repeating: 0, count: 7)
        for task in allCompletedTasks {
            guard let completedDate = task.completedDate else { continue }
            let weekday = calendar.component(.weekday, from: completedDate)
            counts[weekday - 1] += 1
        }

        return daySymbols.enumerated().map { index, name in
            DayData(dayName: name, count: counts[index])
        }
    }

    private func taskCountsByCategory() -> [CategoryData] {
        var counts: [String: Int] = [:]
        for project in store.activeProjects {
            let taskCount = project.activeTasks.count
            if taskCount > 0 {
                counts[project.safeCategory.rawValue, default: 0] += taskCount
            }
        }
        return counts
            .map { CategoryData(category: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    StatisticsView()
        .environment(ProjectStore.preview())
}
