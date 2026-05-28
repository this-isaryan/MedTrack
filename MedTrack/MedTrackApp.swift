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
    @StateObject private var notificationRouter = NotificationNavigationRouter.shared
    @State private var selectedTab: AppTab = .home

    enum AppTab {
        case home
        case categories
        case profile
    }

    init() {
        NotificationManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                NavigationView {
                    HomeView()
                }
                .tabItem {
                    Label("Home", systemImage: "pills")
                }
                .tag(AppTab.home)

                NavigationView {
                    MedicineCategoriesView()
                }
                .tabItem {
                    Label("Categories", systemImage: "rectangle.3.group")
                }
                .tag(AppTab.categories)

                NavigationView {
                    ProfileView()
                }
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(AppTab.profile)
            }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .environmentObject(notificationRouter)
            .onReceive(notificationRouter.$route) { route in
                guard route != nil else { return }
                selectedTab = .home
            }
            .onAppear {
                NotificationManager.shared.requestPermission()
            }
        }
    }
}
