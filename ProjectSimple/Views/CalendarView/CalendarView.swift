import SwiftUI

struct CalendarView: View {
    @Environment(ProjectStore.self) private var store
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var displayedMonth = Date.now
    @State private var selectedDate: Date? = nil

    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    private var dayCellHeight: CGFloat {
        sizeClass == .regular ? 56 : 44
    }

    var body: some View {
        // Read refreshToken to re-evaluate when data changes via sync.
        let _ = store.refreshToken
        NavigationStack {
            Group {
                if sizeClass == .regular {
                    wideLayout
                } else {
                    compactLayout
                }
            }
            .navigationTitle("Calendar")
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
            .navigationDestination(for: UUID.self) { projectID in
                if let project = store.projects.first(where: { $0.safeID == projectID }) {
                    ProjectDetailView(project: project)
                }
            }
        }
    }

    // MARK: - Layout Variants

    private var compactLayout: some View {
        VStack(spacing: 0) {
            monthHeader
            dayOfWeekHeader
            calendarGrid
            Divider()
            taskListForSelectedDate
        }
    }

    private var wideLayout: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                monthHeader
                dayOfWeekHeader
                calendarGrid
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            VStack(spacing: 0) {
                taskListForSelectedDate
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
            }
            .accessibilityLabel("Previous month")

            Spacer()

            Text(monthYearString)
                .font(.title2.bold())

            Spacer()

            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
            .accessibilityLabel("Next month")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Day of Week Header

    private var dayOfWeekHeader: some View {
        HStack(spacing: 0) {
            ForEach(daysOfWeek, id: \.self) { day in
                Text(day)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let days = daysInMonth()
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(days, id: \.self) { date in
                if let date {
                    dayCell(for: date)
                } else {
                    Color.clear
                        .frame(height: dayCellHeight)
                }
            }
        }
        .padding(.horizontal, 4)
    }

    private func dayCell(for date: Date) -> some View {
        let isToday = calendar.isDateInToday(date)
        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        let tasksForDay = store.tasks(for: date)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDate = date
            }
        } label: {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.callout)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(isSelected ? .white : isToday ? .blue : .primary)

                if !tasksForDay.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(tasksForDay.prefix(3), id: \.task.safeID) { item in
                            Circle()
                                .fill(Color(projectColor(item.project.safeColorName)))
                                .frame(width: 5, height: 5)
                        }
                    }
                } else {
                    Spacer()
                        .frame(height: 5)
                }
            }
            .frame(height: dayCellHeight)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(dayCellAccessibilityLabel(date: date, isToday: isToday, taskCount: tasksForDay.count))
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to view tasks")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Task List for Selected Date

    @ViewBuilder
    private var taskListForSelectedDate: some View {
        if let selectedDate {
            let tasksForDay = store.tasks(for: selectedDate)

            VStack(alignment: .leading, spacing: 8) {
                Text(selectedDateString)
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 12)

                if tasksForDay.isEmpty {
                    ContentUnavailableView {
                        Label("No Tasks", systemImage: "checkmark.circle")
                    } description: {
                        Text("No tasks scheduled for this day.")
                    }
                } else {
                    List {
                        ForEach(tasksForDay, id: \.task.safeID) { item in
                            NavigationLink(value: item.project.safeID) {
                                CalendarTaskRow(project: item.project, task: item.task)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
        } else {
            let overdue = store.overdueTasks()
            VStack(alignment: .leading, spacing: 8) {
                if overdue.isEmpty {
                    ContentUnavailableView {
                        Label("No Overdue Tasks", systemImage: "checkmark.circle")
                    } description: {
                        Text("You're all caught up! Tap a date to see scheduled tasks.")
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    HStack {
                        Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundStyle(.red)
                        Spacer()
                        Text("\(overdue.count) task\(overdue.count == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(overdue.count) overdue task\(overdue.count == 1 ? "" : "s")")

                    List {
                        ForEach(overdue, id: \.task.safeID) { item in
                            NavigationLink(value: item.project.safeID) {
                                CalendarTaskRow(project: item.project, task: item.task)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
    }

    // MARK: - Helpers

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private var selectedDateString: String {
        guard let selectedDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: selectedDate)
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            withAnimation(.easeInOut(duration: 0.2)) {
                displayedMonth = newMonth
                selectedDate = nil
            }
        }
    }

    private func daysInMonth() -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let leadingBlanks = firstWeekday - 1

        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }

        return days
    }

    private func dayCellAccessibilityLabel(date: Date, isToday: Bool, taskCount: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        var label = formatter.string(from: date)
        if isToday { label += ", today" }
        if taskCount > 0 {
            label += ", \(taskCount) task\(taskCount == 1 ? "" : "s")"
        }
        return label
    }

    private func projectColor(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "purple": return .purple
        case "orange": return .orange
        case "red": return .red
        case "green": return .green
        case "pink": return .pink
        default: return .blue
        }
    }
}

#Preview {
    CalendarView()
        .environment(ProjectStore.preview())
}
