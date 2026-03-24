# ProjectSimple

A native iOS project and task management app built entirely with SwiftUI and SwiftData. Organize work into projects, track tasks with priorities, due dates, and subtasks, and stay on top of deadlines with widgets, notifications, and Siri integration.

## Features

### Project & Task Management
- Create projects with custom colors, categories, and date ranges
- Add tasks with titles, descriptions, due dates, priorities (High/Medium/Low), and status tracking (Not Started, In Progress, Completed)
- Break tasks into subtasks (steps) with individual completion tracking
- Recurring tasks with Daily, Weekly, Biweekly, Monthly, and Yearly schedules
- Archive and restore projects and tasks
- Full undo/redo support (up to 30 levels)

### Multiple Views
- **Projects** — Sidebar navigation with project list and progress indicators
- **Calendar** — Visual calendar with task indicators and overdue highlighting
- **Search** — Full-text search with filtering by priority and category
- **Statistics** — Charts for weekly completion trends, task distribution by priority, category breakdowns, and most productive day analysis

### iCloud Sync
- Automatic CloudKit synchronization across all your devices
- Remote change detection with fingerprint-based diffing

### Widgets
- **Lock screen widgets** — Circular and rectangular variants showing overdue task counts
- **Home screen widgets** — Small (2x2) and medium (2x4) sizes with task details and priority indicators

### Siri Shortcuts & App Intents
- "Create a new project"
- "Add a task"
- "Show overdue tasks"
- "Task summary" (reports active, overdue, and due-today counts)
- "Mark task done"

### Notifications
- Morning reminders (9 AM) for tasks and projects due that day
- 5-day advance warnings for upcoming deadlines
- Dynamic badge count for overdue and due-today tasks

### Export & Backup
- **PDF export** — Generate formatted project reports with progress summaries and task lists
- **JSON export/import** — Full data backup and restore

### Apple Watch
- Companion watchOS app for viewing projects and tasks on your wrist

### Accessibility
- Full VoiceOver support with detailed labels and hints
- Contextual in-app tips via TipKit

## Screenshots

_Add screenshots here._

## Requirements

- iOS 26.0+
- watchOS 26.0+ (for the watch app)
- Xcode 26+

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI, Charts |
| Persistence | SwiftData + CloudKit |
| Widgets | WidgetKit |
| Shortcuts | AppIntents |
| Notifications | UserNotifications |
| PDF Generation | UIGraphicsPDFRenderer |
| Tips | TipKit |
| Haptics | UIImpactFeedbackGenerator |

## Architecture

The app follows an Observable/MVVM pattern:

- **Models** — `Project`, `ProjectTask`, and `TaskStep` defined as SwiftData models
- **ProjectStore** — A `@MainActor @Observable` singleton that manages all CRUD operations, undo/redo, notifications, and CloudKit sync
- **Views** — SwiftUI views with `@Environment` injection for accessing the store
- **SharedModelContainer** — Centralized `ModelContainer` configuration shared between the main app and widget extension

## Project Structure

```
ProjectSimple/
├── Models/              # SwiftData models (Project, ProjectTask, TaskStep)
├── ProjectStore/        # Central data store and business logic
├── Views/
│   ├── ProjectListView/ # Project sidebar and rows
│   ├── ProjectDetailView/ # Task list within a project
│   ├── AddTaskView/     # Task creation with steps
│   ├── CalendarView/    # Calendar-based task view
│   ├── SearchView/      # Search and filter
│   ├── StatisticsView/  # Charts and metrics
│   ├── ArchiveView/     # Archived projects and tasks
│   └── HelperViews/     # Reusable UI components
├── Haptics/             # Haptic feedback manager
├── Intents/             # Siri shortcuts and App Intents
├── NotificationManager/ # Local notification scheduling
├── PDFGenerator/        # PDF report generation
├── SharedModelContainer/ # SwiftData container setup
└── Tips/                # TipKit definitions
OverdueTasksWidget/      # Home screen and lock screen widgets
ProjectSimpleWatch/      # watchOS companion app
ProjectSimpleTests/      # Unit tests
```

## Getting Started

1. Clone the repository
2. Open `ProjectSimple.xcodeproj` in Xcode 26+
3. Select a target device or simulator
4. Build and run

> **Note:** iCloud sync requires an Apple Developer account and a provisioned device. Widgets and notifications work best on physical hardware.

## License

_Add your license here._
