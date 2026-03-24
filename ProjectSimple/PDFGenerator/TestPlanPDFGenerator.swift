import UIKit

/// Generates a PDF test plan for TestFlight testers.
struct TestPlanPDFGenerator {

    static let pageWidth: CGFloat = 612
    static let pageHeight: CGFloat = 792
    static let margin: CGFloat = 50
    static let contentWidth: CGFloat = pageWidth - 2 * margin

    func generate() -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: Self.pageWidth, height: Self.pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { context in
            var y: CGFloat = 0

            func newPage() {
                context.beginPage()
                y = Self.margin
            }

            func space(_ needed: CGFloat) {
                if y + needed > Self.pageHeight - Self.margin {
                    newPage()
                }
            }

            // ── Cover Page ──────────────────────────────────────────────

            newPage()
            y = 200
            y = drawCentered("ProjectSimple", at: y, font: .systemFont(ofSize: 36, weight: .bold), color: .label)
            y += 8
            y = drawCentered("TestFlight Test Plan", at: y, font: .systemFont(ofSize: 24, weight: .light), color: .secondaryLabel)
            y += 24
            y = drawCentered("Thank you for helping test ProjectSimple! Please work through the", at: y, font: .systemFont(ofSize: 12), color: .secondaryLabel)
            y += 2
            y = drawCentered("sections below and report any issues via TestFlight feedback.", at: y, font: .systemFont(ofSize: 12), color: .secondaryLabel)

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            y += 30
            y = drawCentered("Generated: \(dateFormatter.string(from: Date.now))", at: y, font: .systemFont(ofSize: 10), color: .tertiaryLabel)

            // ── Table of Contents ────────────────────────────────────────

            newPage()
            y = drawHeading("Table of Contents", at: y)
            y += 4
            let tocItems = [
                "1.  First Launch & Onboarding",
                "2.  Project Management",
                "3.  Task Management",
                "4.  Calendar View",
                "5.  Search & Filters",
                "6.  Statistics Dashboard",
                "7.  Notifications",
                "8.  Home Screen & Lock Screen Widgets",
                "9.  Siri & Shortcuts",
                "10. Export & Import",
                "11. Undo / Redo",
                "12. iCloud Sync",
                "13. Edge Cases & Stress Testing",
                "14. Haptic Feedback"
            ]
            for item in tocItems {
                y = drawBody(item, at: y)
                y += 2
            }

            // ── 1. First Launch & Onboarding ────────────────────────────

            newPage()
            y = drawHeading("1. First Launch & Onboarding", at: y)
            y += 4
            y = drawBody("Verify the initial experience when opening the app for the first time.", at: y)
            y += 8
            y = drawCheckbox("App launches without crashing", at: y)
            y = drawCheckbox("\"Getting Started\" sample project appears with tutorial tasks", at: y)
            y = drawCheckbox("Contextual tips appear (swipe actions, status tap, filter, add step)", at: y)
            y = drawCheckbox("Notification permission prompt appears", at: y)

            // ── 2. Project Management ───────────────────────────────────

            y += 20
            space(60)
            y = drawHeading("2. Project Management", at: y)

            y += 8
            y = drawSubheading("Creating a Project", at: y)
            y += 4
            y = drawCheckbox("Tap + to create a new project", at: y)
            y = drawCheckbox("Fill in name, description, start/end dates, category, and color", at: y)
            y = drawCheckbox("Project appears in the Projects list after tapping Add", at: y)

            y += 8
            space(60)
            y = drawSubheading("Editing a Project", at: y)
            y += 4
            y = drawCheckbox("Swipe right on a project row to access the edit button", at: y)
            y = drawCheckbox("Change project details and verify changes save correctly", at: y)

            y += 8
            space(60)
            y = drawSubheading("Deleting a Project", at: y)
            y += 4
            y = drawCheckbox("Swipe left and tap delete — confirmation dialog appears", at: y)
            y = drawCheckbox("Project and all its tasks are permanently removed", at: y)

            y += 8
            space(60)
            y = drawSubheading("Archiving a Project", at: y)
            y += 4
            y = drawCheckbox("Swipe left and tap archive (orange button)", at: y)
            y = drawCheckbox("Project moves to the Archive tab", at: y)
            y = drawCheckbox("Unarchive from the Archive tab — project returns to Projects", at: y)

            // ── 3. Task Management ──────────────────────────────────────

            y += 20
            space(60)
            y = drawHeading("3. Task Management", at: y)

            y += 8
            y = drawSubheading("Creating a Task", at: y)
            y += 4
            y = drawCheckbox("Open a project, tap menu (...) → Add Task", at: y)
            y = drawCheckbox("Fill in title, details, due date, priority (Low/Medium/High)", at: y)
            y = drawCheckbox("Add steps (checklist items) to the task", at: y)
            y = drawCheckbox("Task appears in the project's task list after tapping Add", at: y)

            y += 8
            space(60)
            y = drawSubheading("Task Status", at: y)
            y += 4
            y = drawCheckbox("Tap the status icon to cycle: Not Started → In Progress → Completed", at: y)
            y = drawCheckbox("Status icon updates correctly (empty circle → half-filled → checkmark)", at: y)
            y = drawCheckbox("Project progress bar updates when task status changes", at: y)

            y += 8
            space(60)
            y = drawSubheading("Editing, Deleting & Archiving Tasks", at: y)
            y += 4
            y = drawCheckbox("Swipe right to edit a task — changes save correctly", at: y)
            y = drawCheckbox("Swipe left to delete a task", at: y)
            y = drawCheckbox("Swipe left to archive a task", at: y)

            y += 8
            space(60)
            y = drawSubheading("Steps (Subtasks)", at: y)
            y += 4
            y = drawCheckbox("Add a step — it appears in the checklist", at: y)
            y = drawCheckbox("Toggle a step complete/incomplete (strikethrough appears)", at: y)
            y = drawCheckbox("Delete a step via swipe", at: y)
            y = drawCheckbox("Reorder steps via drag and drop", at: y)
            y = drawCheckbox("Step count (e.g. \"2/5 steps\") shows correctly on the task row", at: y)

            y += 8
            space(60)
            y = drawSubheading("Recurring Tasks", at: y)
            y += 4
            y = drawCheckbox("Create a task with recurrence (Daily, Weekly, Biweekly, Monthly, Yearly)", at: y)
            y = drawCheckbox("Complete the recurring task — a new occurrence is auto-created", at: y)
            y = drawCheckbox("New occurrence has the correct next due date", at: y)
            y = drawCheckbox("Steps on the new occurrence are reset to incomplete", at: y)

            // ── 4. Calendar View ────────────────────────────────────────

            y += 20
            space(60)
            y = drawHeading("4. Calendar View", at: y)
            y += 4
            y = drawCheckbox("Navigate between months using the arrow buttons", at: y)
            y = drawCheckbox("Today's date is highlighted in blue", at: y)
            y = drawCheckbox("Colored dots appear on days that have tasks", at: y)
            y = drawCheckbox("Tap a date — tasks due that day appear below", at: y)
            y = drawCheckbox("With no date selected, overdue tasks section appears", at: y)
            y = drawCheckbox("Tap a task to navigate to its project", at: y)

            // ── 5. Search & Filters ─────────────────────────────────────

            y += 20
            space(60)
            y = drawHeading("5. Search & Filters", at: y)
            y += 4
            y = drawCheckbox("Type in the search bar — results match project names and task titles", at: y)
            y = drawCheckbox("Tap the filter icon and select a priority (High/Medium/Low)", at: y)
            y = drawCheckbox("Tap the filter icon and select a category", at: y)
            y = drawCheckbox("Combine text search with filters — results narrow correctly", at: y)
            y = drawCheckbox("\"No Results\" message appears for unmatched searches", at: y)

            // ── 6. Statistics Dashboard ─────────────────────────────────

            y += 20
            space(60)
            y = drawHeading("6. Statistics Dashboard", at: y)
            y += 4
            y = drawCheckbox("Overview cards show correct counts (Projects, Tasks, Completed, Overdue)", at: y)
            y = drawCheckbox("Completion rate percentage matches actual data", at: y)
            y = drawCheckbox("\"This Week\" section shows recently completed tasks", at: y)
            y = drawCheckbox("4-week completion trend bar chart displays correctly", at: y)
            y = drawCheckbox("Most Productive Day chart highlights the correct day", at: y)
            y = drawCheckbox("Priority donut chart and Category bar chart render correctly", at: y)

            // ── 7. Notifications ────────────────────────────────────────

            y += 20
            space(60)
            y = drawHeading("7. Notifications", at: y)
            y += 4
            y = drawBody("Ensure notifications are enabled in Settings → ProjectSimple → Notifications.", at: y)
            y += 6
            y = drawCheckbox("Task due today — notification arrives at 9:00 AM", at: y)
            y = drawCheckbox("Task due soon — notification arrives 5 days before due date", at: y)
            y = drawCheckbox("App badge shows count of overdue + due-today tasks", at: y)
            y = drawCheckbox("Completing a task updates the badge count", at: y)

            // ── 8. Widgets ──────────────────────────────────────────────

            y += 20
            space(60)
            y = drawHeading("8. Home Screen & Lock Screen Widgets", at: y)
            y += 4
            y = drawBody("Long-press home screen → tap + → search \"ProjectSimple\" to add widgets.", at: y)
            y += 6

            y = drawSubheading("Home Screen Widgets", at: y)
            y += 4
            y = drawCheckbox("Small widget — shows overdue count and up to 3 task titles", at: y)
            y = drawCheckbox("Medium widget — shows up to 4 tasks with project names and priority dots", at: y)
            y = drawCheckbox("Widgets show \"All caught up!\" when no tasks are due", at: y)
            y = drawCheckbox("Tapping a widget opens the app", at: y)

            y += 8
            space(60)
            y = drawSubheading("Lock Screen Widgets", at: y)
            y += 4
            y = drawCheckbox("Circular widget — displays overdue task count", at: y)
            y = drawCheckbox("Rectangular widget — shows up to 2 overdue task titles", at: y)

            // ── 9. Siri & Shortcuts ─────────────────────────────────────

            y += 20
            space(60)
            y = drawHeading("9. Siri & Shortcuts", at: y)
            y += 4
            y = drawBody("Test each voice command by saying \"Hey Siri\" followed by the phrase.", at: y)
            y += 6
            y = drawCheckbox("\"Create a new project in ProjectSimple\" — opens Add Project screen", at: y)
            y = drawCheckbox("\"Add a task in ProjectSimple\" — prompts for project, opens Add Task", at: y)
            y = drawCheckbox("\"Show overdue tasks in ProjectSimple\" — Siri reads up to 5 overdue tasks", at: y)
            y = drawCheckbox("\"Task summary in ProjectSimple\" — Siri reports active, overdue, due-today counts", at: y)
            y = drawCheckbox("\"Mark task done in ProjectSimple\" — completes a task without opening app", at: y)

            // ── 10. Export & Import ─────────────────────────────────────

            y += 20
            space(60)
            y = drawHeading("10. Export & Import", at: y)

            y += 8
            y = drawSubheading("PDF Export", at: y)
            y += 4
            y = drawCheckbox("Open a project → menu (...) → Export as PDF", at: y)
            y = drawCheckbox("PDF includes project info, progress bar, and full task list", at: y)
            y = drawCheckbox("Share sheet appears — save, AirDrop, email, or print", at: y)

            y += 8
            space(60)
            y = drawSubheading("JSON Backup", at: y)
            y += 4
            y = drawCheckbox("Projects tab → gear icon → Export Data → share the JSON file", at: y)
            y = drawCheckbox("Projects tab → gear icon → Import Data → pick a .json file", at: y)
            y = drawCheckbox("Imported data appears alongside existing projects", at: y)

            // ── 11. Undo / Redo ─────────────────────────────────────────

            y += 20
            space(60)
            y = drawHeading("11. Undo / Redo", at: y)
            y += 4
            y = drawCheckbox("Delete a task, then tap Undo — task is restored", at: y)
            y = drawCheckbox("Archive a project, then tap Undo — project returns", at: y)
            y = drawCheckbox("Tap Redo after undoing — action is re-applied", at: y)
            y = drawCheckbox("Perform multiple actions in a row, then undo each one sequentially", at: y)

            // ── 12. iCloud Sync ─────────────────────────────────────────

            y += 20
            space(60)
            y = drawHeading("12. iCloud Sync", at: y)
            y += 4
            y = drawBody("Test with two devices signed into the same iCloud account.", at: y)
            y += 6
            y = drawCheckbox("Create a project on Device A — it appears on Device B", at: y)
            y = drawCheckbox("Complete a task on Device B — status updates on Device A", at: y)
            y = drawCheckbox("Background the app, make changes on another device, reopen — data syncs", at: y)

            // ── 13. Edge Cases & Stress Testing ─────────────────────────

            y += 20
            space(60)
            y = drawHeading("13. Edge Cases & Stress Testing", at: y)
            y += 4
            y = drawCheckbox("Create 10+ projects and 50+ tasks — app remains responsive", at: y)
            y = drawCheckbox("Use the app offline, then reconnect — data persists", at: y)
            y = drawCheckbox("Background and reopen the app repeatedly — no crashes", at: y)
            y = drawCheckbox("Rotate between portrait and landscape (iPad)", at: y)
            y = drawCheckbox("Test with Dynamic Type set to largest accessibility size", at: y)
            y = drawCheckbox("Test with VoiceOver enabled — all elements are accessible", at: y)
            y = drawCheckbox("Empty states: no projects, no tasks, no search results", at: y)

            // ── 14. Haptic Feedback ─────────────────────────────────────

            y += 20
            space(60)
            y = drawHeading("14. Haptic Feedback", at: y)
            y += 4
            y = drawCheckbox("Medium haptic when completing a task", at: y)
            y = drawCheckbox("Light haptic when toggling a step checkbox", at: y)
            y = drawCheckbox("Success haptic when all tasks in a project are completed", at: y)
            y = drawCheckbox("Toggle haptics off (gear menu) — haptics stop", at: y)
            y = drawCheckbox("Toggle haptics back on — haptics resume", at: y)

            // ── Notes Section ───────────────────────────────────────────

            y += 30
            space(120)
            y = drawHeading("Notes", at: y)
            y += 8
            y = drawBody("Use this space to write down any issues, observations, or suggestions:", at: y)
            y += 12

            // Draw lined area for notes
            for _ in 0..<8 {
                space(24)
                let linePath = UIBezierPath()
                linePath.move(to: CGPoint(x: Self.margin, y: y))
                linePath.addLine(to: CGPoint(x: Self.margin + Self.contentWidth, y: y))
                UIColor.separator.setStroke()
                linePath.lineWidth = 0.5
                linePath.stroke()
                y += 24
            }
        }
    }

    // MARK: - Drawing Helpers

    private func drawCentered(_ text: String, at y: CGFloat, font: UIFont, color: UIColor) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let size = (text as NSString).boundingRect(
            with: CGSize(width: Self.contentWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin, attributes: attrs, context: nil
        )
        let x = Self.margin + (Self.contentWidth - size.width) / 2
        (text as NSString).draw(in: CGRect(x: x, y: y, width: size.width + 1, height: size.height), withAttributes: attrs)
        return y + size.height
    }

    private func drawHeading(_ text: String, at y: CGFloat) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 20, weight: .bold)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.label]
        let size = (text as NSString).boundingRect(
            with: CGSize(width: Self.contentWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin, attributes: attrs, context: nil
        )
        (text as NSString).draw(in: CGRect(x: Self.margin, y: y, width: Self.contentWidth, height: size.height), withAttributes: attrs)

        let lineY = y + size.height + 2
        let path = UIBezierPath()
        path.move(to: CGPoint(x: Self.margin, y: lineY))
        path.addLine(to: CGPoint(x: Self.margin + Self.contentWidth, y: lineY))
        UIColor.separator.setStroke()
        path.lineWidth = 0.5
        path.stroke()

        return lineY + 4
    }

    private func drawSubheading(_ text: String, at y: CGFloat) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.label]
        let size = (text as NSString).boundingRect(
            with: CGSize(width: Self.contentWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin, attributes: attrs, context: nil
        )
        (text as NSString).draw(in: CGRect(x: Self.margin, y: y, width: Self.contentWidth, height: size.height), withAttributes: attrs)
        return y + size.height
    }

    private func drawBody(_ text: String, at y: CGFloat) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 11)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.darkGray
        ]
        let size = (text as NSString).boundingRect(
            with: CGSize(width: Self.contentWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin, attributes: attrs, context: nil
        )
        (text as NSString).draw(in: CGRect(x: Self.margin, y: y, width: Self.contentWidth, height: size.height), withAttributes: attrs)
        return y + size.height
    }

    private func drawCheckbox(_ text: String, at y: CGFloat) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 11)
        let indent: CGFloat = 24
        let textX = Self.margin + indent
        let textWidth = Self.contentWidth - indent

        // Draw checkbox square
        let boxSize: CGFloat = 10
        let boxRect = CGRect(x: Self.margin + 2, y: y + 1, width: boxSize, height: boxSize)
        let boxPath = UIBezierPath(roundedRect: boxRect, cornerRadius: 2)
        UIColor.systemGray3.setStroke()
        boxPath.lineWidth = 1.0
        boxPath.stroke()

        // Draw text
        let textAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.darkGray]
        let size = (text as NSString).boundingRect(
            with: CGSize(width: textWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin, attributes: textAttrs, context: nil
        )
        (text as NSString).draw(in: CGRect(x: textX, y: y, width: textWidth, height: size.height), withAttributes: textAttrs)
        return y + max(size.height, boxSize) + 4
    }
}
