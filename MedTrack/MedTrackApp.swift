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
                    MedicineCategoriesView()
                }
                .tabItem {
                    Label("Categories", systemImage: "rectangle.3.group")
                }

                NavigationView {
                    ProfileView()
                }
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
            }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .onAppear {
                NotificationManager.shared.requestPermission()
            }
        }
    }
}
