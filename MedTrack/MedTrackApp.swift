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
    
    init () {
        NotificationManager.shared.requestPermisson()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
