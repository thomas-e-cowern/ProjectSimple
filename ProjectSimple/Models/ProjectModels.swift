import Foundation
import SwiftData

enum ProjectCategory: String, Codable, CaseIterable {
    case work = "Work"
    case personal = "Personal"
    case education = "Education"
    case health = "Health"
    case finance = "Finance"
    case other = "Other"

    var icon: String {
        switch self {
        case .work: return "briefcase.fill"
        case .personal: return "person.fill"
        case .education: return "book.fill"
        case .health: return "heart.fill"
        case .finance: return "dollarsign.circle.fill"
        case .other: return "folder.fill"
        }
    }
}

@Model
class Project {
    // All stored properties must be optional for CloudKit compatibility.
    var id: UUID?
    var name: String?
    var descriptionText: String?
    var startDate: Date?
    var endDate: Date?
    @Relationship(deleteRule: .cascade, inverse: \ProjectTask.project)
    var tasks: [ProjectTask]?
    var colorName: String?
    var category: ProjectCategory?
    var isArchived: Bool?

    init(
        id: UUID = UUID(),
        name: String,
        descriptionText: String = "",
        startDate: Date = .now,
        endDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now,
        tasks: [ProjectTask] = [],
        colorName: String = "blue",
        category: ProjectCategory = .other,
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.descriptionText = descriptionText
        self.startDate = startDate
        self.endDate = endDate
        self.tasks = tasks
        self.colorName = colorName
        self.category = category
        self.isArchived = isArchived
    }

    // MARK: - Safe Accessors (non-optional wrappers for the rest of the codebase)

    /// Returns `false` when the object has been deleted from its context.
    /// Objects that were never inserted (modelContext == nil) are still
    /// accessible.  All safe accessors check this first to avoid
    /// "backing data was detached" crashes.
    var isAccessible: Bool { !isDeleted }

    var safeID: UUID { isAccessible ? (id ?? UUID()) : UUID() }
    var safeName: String { isAccessible ? (name ?? "") : "" }
    var safeDescription: String { isAccessible ? (descriptionText ?? "") : "" }
    var safeStartDate: Date { isAccessible ? (startDate ?? .now) : .now }
    var safeEndDate: Date { isAccessible ? (endDate ?? .now) : .now }
    var safeTasks: [ProjectTask] { isAccessible ? (tasks ?? []) : [] }
    var safeColorName: String { isAccessible ? (colorName ?? "blue") : "blue" }
    var safeCategory: ProjectCategory { isAccessible ? (category ?? .other) : .other }
    var safeIsArchived: Bool { isAccessible ? (isArchived ?? false) : false }

    var activeTasks: [ProjectTask] {
        safeTasks.filter { !$0.safeIsArchived }
    }

    var completionPercentage: Double {
        let active = activeTasks
        guard !active.isEmpty else { return 0 }
        let completed = active.filter { $0.safeStatus == .completed }.count
        return Double(completed) / Double(active.count)
    }
}
