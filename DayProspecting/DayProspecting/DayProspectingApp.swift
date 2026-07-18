//
//  DayProspectingApp.swift
//  DayProspecting
//
//  Created by Domingo Hilario on 6/22/26.
//

import SwiftData
import SwiftUI

@main
struct DayProspectingApp: App {
    // Read the globally selected language string identifier (e.g., "en", "es", "fr")
    @AppStorage("app_language") private var appLanguage: String = "en"
    @AppStorage("is_dark_mode") private var isDarkMode: Bool = false  // 💡 Tracks color theme preference

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ContactAddress.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        // Replace with the exact container ID you created in step 1
            /*   let config = ModelConfiguration(
                   "dayprospecting",
                   cloudKitDatabase: .private("iCloud.com.yourname.dayprospecting")
               )*/

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            LaunchScreenView()
                // Forces all LocalizedStringKey structures to follow this locale definition
                .environment(\.locale, Locale(identifier: appLanguage))
                // 💡 Forces view hierarchies to match selection (true = dark, false = light)
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
        .modelContainer(sharedModelContainer)
    }
}
