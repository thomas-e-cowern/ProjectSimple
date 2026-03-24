//
//  SearchTaskRow.swift
//  ProjectSimple
//
//  Created by Thomas Cowern on 3/17/26.
//

import Foundation
import SwiftUI

// MARK: - Search Task Row

struct SearchTaskRow: View {
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
                
                HStack(spacing: 8) {
                    Text(projectName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(task.safePriority.rawValue)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(priorityColor.opacity(0.15))
                        .foregroundStyle(priorityColor)
                        .clipShape(Capsule())
                    
                    Text(task.safeDueDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(task.safeTitle), \(projectName), \(task.safeStatus.rawValue), \(task.safePriority.rawValue) priority\(task.safeRecurrenceRule != .none ? ", repeats \(task.safeRecurrenceRule.rawValue.lowercased())" : "")\(!task.safeSteps.isEmpty ? ", \(task.completedStepsCount) of \(task.safeSteps.count) steps done" : "")")
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
