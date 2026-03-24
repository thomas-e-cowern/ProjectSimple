//
//  ProjectTask.swift
//  ProjectSimple
//
//  Created by Thomas Cowern on 3/16/26.
//

import Foundation
import SwiftData

@Model
class ProjectTask {
    // All stored properties must be optional for CloudKit compatibility.
    var id: UUID?
    var title: String?
    var details: String?
    var dueDate: Date?
    var status: TaskStatus?
    var priority: TaskPriority?
    var isArchived: Bool?
    var recurrenceRule: RecurrenceRule?
    var hasGeneratedNextOccurrence: Bool?
    var steps: [TaskStep]?
    var completedDate: Date?
    var project: Project?

    init(
        id: UUID = UUID(),
        title: String,
        details: String = "",
        dueDate: Date,
        status: TaskStatus = .notStarted,
        priority: TaskPriority = .medium,
        isArchived: Bool = false,
        recurrenceRule: RecurrenceRule = .none,
        steps: [TaskStep] = [],
        completedDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.dueDate = dueDate
        self.status = status
        self.priority = priority
        self.isArchived = isArchived
        self.recurrenceRule = recurrenceRule
        self.hasGeneratedNextOccurrence = false
        self.steps = steps
        self.completedDate = completedDate ?? (status == .completed ? Date.now : nil)
    }

    // MARK: - Safe Accessors (non-optional wrappers for the rest of the codebase)

    /// Returns `false` when the object has been deleted from its context.
    /// Objects that were never inserted (modelContext == nil) are still
    /// accessible.
    var isAccessible: Bool { !isDeleted }

    var safeID: UUID { isAccessible ? (id ?? UUID()) : UUID() }
    var safeTitle: String { isAccessible ? (title ?? "") : "" }
    var safeDetails: String { isAccessible ? (details ?? "") : "" }
    var safeDueDate: Date { isAccessible ? (dueDate ?? .now) : .now }
    var safeStatus: TaskStatus { isAccessible ? (status ?? .notStarted) : .notStarted }
    var safePriority: TaskPriority { isAccessible ? (priority ?? .medium) : .medium }
    var safeIsArchived: Bool { isAccessible ? (isArchived ?? false) : false }
    var safeRecurrenceRule: RecurrenceRule { isAccessible ? (recurrenceRule ?? .none) : .none }
    var safeHasGeneratedNextOccurrence: Bool { isAccessible ? (hasGeneratedNextOccurrence ?? false) : false }
    var safeSteps: [TaskStep] { isAccessible ? (steps ?? []) : [] }

    var completedStepsCount: Int {
        safeSteps.filter { $0.isCompleted }.count
    }

    var stepsResetForRecurrence: [TaskStep] {
        safeSteps.map { TaskStep(title: $0.title) }
    }
}

enum TaskStatus: String, Codable, CaseIterable {
    case notStarted = "Not Started"
    case inProgress = "In Progress"
    case completed = "Completed"

    var icon: String {
        switch self {
        case .notStarted: return "circle"
        case .inProgress: return "circle.lefthalf.filled"
        case .completed: return "checkmark.circle.fill"
        }
    }
}

enum TaskPriority: String, Codable, CaseIterable, Comparable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "orange"
        case .high: return "red"
        }
    }

    private var sortOrder: Int {
        switch self {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }

    static func < (lhs: TaskPriority, rhs: TaskPriority) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

enum RecurrenceRule: String, Codable, CaseIterable {
    case none = "None"
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Biweekly"
    case monthly = "Monthly"
    case yearly = "Yearly"

    func nextDueDate(from date: Date) -> Date? {
        let calendar = Calendar.current
        switch self {
        case .none: return nil
        case .daily: return calendar.date(byAdding: .day, value: 1, to: date)
        case .weekly: return calendar.date(byAdding: .weekOfYear, value: 1, to: date)
        case .biweekly: return calendar.date(byAdding: .weekOfYear, value: 2, to: date)
        case .monthly: return calendar.date(byAdding: .month, value: 1, to: date)
        case .yearly: return calendar.date(byAdding: .year, value: 1, to: date)
        }
    }
}

struct TaskStep: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    var title: String
    var isCompleted: Bool

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}
