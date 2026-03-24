import Testing
import Foundation
@testable import ProjectSimple

// MARK: - TaskStatus Tests

struct TaskStatusTests {

    @Test func rawValues() {
        #expect(TaskStatus.notStarted.rawValue == "Not Started")
        #expect(TaskStatus.inProgress.rawValue == "In Progress")
        #expect(TaskStatus.completed.rawValue == "Completed")
    }

    @Test func icons() {
        #expect(TaskStatus.notStarted.icon == "circle")
        #expect(TaskStatus.inProgress.icon == "circle.lefthalf.filled")
        #expect(TaskStatus.completed.icon == "checkmark.circle.fill")
    }

    @Test func allCasesContainsAllStatuses() {
        #expect(TaskStatus.allCases.count == 3)
        #expect(TaskStatus.allCases.contains(.notStarted))
        #expect(TaskStatus.allCases.contains(.inProgress))
        #expect(TaskStatus.allCases.contains(.completed))
    }
}

// MARK: - TaskPriority Tests

struct TaskPriorityTests {

    @Test func rawValues() {
        #expect(TaskPriority.low.rawValue == "Low")
        #expect(TaskPriority.medium.rawValue == "Medium")
        #expect(TaskPriority.high.rawValue == "High")
    }

    @Test func colors() {
        #expect(TaskPriority.low.color == "green")
        #expect(TaskPriority.medium.color == "orange")
        #expect(TaskPriority.high.color == "red")
    }

    @Test func comparableOrdersHighBeforeLow() {
        #expect(TaskPriority.high < TaskPriority.medium)
        #expect(TaskPriority.medium < TaskPriority.low)
        #expect(TaskPriority.high < TaskPriority.low)
    }

    @Test func sortingProducesHighMediumLowOrder() {
        let priorities: [TaskPriority] = [.low, .high, .medium]
        let sorted = priorities.sorted()
        #expect(sorted == [.high, .medium, .low])
    }

    @Test func allCasesContainsAllPriorities() {
        #expect(TaskPriority.allCases.count == 3)
    }
}

// MARK: - ProjectCategory Tests

struct ProjectCategoryTests {

    @Test func rawValues() {
        #expect(ProjectCategory.work.rawValue == "Work")
        #expect(ProjectCategory.personal.rawValue == "Personal")
        #expect(ProjectCategory.education.rawValue == "Education")
        #expect(ProjectCategory.health.rawValue == "Health")
        #expect(ProjectCategory.finance.rawValue == "Finance")
        #expect(ProjectCategory.other.rawValue == "Other")
    }

    @Test func icons() {
        #expect(ProjectCategory.work.icon == "briefcase.fill")
        #expect(ProjectCategory.personal.icon == "person.fill")
        #expect(ProjectCategory.education.icon == "book.fill")
        #expect(ProjectCategory.health.icon == "heart.fill")
        #expect(ProjectCategory.finance.icon == "dollarsign.circle.fill")
        #expect(ProjectCategory.other.icon == "folder.fill")
    }

    @Test func allCasesContainsAllCategories() {
        #expect(ProjectCategory.allCases.count == 6)
    }
}

// MARK: - RecurrenceRule Tests
// Note: Must use module-qualified name to disambiguate from Foundation's Calendar.RecurrenceRule.

private typealias Recurrence = ProjectSimple.RecurrenceRule

struct RecurrenceRuleTests {

    @Test func rawValues() {
        #expect(Recurrence.none.rawValue == "None")
        #expect(Recurrence.daily.rawValue == "Daily")
        #expect(Recurrence.weekly.rawValue == "Weekly")
        #expect(Recurrence.biweekly.rawValue == "Biweekly")
        #expect(Recurrence.monthly.rawValue == "Monthly")
        #expect(Recurrence.yearly.rawValue == "Yearly")
    }

    @Test func allCasesContainsAllRules() {
        #expect(Recurrence.allCases.count == 6)
    }

    @Test func noneReturnsNilNextDate() {
        let date = Date.now
        #expect(Recurrence.none.nextDueDate(from: date) == nil)
    }

    @Test func dailyAdvancesOneDay() {
        let calendar = Calendar.current
        let base = calendar.date(from: DateComponents(year: 2026, month: 3, day: 10))!
        let next = Recurrence.daily.nextDueDate(from: base)!
        let expected = calendar.date(from: DateComponents(year: 2026, month: 3, day: 11))!
        #expect(calendar.isDate(next, inSameDayAs: expected))
    }

    @Test func weeklyAdvancesOneWeek() {
        let calendar = Calendar.current
        let base = calendar.date(from: DateComponents(year: 2026, month: 3, day: 10))!
        let next = Recurrence.weekly.nextDueDate(from: base)!
        let expected = calendar.date(from: DateComponents(year: 2026, month: 3, day: 17))!
        #expect(calendar.isDate(next, inSameDayAs: expected))
    }

    @Test func biweeklyAdvancesTwoWeeks() {
        let calendar = Calendar.current
        let base = calendar.date(from: DateComponents(year: 2026, month: 3, day: 10))!
        let next = Recurrence.biweekly.nextDueDate(from: base)!
        let expected = calendar.date(from: DateComponents(year: 2026, month: 3, day: 24))!
        #expect(calendar.isDate(next, inSameDayAs: expected))
    }

    @Test func monthlyAdvancesOneMonth() {
        let calendar = Calendar.current
        let base = calendar.date(from: DateComponents(year: 2026, month: 3, day: 10))!
        let next = Recurrence.monthly.nextDueDate(from: base)!
        let expected = calendar.date(from: DateComponents(year: 2026, month: 4, day: 10))!
        #expect(calendar.isDate(next, inSameDayAs: expected))
    }

    @Test func yearlyAdvancesOneYear() {
        let calendar = Calendar.current
        let base = calendar.date(from: DateComponents(year: 2026, month: 3, day: 10))!
        let next = Recurrence.yearly.nextDueDate(from: base)!
        let expected = calendar.date(from: DateComponents(year: 2027, month: 3, day: 10))!
        #expect(calendar.isDate(next, inSameDayAs: expected))
    }

    @Test func monthlyHandlesEndOfMonth() {
        let calendar = Calendar.current
        let base = calendar.date(from: DateComponents(year: 2026, month: 1, day: 31))!
        let next = Recurrence.monthly.nextDueDate(from: base)!
        // Jan 31 + 1 month = Feb 28 (2026 is not a leap year)
        let expected = calendar.date(from: DateComponents(year: 2026, month: 2, day: 28))!
        #expect(calendar.isDate(next, inSameDayAs: expected))
    }
}
// MARK: - TaskStep Tests

@MainActor
struct TaskStepTests {

    @Test func defaultInit() {
        let step = TaskStep(title: "Do something")
        #expect(step.title == "Do something")
        #expect(step.isCompleted == false)
    }

    @Test func customInit() {
        let id = UUID()
        let step = TaskStep(id: id, title: "Custom", isCompleted: true)
        #expect(step.id == id)
        #expect(step.title == "Custom")
        #expect(step.isCompleted == true)
    }

    @Test func equatable() {
        let id = UUID()
        let a = TaskStep(id: id, title: "Same", isCompleted: false)
        let b = TaskStep(id: id, title: "Same", isCompleted: false)
        #expect(a == b)
    }

    @Test func notEqualWhenDifferentCompletion() {
        let id = UUID()
        let a = TaskStep(id: id, title: "Same", isCompleted: false)
        let b = TaskStep(id: id, title: "Same", isCompleted: true)
        #expect(a != b)
    }

    @Test func hashable() {
        let step = TaskStep(title: "Hash me")
        let set: Set<TaskStep> = [step, step]
        #expect(set.count == 1)
    }

    @Test func codableRoundTrip() throws {
        let original = TaskStep(title: "Encode me", isCompleted: true)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TaskStep.self, from: data)
        #expect(decoded == original)
    }

    @Test func codableArrayRoundTrip() throws {
        let steps = [
            TaskStep(title: "Step 1"),
            TaskStep(title: "Step 2", isCompleted: true)
        ]
        let data = try JSONEncoder().encode(steps)
        let decoded = try JSONDecoder().decode([TaskStep].self, from: data)
        #expect(decoded == steps)
    }
}

