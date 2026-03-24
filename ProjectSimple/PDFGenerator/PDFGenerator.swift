import UIKit
import UniformTypeIdentifiers

// MARK: - Data Transfer Types

struct PDFTaskInfo {
    let title: String
    let details: String
    let dueDate: Date
    let status: String
    let priority: String
    let priorityColorName: String
}

struct PDFProjectInfo {
    let name: String
    let descriptionText: String
    let category: String
    let startDate: Date
    let endDate: Date
    let completionPercentage: Double
    let completedCount: Int
    let inProgressCount: Int
    let notStartedCount: Int
    let tasks: [PDFTaskInfo]
}

extension PDFProjectInfo {
    init(from project: Project) {
        let active = project.activeTasks
        let sorted = active.sorted { a, b in
            if a.safeStatus == .completed && b.safeStatus != .completed { return false }
            if a.safeStatus != .completed && b.safeStatus == .completed { return true }
            if a.safePriority != b.safePriority { return a.safePriority < b.safePriority }
            return a.safeDueDate < b.safeDueDate
        }
        self.name = project.safeName
        self.descriptionText = project.safeDescription
        self.category = project.safeCategory.rawValue
        self.startDate = project.safeStartDate
        self.endDate = project.safeEndDate
        self.completionPercentage = project.completionPercentage
        self.completedCount = active.filter { $0.safeStatus == .completed }.count
        self.inProgressCount = active.filter { $0.safeStatus == .inProgress }.count
        self.notStartedCount = active.filter { $0.safeStatus == .notStarted }.count
        self.tasks = sorted.map { task in
            PDFTaskInfo(
                title: task.safeTitle,
                details: task.safeDetails,
                dueDate: task.safeDueDate,
                status: task.safeStatus.rawValue,
                priority: task.safePriority.rawValue,
                priorityColorName: task.safePriority.color
            )
        }
    }
}

// MARK: - PDF Generator

struct PDFGenerator {
    static let pageWidth: CGFloat = 612
    static let pageHeight: CGFloat = 792
    static let margin: CGFloat = 50
    static let contentWidth: CGFloat = pageWidth - 2 * margin

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    func generatePDF(for project: PDFProjectInfo) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: Self.pageWidth, height: Self.pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = renderer.pdfData { context in
            var yPosition: CGFloat = 0

            func beginNewPage() {
                context.beginPage()
                yPosition = Self.margin
            }

            func ensureSpace(_ needed: CGFloat) {
                if yPosition + needed > Self.pageHeight - Self.margin {
                    beginNewPage()
                }
            }

            beginNewPage()

            // Title
            yPosition = drawTitle(project.name, at: yPosition)
            yPosition += 8

            // Description
            if !project.descriptionText.isEmpty {
                yPosition = drawText(
                    project.descriptionText,
                    at: yPosition,
                    font: .systemFont(ofSize: 12),
                    color: .secondaryLabel
                )
                yPosition += 12
            }

            // Metadata row
            yPosition = drawMetadataRow(project: project, at: yPosition)
            yPosition += 20

            // Progress section
            ensureSpace(80)
            yPosition = drawSectionHeader("Progress Summary", at: yPosition)
            yPosition += 8
            yPosition = drawProgressSummary(project: project, at: yPosition)
            yPosition += 24

            // Tasks section
            ensureSpace(40)
            let projectTasks = project.tasks
            yPosition = drawSectionHeader("Tasks (\(projectTasks.count))", at: yPosition)
            yPosition += 8

            if projectTasks.isEmpty {
                yPosition = drawText(
                    "No active tasks.",
                    at: yPosition,
                    font: .italicSystemFont(ofSize: 11),
                    color: .secondaryLabel
                )
            } else {
                for (index, task) in projectTasks.enumerated() {
                    let estimatedHeight = estimateTaskHeight(task)
                    ensureSpace(estimatedHeight)
                    yPosition = drawTask(task, index: index, at: yPosition)
                    yPosition += 12
                }
            }

            // Footer
            ensureSpace(40)
            drawFooter(at: Self.pageHeight - Self.margin + 20)
        }
        return data
    }

    // MARK: - Drawing Helpers

    private func drawTitle(_ text: String, at y: CGFloat) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 24, weight: .bold)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.label]
        let rect = CGRect(x: Self.margin, y: y, width: Self.contentWidth, height: 40)
        let boundingRect = (text as NSString).boundingRect(
            with: CGSize(width: Self.contentWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: attrs,
            context: nil
        )
        (text as NSString).draw(in: rect, withAttributes: attrs)
        return y + boundingRect.height
    }

    private func drawText(_ text: String, at y: CGFloat, font: UIFont, color: UIColor) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let boundingRect = (text as NSString).boundingRect(
            with: CGSize(width: Self.contentWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: attrs,
            context: nil
        )
        let rect = CGRect(x: Self.margin, y: y, width: Self.contentWidth, height: boundingRect.height)
        (text as NSString).draw(in: rect, withAttributes: attrs)
        return y + boundingRect.height
    }

    private func drawSectionHeader(_ text: String, at y: CGFloat) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.label]
        let rect = CGRect(x: Self.margin, y: y, width: Self.contentWidth, height: 24)
        (text as NSString).draw(in: rect, withAttributes: attrs)

        // Underline
        let lineY = y + 22
        let path = UIBezierPath()
        path.move(to: CGPoint(x: Self.margin, y: lineY))
        path.addLine(to: CGPoint(x: Self.margin + Self.contentWidth, y: lineY))
        UIColor.separator.setStroke()
        path.lineWidth = 0.5
        path.stroke()

        return y + 26
    }

    private func drawMetadataRow(project: PDFProjectInfo, at y: CGFloat) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 11)
        let labelFont = UIFont.systemFont(ofSize: 11, weight: .semibold)
        let color = UIColor.secondaryLabel

        let items: [(String, String)] = [
            ("Category:", project.category),
            ("Start:", dateFormatter.string(from: project.startDate)),
            ("End:", dateFormatter.string(from: project.endDate))
        ]

        let columnWidth = Self.contentWidth / CGFloat(items.count)
        for (index, item) in items.enumerated() {
            let x = Self.margin + columnWidth * CGFloat(index)

            let labelAttrs: [NSAttributedString.Key: Any] = [.font: labelFont, .foregroundColor: color]
            let valueAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.label]

            let labelStr = NSAttributedString(string: item.0 + " ", attributes: labelAttrs)
            let valueStr = NSAttributedString(string: item.1, attributes: valueAttrs)

            let combined = NSMutableAttributedString()
            combined.append(labelStr)
            combined.append(valueStr)

            combined.draw(in: CGRect(x: x, y: y, width: columnWidth, height: 20))
        }

        return y + 20
    }

    private func drawProgressSummary(project: PDFProjectInfo, at y: CGFloat) -> CGFloat {
        var currentY = y

        // Progress text
        let totalTasks = project.completedCount + project.inProgressCount + project.notStartedCount
        let percentText = "\(project.completedCount) of \(totalTasks) tasks completed (\(Int(project.completionPercentage * 100))%)"
        currentY = drawText(percentText, at: currentY, font: .systemFont(ofSize: 12), color: .label)
        currentY += 8

        // Progress bar
        let barHeight: CGFloat = 8
        let barRect = CGRect(x: Self.margin, y: currentY, width: Self.contentWidth, height: barHeight)
        let fillWidth = Self.contentWidth * project.completionPercentage

        // Background
        let bgPath = UIBezierPath(roundedRect: barRect, cornerRadius: 4)
        UIColor.systemGray5.setFill()
        bgPath.fill()

        // Fill
        if fillWidth > 0 {
            let fillRect = CGRect(x: Self.margin, y: currentY, width: fillWidth, height: barHeight)
            let fillPath = UIBezierPath(roundedRect: fillRect, cornerRadius: 4)
            UIColor.systemBlue.setFill()
            fillPath.fill()
        }

        currentY += barHeight + 10

        // Status counts
        let statusItems: [(Int, String, UIColor)] = [
            (project.notStartedCount, "To Do", .systemGray),
            (project.inProgressCount, "In Progress", .systemBlue),
            (project.completedCount, "Done", .systemGreen)
        ]

        let columnWidth = Self.contentWidth / CGFloat(statusItems.count)
        for (index, item) in statusItems.enumerated() {
            let x = Self.margin + columnWidth * CGFloat(index)

            // Colored dot
            let dotRect = CGRect(x: x, y: currentY + 3, width: 8, height: 8)
            let dotPath = UIBezierPath(ovalIn: dotRect)
            item.2.setFill()
            dotPath.fill()

            // Count and label
            let text = "\(item.0) \(item.1)"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.secondaryLabel
            ]
            (text as NSString).draw(
                in: CGRect(x: x + 12, y: currentY, width: columnWidth - 12, height: 16),
                withAttributes: attrs
            )
        }

        return currentY + 20
    }

    private func drawTask(_ task: PDFTaskInfo, index: Int, at y: CGFloat) -> CGFloat {
        var currentY = y

        // Priority indicator dot
        let dotColor = uiColor(forPriorityColorName: task.priorityColorName)
        let dotRect = CGRect(x: Self.margin, y: currentY + 3, width: 8, height: 8)
        let dotPath = UIBezierPath(ovalIn: dotRect)
        dotColor.setFill()
        dotPath.fill()

        // Task title
        let titleFont = UIFont.systemFont(ofSize: 13, weight: .medium)
        let isCompleted = task.status == "Completed"
        let titleAttrs: [NSAttributedString.Key: Any]
        if isCompleted {
            titleAttrs = [
                .font: titleFont,
                .foregroundColor: UIColor.secondaryLabel,
                .strikethroughStyle: NSUnderlineStyle.single.rawValue
            ]
        } else {
            titleAttrs = [.font: titleFont, .foregroundColor: UIColor.label]
        }

        let titleX = Self.margin + 14
        let titleWidth = Self.contentWidth - 14
        let titleBounding = (task.title as NSString).boundingRect(
            with: CGSize(width: titleWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: titleAttrs,
            context: nil
        )
        (task.title as NSString).draw(
            in: CGRect(x: titleX, y: currentY, width: titleWidth, height: titleBounding.height),
            withAttributes: titleAttrs
        )
        currentY += titleBounding.height + 2

        // Status, priority, due date line
        let statusColor = uiColor(forStatus: task.status)
        let metaString = NSMutableAttributedString()

        let statusAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
            .foregroundColor: statusColor
        ]
        metaString.append(NSAttributedString(string: task.status, attributes: statusAttrs))

        let separatorAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.tertiaryLabel
        ]
        metaString.append(NSAttributedString(string: "  ·  ", attributes: separatorAttrs))

        let priorityAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
            .foregroundColor: dotColor
        ]
        metaString.append(NSAttributedString(string: task.priority, attributes: priorityAttrs))

        metaString.append(NSAttributedString(string: "  ·  ", attributes: separatorAttrs))

        let dateAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.secondaryLabel
        ]
        metaString.append(NSAttributedString(string: "Due: \(dateFormatter.string(from: task.dueDate))", attributes: dateAttrs))

        metaString.draw(in: CGRect(x: titleX, y: currentY, width: titleWidth, height: 16))
        currentY += 16

        // Details (if present)
        if !task.details.isEmpty {
            currentY += 2
            let detailsFont = UIFont.systemFont(ofSize: 10)
            let detailsAttrs: [NSAttributedString.Key: Any] = [
                .font: detailsFont,
                .foregroundColor: UIColor.tertiaryLabel
            ]
            let detailsBounding = (task.details as NSString).boundingRect(
                with: CGSize(width: titleWidth, height: .greatestFiniteMagnitude),
                options: .usesLineFragmentOrigin,
                attributes: detailsAttrs,
                context: nil
            )
            (task.details as NSString).draw(
                in: CGRect(x: titleX, y: currentY, width: titleWidth, height: detailsBounding.height),
                withAttributes: detailsAttrs
            )
            currentY += detailsBounding.height
        }

        currentY += 6

        // Separator line
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: Self.margin, y: currentY))
        linePath.addLine(to: CGPoint(x: Self.margin + Self.contentWidth, y: currentY))
        UIColor.separator.setStroke()
        linePath.lineWidth = 0.25
        linePath.stroke()

        return currentY + 2
    }

    @discardableResult
    private func drawFooter(at y: CGFloat) -> CGFloat {
        let text = "Generated on \(dateFormatter.string(from: Date.now))"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.tertiaryLabel
        ]
        let rect = CGRect(x: Self.margin, y: y, width: Self.contentWidth, height: 14)
        (text as NSString).draw(in: rect, withAttributes: attrs)
        return y + 14
    }

    private func estimateTaskHeight(_ task: PDFTaskInfo) -> CGFloat {
        var height: CGFloat = 40 // title + meta line + padding
        if !task.details.isEmpty {
            let detailsFont = UIFont.systemFont(ofSize: 10)
            let attrs: [NSAttributedString.Key: Any] = [.font: detailsFont]
            let bounding = (task.details as NSString).boundingRect(
                with: CGSize(width: Self.contentWidth - 14, height: .greatestFiniteMagnitude),
                options: .usesLineFragmentOrigin,
                attributes: attrs,
                context: nil
            )
            height += bounding.height + 4
        }
        return height
    }

    // MARK: - Color Helpers

    private func uiColor(forPriorityColorName name: String) -> UIColor {
        switch name {
        case "green": return .systemGreen
        case "orange": return .systemOrange
        case "red": return .systemRed
        default: return .systemGray
        }
    }

    private func uiColor(forStatus status: String) -> UIColor {
        switch status {
        case "Not Started": return .systemGray
        case "In Progress": return .systemBlue
        case "Completed": return .systemGreen
        default: return .systemGray
        }
    }
}



// MARK: - Temporary File Helper

func writePDFToTemporaryFile(data: Data, projectName: String) -> URL? {
    let sanitizedName = projectName.replacingOccurrences(of: " ", with: "_")
    let fileName = "\(sanitizedName)_Report.pdf"
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
    do {
        try data.write(to: url)
        return url
    } catch {
        return nil
    }
}
