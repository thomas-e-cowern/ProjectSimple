//
//  ProjectRow.swift
//  ProjectSimple
//
//  Created by Thomas Cowern on 3/19/26.
//

import SwiftUI

struct ProjectRow: View {
    @Environment(ProjectStore.self) private var store
    let project: Project

    var body: some View {
        // Read refreshToken to force re-evaluation when CloudKit data arrives.
        let _ = store.refreshToken
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color(for: project.safeColorName))
                .frame(width: 6, height: 50)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(project.safeName)
                    .font(.headline)

                Text(project.safeDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 12) {
                    Label(project.safeCategory.rawValue, systemImage: project.safeCategory.icon)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Label("\(project.safeTasks.count) tasks", systemImage: "checklist")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    ProgressView(value: project.completionPercentage)
                        .frame(width: 60)
                        .accessibilityHidden(true)

                    Text("\(Int(project.completionPercentage * 100))%")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(project.safeName), \(project.safeCategory.rawValue), \(project.safeTasks.count) tasks, \(Int(project.completionPercentage * 100)) percent complete")
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
