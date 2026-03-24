//
//  ArchiveRowView.swift
//  ProjectSimple
//
//  Created by Thomas Cowern on 3/19/26.
//

import SwiftUI

// MARK: - Row Views

struct ArchivedProjectRow: View {
    let project: Project

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color(for: project.safeColorName))
                .frame(width: 6, height: 50)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(project.safeName)
                    .font(.headline)

                if !project.safeDescription.isEmpty {
                    Text(project.safeDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 12) {
                    Label("\(project.safeTasks.count) tasks", systemImage: "checklist")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if project.safeIsArchived {
                        Text("Archived")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }

                    if project.completionPercentage == 1.0 {
                        Text("Complete")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.15))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(project.safeName), \(project.safeTasks.count) tasks\(project.safeIsArchived ? ", archived" : "")\(project.completionPercentage == 1.0 ? ", complete" : "")")
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
