import SwiftData
import Foundation

enum SharedModelContainer {
    static let appGroupIdentifier = "group.mss.ProjectSimple"

    /// Creates the main app's ModelContainer with CloudKit sync enabled.
    static func create() throws -> ModelContainer {
        let schema = Schema([Project.self, ProjectTask.self])

        // Explicitly place the store in the app's private Application
        // Support directory (NOT the App Group).  When an App Group
        // entitlement is present, SwiftData may auto-select the shared
        // container, which can interfere with CloudKit mirroring.
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        let storeURL = appSupport.appendingPathComponent("ProjectSimple.store")

        let config = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .private("iCloud.mss.ProjectSimple")
        )

        do {
            let container = try ModelContainer(for: schema, configurations: config)
            print("✅ ModelContainer created with CloudKit sync enabled")
            print("✅ Store URL: \(config.url)")
            return container
        } catch {
            print("⚠️ CloudKit ModelContainer failed: \(error)")
            print("⚠️ Falling back to local-only storage — SYNC WILL NOT WORK")

            let localConfig = ModelConfiguration(
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            return try ModelContainer(for: schema, configurations: localConfig)
        }
    }

    /// Creates a local-only ModelContainer in the App Group container,
    /// suitable for the widget extension (which cannot use CloudKit).
    static func createForWidget() throws -> ModelContainer {
        let schema = Schema([Project.self, ProjectTask.self])

        if let dir = appGroupSupportDirectory() {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        let config = ModelConfiguration(
            "ProjectSimple",
            schema: schema,
            groupContainer: .identifier(appGroupIdentifier),
            cloudKitDatabase: .none
        )

        return try ModelContainer(for: schema, configurations: config)
    }

    // MARK: - Helpers

    private static func appGroupSupportDirectory() -> URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        )?.appending(path: "Library/Application Support")
    }


}
