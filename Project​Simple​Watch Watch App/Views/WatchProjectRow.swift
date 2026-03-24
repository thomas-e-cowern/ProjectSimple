import SwiftUI

struct WatchProjectRow: View {
    let project: Project

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.projectColor(for: project.safeColorName))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(project.safeName)
                    .font(.caption)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: project.safeCategory.icon)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)

                    Text("\(project.activeTasks.count) tasks")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text("\(Int(project.completionPercentage * 100))%")
                .font(.caption2.bold())
                .foregroundStyle(project.completionPercentage == 1.0 ? .green : .secondary)
        }
    }
}
