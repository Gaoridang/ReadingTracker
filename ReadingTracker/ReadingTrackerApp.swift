//
//  ReadingTrackerApp.swift
//  ReadingTracker
//
//  Created by 이재준 on 6/27/25.
//

import SwiftUI

@main
struct ReadingTrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
