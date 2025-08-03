//
//  MedTrackApp.swift
//  MedTrack
//
//  Created by Aryan kumar on 8/2/25.
//

import SwiftUI

@main
struct MedTrackApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
