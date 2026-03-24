//
//  TaskRow.swift
//  ProjectSimple
//
//  Created by Thomas Cowern on 3/19/26.
//

import SwiftUI
import TipKit

struct TaskRow: View {
    @Environment(ProjectStore.self) private var store
    let task: ProjectTask
    let projectID: UUID

    var body: some View {
        // Read refreshToken to force re-evaluation when CloudKit data arrives.
        let _ = store.refreshToken
        let statusTip = TapStatusTip()
        HStack(spacing: 12) {
            Button {
                cycleStatus()
                statusTip.invalidate(reason: .actionPerformed)
            } label: {
                Image(systemName: task.safeStatus.icon)
                    .foregroundStyle(statusColor)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .popoverTip(statusTip)
            .accessibilityLabel("Status: \(task.safeStatus.rawValue)")
            .accessibilityHint("Double tap to change status")

            VStack(alignment: .leading, spacing: 2) {
                Text(task.safeTitle)
                    .font(.subheadline.weight(.medium))
                    .strikethrough(task.safeStatus == .completed, color: .secondary)

                HStack(spacing: 8) {
                    Text(task.safeDueDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(isDueSoon ? .red : .secondary)

                    Text(task.safePriority.rawValue)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
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
            }

            Spacer()
        }
        .padding(.vertical, 2)
        .accessibilityLabel("\(task.safeTitle), \(task.safeStatus.rawValue), \(task.safePriority.rawValue) priority\(task.safeRecurrenceRule != .none ? ", repeats \(task.safeRecurrenceRule.rawValue.lowercased())" : "")\(isDueSoon ? ", due soon" : "")\(!task.safeSteps.isEmpty ? ", \(task.completedStepsCount) of \(task.safeSteps.count) steps done" : "")")
    }

    private func cycleStatus() {
        store.pushUndo()
        let previousStatus = task.safeStatus
        let updated = task
        switch task.safeStatus {
        case .notStarted: updated.status = .inProgress
        case .inProgress: updated.status = .completed
        case .completed: updated.status = .notStarted
        }
        if updated.status == .completed && previousStatus != .completed {
            updated.completedDate = Date.now
        } else if updated.status != .completed {
            updated.completedDate = nil
        }
        store.updateTask(updated, in: projectID)

        if updated.status == .completed && previousStatus != .completed {
            HapticManager.taskCompleted()
            if let project = store.projects.first(where: { $0.safeID == projectID }),
               project.completionPercentage == 1.0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    HapticManager.milestoneReached()
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
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    private var isDueSoon: Bool {
        task.safeStatus != .completed && task.safeDueDate < Calendar.current.date(byAdding: .day, value: 2, to: .now)!
    }
}
