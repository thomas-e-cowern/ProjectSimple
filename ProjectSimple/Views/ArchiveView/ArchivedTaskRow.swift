//
//  ArchivedTaskRow.swift
//  ProjectSimple
//
//  Created by Thomas Cowern on 3/19/26.
//

import SwiftUI

struct ArchivedTaskRow: View {
    let task: ProjectTask
    let projectName: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: task.safeStatus.icon)
                .foregroundStyle(statusColor)
                .font(.title3)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.safeTitle)
                    .font(.subheadline.weight(.medium))
                    .strikethrough(task.safeStatus == .completed, color: .secondary)

                HStack(spacing: 8) {
                    Text(task.safeDueDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(task.safePriority.rawValue)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(priorityColor.opacity(0.15))
                        .foregroundStyle(priorityColor)
                        .clipShape(Capsule())

                    if task.safeIsArchived {
                        Text("Archived")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(task.safeTitle), \(task.safeStatus.rawValue), \(task.safePriority.rawValue) priority\(task.safeIsArchived ? ", archived" : "")")
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
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

