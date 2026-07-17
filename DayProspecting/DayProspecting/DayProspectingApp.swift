//
//  DayProspectingApp.swift
//  DayProspecting
//
//  Created by Domingo Hilario on 6/22/26.
//

import SwiftUI
import SwiftData

@main
struct DayProspectingApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ContactAddress.self,
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
            LaunchScreenView()
        }
        .modelContainer(sharedModelContainer)
    }
}
