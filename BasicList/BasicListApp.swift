//
//  BasicListApp.swift
//  BasicList
//
//  Created by Stephen Choate on 2/23/25.
//

import SwiftUI
import SwiftData

@main
struct BasicListApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TaskItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
