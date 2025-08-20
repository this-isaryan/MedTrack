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
            TabView {
                NavigationView {
                    HomeView()
                }
                .tabItem {
                    Label("Home", systemImage: "pills")
                }

                NavigationView {
                    ProfileView()
                }
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
            }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
