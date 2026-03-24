//
//  CalendarTaskRow.swift
//  ProjectSimple
//
//  Created by Thomas Cowern on 3/18/26.
//

import SwiftUI

struct CalendarTaskRow: View {
    let project: Project
    let task: ProjectTask

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color(for: project.safeColorName))
                .frame(width: 4, height: 40)
                .accessibilityHidden(true)

            Image(systemName: task.safeStatus.icon)
                .foregroundStyle(statusColor)
                .font(.title3)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.safeTitle)
                    .font(.subheadline.weight(.medium))
                    .strikethrough(task.safeStatus == .completed, color: .secondary)

                Text(project.safeName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(task.safePriority.rawValue)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(priorityColor.opacity(0.15))
                .foregroundStyle(priorityColor)
                .clipShape(Capsule())

            if task.safeRecurrenceRule != .none {
                Image(systemName: "arrow.clockwise")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if !task.safeSteps.isEmpty {
                HStack(spacing: 2) {
                    Image(systemName: "checklist")
                        .font(.caption2)
                    Text("\(task.completedStepsCount)/\(task.safeSteps.count)")
                        .font(.caption2)
                }
                .foregroundStyle(task.completedStepsCount == task.safeSteps.count ? .green : .secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(task.safeTitle), \(project.safeName), \(task.safeStatus.rawValue), \(task.safePriority.rawValue) priority\(task.safeRecurrenceRule != .none ? ", repeats \(task.safeRecurrenceRule.rawValue.lowercased())" : "")\(!task.safeSteps.isEmpty ? ", \(task.completedStepsCount) of \(task.safeSteps.count) steps done" : "")")
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

    private func color(for name: String) -> Color {
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
