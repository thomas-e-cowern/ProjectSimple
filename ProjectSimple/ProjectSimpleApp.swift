//
//  ProjectSimpleApp.swift
//  ProjectSimple
//
//  Created by Thomas Cowern on 3/10/26.
//

import SwiftUI
import SwiftData
import TipKit
import AppIntents

// MARK: - Quick Action State

@Observable
class QuickActionState {
    static let shared = QuickActionState()
    var pendingAction: String?
    var pendingProjectID: UUID?
}

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        application.shortcutItems = [
            UIApplicationShortcutItem(
                type: "com.projectsimple.newProject",
                localizedTitle: "New Project",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "folder.badge.plus")
            )
        ]
        // Register for remote notifications so CloudKit can push sync updates
        application.registerForRemoteNotifications()
        return true
    }

    nonisolated func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        // CloudKit silent pushes arrive here; the underlying
        // NSPersistentCloudKitContainer handles the actual import.
        return .newData
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if let shortcutItem = options.shortcutItem {
            QuickActionState.shared.pendingAction = shortcutItem.type
        }
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        QuickActionState.shared.pendingAction = shortcutItem.type
        completionHandler(true)
    }
}

// MARK: - App

@main
struct ProjectSimpleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    let container: ModelContainer
    @State private var notificationManager = NotificationManager()
    private let quickActionState = QuickActionState.shared

    init() {
        UserDefaults.standard.register(defaults: ["hapticsEnabled": true])

        do {
            container = try SharedModelContainer.create()
        } catch {
            fatalError("Failed to create ModelContainer (even local fallback): \(error)")
        }

        do {
            try Tips.configure([
                .displayFrequency(.daily)
            ])
        } catch {
            print("Error initializing TipKit: \(error)")
        }

        AppShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            ContentViewWrapper()
                .environment(notificationManager)
                .environment(quickActionState)
                .modelContainer(container)
                .onOpenURL { url in
                    if url.host() == "overdue" {
                        QuickActionState.shared.pendingAction = "com.projectsimple.showOverdue"
                    }
                }
        }
    }
}

/// Wrapper that creates ProjectStore from the main-actor model context
struct ContentViewWrapper: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(NotificationManager.self) private var notificationManager
    @State private var store: ProjectStore?

    var body: some View {
        Group {
            if let store {
                ContentView()
                    .environment(store)
            } else {
                SplashView()
            }
        }
        .task {
            if store == nil {
                let newStore = ProjectStore(modelContext: modelContext)
                newStore.notificationManager = notificationManager
                store = newStore
                await notificationManager.requestAuthorization()
                await notificationManager.rescheduleAll(for: newStore.projects)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                store?.refreshAfterRemoteChange()
            }
        }
    }
}
// MARK: - Splash Screen

struct SplashView: View {
    @State private var showSyncMessage = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checklist")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("ProjectSimple")
                .font(.largeTitle.bold())

            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.regular)

                Text(showSyncMessage ? "Syncing your data..." : "Loading...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .animation(.easeInOut, value: showSyncMessage)
            }

            Spacer()
            Spacer()
        }
        .task {
            try? await Task.sleep(for: .seconds(2))
            showSyncMessage = true
        }
    }
}

