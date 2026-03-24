//
//  Project_Simple_WatchApp.swift
//  Project​Simple​Watch Watch App
//
//  Created by Thomas Cowern on 3/21/26.
//

import SwiftUI
import SwiftData

@main
struct Project_Simple_Watch_Watch_AppApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try SharedModelContainer.create()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            WatchContentViewWrapper()
                .modelContainer(container)
        }
    }
}

struct WatchContentViewWrapper: View {
    @Environment(\.modelContext) private var modelContext
    @State private var store: WatchProjectStore?

    var body: some View {
        Group {
            if let store {
                WatchContentView()
                    .environment(store)
            } else {
                ProgressView()
            }
        }
        .task {
            if store == nil {
                store = WatchProjectStore(modelContext: modelContext)
            }
        }
    }
}
