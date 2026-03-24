import UIKit

/// Generates a static PDF user guide for the ProjectSimple app.
struct UserGuidePDFGenerator {

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
            y = drawCentered("User Guide", at: y, font: .systemFont(ofSize: 24, weight: .light), color: .secondaryLabel)
            y += 24
            y = drawCentered("A project and task management app for iPhone, iPad, and Apple Watch.", at: y, font: .systemFont(ofSize: 14), color: .secondaryLabel)

            // ── Table of Contents ────────────────────────────────────────

            newPage()
            y = drawHeading("Table of Contents", at: y)
            y += 4
            let tocItems = [
                "1.  Getting Started",
                "2.  App Navigation",
                "3.  Managing Projects",
                "4.  Managing Tasks",
                "5.  Task Steps (Subtasks)",
                "6.  Recurring Tasks",
                "7.  Calendar View",
                "8.  Search & Filters",
                "9.  Archive & Completed Items",
                "10. PDF Export",
                "11. Data Backup (Export & Import)",
                "12. Notifications",
                "13. Home Screen Widgets",
                "14. Siri Shortcuts",
                "15. iPad Features",
                "16. Haptic Feedback",
                "17. Statistics Dashboard",
                "18. Apple Watch App",
                "19. iCloud Sync",
                "20. Tips & Tricks"
            ]
            for item in tocItems {
                y = drawBody(item, at: y)
                y += 2
            }

            // ── 1. Getting Started ──────────────────────────────────────

            newPage()
            y = drawHeading("1. Getting Started", at: y)
            y += 4
            y = drawBody("When you first launch ProjectSimple, a sample \"Getting Started\" project is created with six tutorial tasks that walk you through the app's features. If you start with an empty project list (for example, after syncing from another device), you can tap the \"Load Sample Project\" button to add the tutorial project at any time. You can complete, edit, or delete these tasks as you explore.", at: y)

            // ── 2. App Navigation ───────────────────────────────────────

            y += 20
            space(100)
            y = drawHeading("2. App Navigation", at: y)
            y += 4
            y = drawBody("The app has five main tabs at the bottom of the screen:", at: y)
            y += 6
            let tabs = [
                ("Calendar", "View tasks by date and see overdue items."),
                ("Projects", "Browse, create, and manage all your projects."),
                ("Search", "Find tasks and projects with text search and filters."),
                ("Statistics", "View completion rates, weekly trends, and productivity insights."),
                ("Archive", "Access archived and completed items.")
            ]
            for tab in tabs {
                space(30)
                y = drawBullet(tab.0, detail: tab.1, at: y)
            }
            y += 6
            y = drawBody("On iPad, these tabs can also appear as a collapsible sidebar.", at: y)

            // ── 3. Managing Projects ────────────────────────────────────

            y += 20
            space(60)
            y = drawHeading("3. Managing Projects", at: y)

            y += 8
            y = drawSubheading("Creating a Project", at: y)
            y += 4
            y = drawNumbered(1, "Go to the Projects tab.", at: y)
            y = drawNumbered(2, "Tap the + button (top right).", at: y)
            y = drawNumbered(3, "Fill in the project details:", at: y)
            let fields = [
                "Name (required)",
                "Description (optional)",
                "Start Date and End Date",
                "Category — Work, Personal, Education, Health, Finance, or Other",
                "Color — Choose from six accent colors"
            ]
            for field in fields {
                y = drawBullet(field, at: y, indent: 40)
            }
            y = drawNumbered(4, "Tap Add.", at: y)

            y += 8
            space(60)
            y = drawSubheading("Viewing a Project", at: y)
            y += 4
            y = drawBody("Tap any project in the list to see its detail view, which includes the project description, category, dates, a progress bar showing completion percentage, status badges (To Do, In Progress, Done counts), and the full task list sorted by status, priority, then due date.", at: y)

            y += 8
            space(60)
            y = drawSubheading("Editing a Project", at: y)
            y += 4
            y = drawBullet("Swipe left on a project row and tap the blue edit button.", at: y)
            y = drawBullet("Or open the project detail view, tap the menu (...) at the top right, and select Edit Project.", at: y)

            y += 8
            space(40)
            y = drawSubheading("Deleting a Project", at: y)
            y += 4
            y = drawBody("Swipe left on a project row and tap the red delete button. A confirmation dialog will appear — this permanently deletes the project and all its tasks.", at: y)

            y += 8
            space(40)
            y = drawSubheading("Archiving a Project", at: y)
            y += 4
            y = drawBody("Swipe left on a project row and tap the orange archive button, or select Archive Project from the project detail menu. Archived projects move to the Archive tab.", at: y)

            // ── 4. Managing Tasks ───────────────────────────────────────

            y += 20
            space(60)
            y = drawHeading("4. Managing Tasks", at: y)

            y += 8
            y = drawSubheading("Creating a Task", at: y)
            y += 4
            y = drawNumbered(1, "Open a project's detail view.", at: y)
            y = drawNumbered(2, "Tap the menu (...) at the top right and select Add Task.", at: y)
            y = drawNumbered(3, "Fill in Title (required), Details, Due Date, Priority (Low/Medium/High), Recurrence, and Steps.", at: y)
            y = drawNumbered(4, "Tap Add.", at: y)

            y += 8
            space(60)
            y = drawSubheading("Changing Task Status", at: y)
            y += 4
            y = drawBody("Each task has a status icon on its left side. Tap the icon to cycle through:", at: y)
            y += 4
            y = drawBullet("Not Started (empty circle)", at: y)
            y = drawBullet("In Progress (half-filled circle)", at: y)
            y = drawBullet("Completed (green checkmark)", at: y)

            y += 8
            space(40)
            y = drawSubheading("Editing, Deleting, and Archiving Tasks", at: y)
            y += 4
            y = drawBullet("Swipe right on a task row for the blue edit button.", at: y)
            y = drawBullet("Swipe left for archive (orange) and delete (red) buttons.", at: y)

            y += 8
            space(40)
            y = drawSubheading("Task Priority Colors", at: y)
            y += 4
            y = drawBullet("High — Red", at: y)
            y = drawBullet("Medium — Orange", at: y)
            y = drawBullet("Low — Green", at: y)

            // ── 5. Task Steps ───────────────────────────────────────────

            y += 20
            space(60)
            y = drawHeading("5. Task Steps (Subtasks)", at: y)
            y += 4
            y = drawBody("Steps let you break a task into smaller checklist items.", at: y)

            y += 8
            y = drawSubheading("Adding Steps", at: y)
            y += 4
            y = drawNumbered(1, "When creating or editing a task, scroll to the Steps section.", at: y)
            y = drawNumbered(2, "Type a step title in the text field.", at: y)
            y = drawNumbered(3, "Tap the + button to add it.", at: y)

            y += 8
            space(60)
            y = drawSubheading("Managing Steps", at: y)
            y += 4
            y = drawBullet("Tap the checkbox next to a step to mark it complete (strikethrough appears).", at: y)
            y = drawBullet("Swipe left on a step to delete it.", at: y)
            y = drawBullet("Drag steps to reorder them.", at: y)
            y += 4
            y = drawBody("A counter like \"2/5 steps\" appears on task rows when steps exist.", at: y)

            y += 8
            space(40)
            y = drawSubheading("Steps and Recurring Tasks", at: y)
            y += 4
            y = drawBody("When a recurring task is completed and a new occurrence is generated, all steps are copied to the new task with their completion reset — so you start fresh each cycle.", at: y)

            // ── 6. Recurring Tasks ──────────────────────────────────────

            y += 20
            space(80)
            y = drawHeading("6. Recurring Tasks", at: y)
            y += 4
            y = drawBody("Set a recurrence rule when creating or editing a task:", at: y)
            y += 6
            let rules = [
                ("None", "One-time task"),
                ("Daily", "New occurrence due the next day"),
                ("Weekly", "New occurrence due in 7 days"),
                ("Biweekly", "New occurrence due in 14 days"),
                ("Monthly", "New occurrence due next month (same day)"),
                ("Yearly", "New occurrence due next year (same day)")
            ]
            for rule in rules {
                space(24)
                y = drawBullet(rule.0, detail: rule.1, at: y)
            }
            y += 6
            y = drawBody("When you mark a recurring task as Completed, the app automatically creates a new task with the next due date. The original completed task remains in your history. The new task inherits the title, details, priority, recurrence rule, and steps (reset to uncompleted).", at: y)

            // ── 7. Calendar View ────────────────────────────────────────

            y += 20
            space(60)
            y = drawHeading("7. Calendar View", at: y)
            y += 4
            y = drawBody("The Calendar tab shows a monthly calendar with your tasks.", at: y)

            y += 8
            y = drawSubheading("Navigation & Indicators", at: y)
            y += 4
            y = drawBullet("Use the arrow buttons next to the month name to move between months.", at: y)
            y = drawBullet("Blue highlight — Today's date.", at: y)
            y = drawBullet("Colored dots below a date — Tasks due that day (colors match project colors, up to 3 shown).", at: y)

            y += 8
            space(40)
            y = drawSubheading("Viewing Tasks", at: y)
            y += 4
            y = drawBullet("Tap a date to see all non-completed tasks due that day.", at: y)
            y = drawBullet("With no date selected, the view shows an Overdue Tasks section listing all past-due incomplete tasks, sorted oldest first.", at: y)
            y = drawBullet("Tap any task row to navigate to its project.", at: y)

            // ── 8. Search & Filters ─────────────────────────────────────

            y += 20
            space(60)
            y = drawHeading("8. Search & Filters", at: y)
            y += 4
            y = drawBody("The Search tab lets you find tasks and projects across your entire app. Type in the search bar to filter by project names, descriptions, task titles, and details. Results are grouped into Projects and Tasks sections.", at: y)

            y += 8
            y = drawSubheading("Filtering", at: y)
            y += 4
            y = drawNumbered(1, "Tap the filter icon (top right).", at: y)
            y = drawNumbered(2, "Select a Priority (High, Medium, Low) and/or Category.", at: y)
            y = drawNumbered(3, "The filter icon fills in to indicate an active filter.", at: y)
            y += 4
            y = drawBody("You can combine text search with filters. To clear a filter, tap the same option again.", at: y)

            // ── 9. Archive & Completed ──────────────────────────────────

            y += 20
            space(60)
            y = drawHeading("9. Archive & Completed Items", at: y)
            y += 4
            y = drawBody("The Archive tab has two sections, toggled by a segmented control:", at: y)

            y += 8
            y = drawSubheading("Archived Section", at: y)
            y += 4
            y = drawBullet("Shows projects and tasks you've explicitly archived.", at: y)
            y = drawBullet("Swipe left to Unarchive (returns to active list).", at: y)
            y = drawBullet("Swipe right to Delete permanently.", at: y)

            y += 8
            space(50)
            y = drawSubheading("Completed Section", at: y)
            y += 4
            y = drawBullet("Shows projects where all tasks are complete, and individual completed tasks.", at: y)
            y = drawBullet("Swipe left on a completed task to Reopen it (sets status to In Progress).", at: y)
            y = drawBullet("Swipe right to Archive it.", at: y)

            // ── 10. PDF Export ──────────────────────────────────────────

            y += 20
            space(80)
            y = drawHeading("10. PDF Export", at: y)
            y += 4
            y = drawBody("You can generate a formatted PDF report for any project:", at: y)
            y += 4
            y = drawNumbered(1, "Open a project's detail view.", at: y)
            y = drawNumbered(2, "Tap the menu (...) at the top right.", at: y)
            y = drawNumbered(3, "Select Export as PDF.", at: y)
            y = drawNumbered(4, "The share sheet appears — save to Files, AirDrop, email, print, etc.", at: y)
            y += 4
            y = drawBody("The PDF includes the project name, description, category, date range, a progress bar with completion percentage, status count summary, and the full task list with priority indicators.", at: y)

            // ── 11. Data Backup ─────────────────────────────────────────

            y += 20
            space(80)
            y = drawHeading("11. Data Backup (Export & Import)", at: y)
            y += 4
            y = drawBody("Back up all your data as a JSON file and restore it later. Especially useful if you need to delete and reinstall the app.", at: y)

            y += 8
            y = drawSubheading("Exporting Data", at: y)
            y += 4
            y = drawNumbered(1, "Go to the Projects tab.", at: y)
            y = drawNumbered(2, "Tap the gear icon (top left).", at: y)
            y = drawNumbered(3, "Select Export Data.", at: y)
            y = drawNumbered(4, "Save the JSON file via the share sheet.", at: y)
            y += 4
            y = drawBody("The export includes all projects, tasks, steps, and their states — active, archived, and completed.", at: y)

            y += 8
            space(80)
            y = drawSubheading("Importing Data", at: y)
            y += 4
            y = drawNumbered(1, "Go to the Projects tab.", at: y)
            y = drawNumbered(2, "Tap the gear icon (top left).", at: y)
            y = drawNumbered(3, "Select Import Data.", at: y)
            y = drawNumbered(4, "Pick a .json backup file from the file picker.", at: y)
            y += 4
            y = drawBody("Import is additive — imported projects are added alongside existing data, not replacing it. Imported items get fresh IDs, so you can import the same backup multiple times without conflicts.", at: y)

            // ── 12. Notifications ───────────────────────────────────────

            y += 20
            space(80)
            y = drawHeading("12. Notifications", at: y)
            y += 4
            y = drawBody("ProjectSimple can send reminders for upcoming tasks and project deadlines. The app requests notification permission on first launch.", at: y)

            y += 8
            y = drawSubheading("Notification Schedule", at: y)
            y += 4
            y = drawBullet("Task due date — Day of at 9:00 AM", at: y)
            y = drawBullet("Task due soon — 5 days before at 9:00 AM", at: y)
            y = drawBullet("Project end date — Day of at 9:00 AM", at: y)
            y = drawBullet("Project end soon — 5 days before at 9:00 AM", at: y)
            y += 4
            y = drawBody("Completed tasks and archived projects do not generate notifications. The app icon badge shows the total number of overdue tasks plus tasks due today.", at: y)

            // ── 13. Home Screen Widgets ─────────────────────────────────

            y += 20
            space(80)
            y = drawHeading("13. Home Screen Widgets", at: y)
            y += 4
            y = drawBody("Add widgets to see your tasks at a glance. Long-press your home screen, tap +, search for ProjectSimple, and choose a widget size.", at: y)

            y += 8
            y = drawSubheading("Available Widgets", at: y)
            y += 4
            y = drawBullet("Small", detail: "Overdue count with up to 3 task titles, sorted by priority.", at: y)
            y = drawBullet("Medium", detail: "Overdue count, up to 4 tasks with project names and priority dots.", at: y)
            y = drawBullet("Lock Screen (Circular)", detail: "Overdue task count.", at: y)
            y = drawBullet("Lock Screen (Rectangular)", detail: "Up to 2 overdue task titles.", at: y)
            y += 4
            y = drawBody("Tapping any widget opens the app to the Calendar view. Widgets refresh at midnight and whenever you make changes in the app.", at: y)

            // ── 14. Siri Shortcuts ──────────────────────────────────────

            y += 20
            space(80)
            y = drawHeading("14. Siri Shortcuts", at: y)
            y += 4
            y = drawBody("Use Siri voice commands and the Shortcuts app with ProjectSimple:", at: y)
            y += 6
            let siriCommands = [
                ("\"Create a new project\"", "Opens the app to the Add Project screen."),
                ("\"Add a task in [Project]\"", "Opens the specific project with the Add Task screen."),
                ("\"Show overdue tasks\"", "Siri reads out up to 5 overdue tasks without opening the app."),
                ("\"Task summary\"", "Siri tells you active, overdue, and due-today task counts."),
                ("\"Mark [Task] done\"", "Marks a task as completed (handles recurrence automatically).")
            ]
            for cmd in siriCommands {
                space(30)
                y = drawBullet(cmd.0, detail: cmd.1, at: y)
            }
            y += 4
            y = drawBody("All five intents are available in the Shortcuts app for custom automations.", at: y)

            // ── 15. iPad Features ───────────────────────────────────────

            y += 20
            space(80)
            y = drawHeading("15. iPad Features", at: y)
            y += 4
            y = drawBody("ProjectSimple adapts its layout for the larger iPad screen:", at: y)
            y += 6
            y = drawBullet("Sidebar Navigation", detail: "The tab bar transforms into a collapsible sidebar on iPad.", at: y)
            y = drawBullet("Split View for Projects", detail: "Two-column layout with project list on the left and detail view on the right.", at: y)
            y = drawBullet("Calendar Split Layout", detail: "In landscape, the calendar grid appears on the left and the task list on the right.", at: y)
            y = drawBullet("Multitasking", detail: "Supports iPad Split View and Slide Over.", at: y)

            // ── 16. Haptic Feedback ──────────────────────────────────────

            y += 20
            space(80)
            y = drawHeading("16. Haptic Feedback", at: y)
            y += 4
            y = drawBody("ProjectSimple provides tactile feedback for key actions so you can feel when something happens.", at: y)

            y += 8
            y = drawSubheading("Haptic Events", at: y)
            y += 4
            y = drawBullet("Task completed", detail: "A medium impact tap when you mark a task as completed.", at: y)
            y = drawBullet("Step toggled", detail: "A light tap when you check or uncheck a step in the edit view.", at: y)
            y = drawBullet("Milestone reached", detail: "A success notification when all tasks in a project are completed.", at: y)

            y += 8
            space(40)
            y = drawSubheading("Turning Haptics On/Off", at: y)
            y += 4
            y = drawNumbered(1, "Go to the Projects tab.", at: y)
            y = drawNumbered(2, "Tap the gear icon (top left).", at: y)
            y = drawNumbered(3, "Toggle Haptic Feedback on or off.", at: y)
            y += 4
            y = drawBody("Haptic feedback is enabled by default. Your preference is saved and persists between app launches.", at: y)

            // ── 17. Statistics Dashboard ─────────────────────────────────

            y += 20
            space(80)
            y = drawHeading("17. Statistics Dashboard", at: y)
            y += 4
            y = drawBody("The Statistics tab gives you insights into your productivity with six sections of data and charts.", at: y)

            y += 8
            y = drawSubheading("Overview", at: y)
            y += 4
            y = drawBody("Four stat cards showing active project count, total tasks, completed tasks, and overdue tasks. A progress bar shows your overall completion rate as a percentage.", at: y)

            y += 8
            space(40)
            y = drawSubheading("This Week", at: y)
            y += 4
            y = drawBody("Shows how many tasks you completed this week, along with up to five recently completed tasks and which project they belong to.", at: y)

            y += 8
            space(40)
            y = drawSubheading("Completion Trend", at: y)
            y += 4
            y = drawBody("A bar chart showing the number of tasks completed per week over the last four weeks, so you can see whether your productivity is trending up or down.", at: y)

            y += 8
            space(40)
            y = drawSubheading("Most Productive Day", at: y)
            y += 4
            y = drawBody("Identifies which day of the week you complete the most tasks. A bar chart breaks down completions by day (Sunday through Saturday), with the top day highlighted.", at: y)

            y += 8
            space(40)
            y = drawSubheading("Tasks by Priority", at: y)
            y += 4
            y = drawBody("A donut chart showing the breakdown of your active (non-completed) tasks by priority level: High (red), Medium (orange), and Low (green).", at: y)

            y += 8
            space(40)
            y = drawSubheading("Tasks by Category", at: y)
            y += 4
            y = drawBody("A horizontal bar chart showing how your active tasks are distributed across project categories (Work, Personal, Education, Health, Finance, Other).", at: y)

            // ── 18. Apple Watch App ──────────────────────────────────────

            y += 20
            space(80)
            y = drawHeading("18. Apple Watch App", at: y)
            y += 4
            y = drawBody("ProjectSimple includes a companion Apple Watch app that lets you view your tasks and make quick updates right from your wrist.", at: y)

            y += 8
            y = drawSubheading("What You Can Do on the Watch", at: y)
            y += 4
            y = drawBullet("View overdue tasks", detail: "Tasks past their due date appear in a dedicated Overdue section.", at: y)
            y = drawBullet("View today's tasks", detail: "Tasks due today sorted by priority.", at: y)
            y = drawBullet("Browse projects", detail: "See all active projects with completion percentages.", at: y)
            y = drawBullet("Cycle task status", detail: "Tap the status icon to move a task from Not Started to In Progress to Completed.", at: y)
            y = drawBullet("Toggle steps", detail: "Open a task's detail view to check off individual steps.", at: y)

            y += 8
            space(60)
            y = drawSubheading("Data Sync", at: y)
            y += 4
            y = drawBody("The watch app shares the same data as the iPhone app via iCloud. Changes made on either device sync automatically. Pull down on the watch task list to refresh and pick up the latest changes.", at: y)

            y += 8
            space(60)
            y = drawSubheading("Watch Navigation", at: y)
            y += 4
            y = drawBody("The watch app has three main sections on its home screen:", at: y)
            y += 4
            y = drawBullet("Overdue", detail: "Red-highlighted section showing past-due tasks (only appears when there are overdue items).", at: y)
            y = drawBullet("Today", detail: "Tasks due today. Shows a green checkmark if there are none.", at: y)
            y = drawBullet("Projects", detail: "Tap a project to see its tasks and completion progress.", at: y)
            y += 4
            y = drawBody("Tap any task to see its full detail including steps, priority, due date, and recurrence info. Haptic feedback confirms status changes on the watch.", at: y)

            // ── 19. iCloud Sync ─────────────────────────────────────────

            y += 20
            space(80)
            y = drawHeading("19. iCloud Sync", at: y)
            y += 4
            y = drawBody("ProjectSimple automatically syncs your projects and tasks across all your Apple devices using iCloud. Changes you make on one device appear on the others.", at: y)

            y += 8
            y = drawSubheading("How It Works", at: y)
            y += 4
            y = drawBullet("Automatic sync", detail: "Projects, tasks, and steps sync in the background via iCloud whenever you make changes.", at: y)
            y = drawBullet("All devices", detail: "Works across iPhone, iPad, and Apple Watch when signed into the same iCloud account.", at: y)
            y = drawBullet("No setup needed", detail: "Sync is enabled automatically. Just make sure iCloud is turned on in Settings.", at: y)

            y += 8
            space(60)
            y = drawSubheading("Things to Know", at: y)
            y += 4
            y = drawBullet("First launch on a new device may take a moment while data syncs from iCloud.", at: y)
            y = drawBullet("Changes sync when your device has a network connection. Edits made offline will sync the next time you're connected.", at: y)
            y = drawBullet("If you see an empty project list on a new device, wait a moment for sync to complete or tap \"Load Sample Project\" to get started right away.", at: y)

            // ── 20. Tips & Tricks ───────────────────────────────────────

            y += 20
            space(100)
            y = drawHeading("20. Tips & Tricks", at: y)
            y += 4
            let tips = [
                "Quick status change — Tap the status icon on any task to cycle through statuses without opening the edit view.",
                "Swipe gestures — Swipe right to edit, swipe left to archive or delete. Works on both project and task rows.",
                "Overdue at a glance — Check the Calendar tab with no date selected to see all overdue tasks in one list.",
                "Backup before testing — Use Export Data before deleting the app to preserve your test data.",
                "Widget for accountability — Add the medium home screen widget to always see your overdue tasks.",
                "Siri for quick checks — Ask Siri for your task summary without picking up your phone.",
                "Statistics insights — Check the Statistics tab weekly to see your completion trends and most productive day.",
                "Watch quick actions — Use your Apple Watch to quickly mark tasks done without pulling out your phone.",
                "iCloud sync — Your data syncs automatically across all your devices. Changes appear within seconds when connected to the internet."
            ]
            for tip in tips {
                space(30)
                y = drawBullet(tip, at: y)
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

    private func drawBullet(_ text: String, at y: CGFloat, indent: CGFloat = 20) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 11)
        let bulletAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.systemBlue]
        let textAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.darkGray]
        let textX = Self.margin + indent
        let textWidth = Self.contentWidth - indent

        (String("•") as NSString).draw(in: CGRect(x: Self.margin + indent - 12, y: y, width: 12, height: 16), withAttributes: bulletAttrs)

        let size = (text as NSString).boundingRect(
            with: CGSize(width: textWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin, attributes: textAttrs, context: nil
        )
        (text as NSString).draw(in: CGRect(x: textX, y: y, width: textWidth, height: size.height), withAttributes: textAttrs)
        return y + size.height + 2
    }

    private func drawBullet(_ label: String, detail: String, at y: CGFloat) -> CGFloat {
        let boldFont = UIFont.systemFont(ofSize: 11, weight: .semibold)
        let normalFont = UIFont.systemFont(ofSize: 11)
        let indent: CGFloat = 20
        let textX = Self.margin + indent
        let textWidth = Self.contentWidth - indent

        let bulletAttrs: [NSAttributedString.Key: Any] = [.font: normalFont, .foregroundColor: UIColor.systemBlue]
        ("•" as NSString).draw(in: CGRect(x: Self.margin + indent - 12, y: y, width: 12, height: 16), withAttributes: bulletAttrs)

        let attributed = NSMutableAttributedString()
        attributed.append(NSAttributedString(string: label + " — ", attributes: [.font: boldFont, .foregroundColor: UIColor.label]))
        attributed.append(NSAttributedString(string: detail, attributes: [.font: normalFont, .foregroundColor: UIColor.darkGray]))

        let size = attributed.boundingRect(
            with: CGSize(width: textWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin, context: nil
        )
        attributed.draw(in: CGRect(x: textX, y: y, width: textWidth, height: size.height))
        return y + size.height + 2
    }

    private func drawNumbered(_ number: Int, _ text: String, at y: CGFloat) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 11)
        let numberFont = UIFont.systemFont(ofSize: 11, weight: .semibold)
        let indent: CGFloat = 20
        let textX = Self.margin + indent
        let textWidth = Self.contentWidth - indent

        let numberAttrs: [NSAttributedString.Key: Any] = [.font: numberFont, .foregroundColor: UIColor.systemBlue]
        ("\(number)." as NSString).draw(in: CGRect(x: Self.margin + 4, y: y, width: 16, height: 16), withAttributes: numberAttrs)

        let textAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.darkGray]
        let size = (text as NSString).boundingRect(
            with: CGSize(width: textWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin, attributes: textAttrs, context: nil
        )
        (text as NSString).draw(in: CGRect(x: textX, y: y, width: textWidth, height: size.height), withAttributes: textAttrs)
        return y + size.height + 2
    }
}
