//
//  HomeView.swift
//  MedTrack
//
//  Created by Aryan kumar on 8/2/25.
//

import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var notificationRouter: NotificationNavigationRouter

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Medicine.expiryDate, ascending: true)],
        animation: .default)
    private var medicines: FetchedResults<Medicine>

    @State private var searchText: String = ""
    @State private var showAddForm = false
    @State private var selectedFilter: FilterOption = .all
    @State private var selectedNotificationRoute: ExpiryReminderRoute?

    enum FilterOption: String, CaseIterable, Identifiable {
        case all = "All"
        case expirationSoon = "Expiring Soon"
        case expired = "Expired"

        var id: String { self.rawValue }
    }

    private var filteredMedicines: [Medicine] {
        var baseList = medicines.filter { med in
            searchText.isEmpty ||
            (med.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (med.purpose?.localizedCaseInsensitiveContains(searchText) ?? false)
        }

        switch selectedFilter {
        case .expirationSoon:
            baseList = baseList.filter { isExpiringSoon($0.expiryDate) }
        case .expired:
            baseList = baseList.filter { isExpired($0.expiryDate) }
        default:
            break
        }

        return baseList
    }

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Group {
            if medicines.isEmpty {
                emptyStateView
            } else {
                medicineList
            }
        }
        .navigationTitle("My Medicines")
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            if let route = notificationRouter.route {
                selectedNotificationRoute = route
            }
        }
        .onReceive(notificationRouter.$route) { route in
            guard let route else { return }
            selectedNotificationRoute = route
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search by name or used for")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddForm = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddForm) {
            AddMedicineView()
                .environment(\.managedObjectContext, viewContext)
        }
    }

    private var medicineList: some View {
        List {
            // Filter Picker
            Picker("Filter", selection: $selectedFilter) {
                ForEach(FilterOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Medicines List
            if filteredMedicines.isEmpty {
                noResultsView
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(filteredMedicines) { medicine in
                    NavigationLink(destination: MedicineDetailView(medicine: medicine)) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(medicine.name ?? "Unnamed")
                                .font(.headline)
                            Text("Used For: \(medicine.purpose ?? "Unknown")")
                                .font(.subheadline)
                            Text("Expires: \(formattedDate(medicine.expiryDate))")
                                .font(.caption)
                                .foregroundColor(.gray)

                            if isExpiringSoon(medicine.expiryDate) {
                                Text("⚠️ Expiring Soon")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            } else if isExpired(medicine.expiryDate) {
                                Text("🚫 Expired")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteMedicines)
            }

            notificationNavigationLink
        }
    }

    private var emptyStateView: some View {
        ScrollView {
            VStack(spacing: 14) {
                Image(systemName: "pills")
                    .font(.system(size: 42, weight: .regular))
                    .foregroundColor(.secondary)

                Text("No medicines yet")
                    .font(.headline)

                Text("Add your first medicine to start tracking expiry dates and reminders.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Button {
                    showAddForm = true
                } label: {
                    Text("Add a medicine to get started")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 120)

            notificationNavigationLink
                .hidden()
        }
    }

    private var noResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 34, weight: .semibold))
                .foregroundColor(.secondary)

            Text(isSearching ? "No matching medicines found" : "No medicines in this filter")
                .font(.headline)
                .foregroundColor(.primary)

            Text(isSearching ? "Try a different medicine name or used for value." : "Try switching back to All medicines.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 56)
        .padding(.bottom, 80)
    }

    private var notificationNavigationLink: some View {
        NavigationLink(
            destination: notificationDestination,
            isActive: Binding(
                get: { selectedNotificationRoute != nil },
                set: { isActive in
                    if !isActive {
                        selectedNotificationRoute = nil
                        notificationRouter.route = nil
                    }
                }
            )
        ) {
            EmptyView()
        }
        .hidden()
    }

    @ViewBuilder
    private var notificationDestination: some View {
        if let route = selectedNotificationRoute,
           let medicine = medicines.first(where: { $0.id == route.medicineID }) {
            MedicineDetailView(medicine: medicine, notificationAction: route.action)
        } else {
            Text("Medicine not found")
                .navigationTitle("Medicine Details")
                .onAppear {
                    if let route = selectedNotificationRoute {
                        print("Notification route medicine not found: \(route.medicineID)")
                    }
                }
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func isExpiringSoon(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        return daysLeft >= 0 && daysLeft <= 7
    }

    private func isExpired(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        return date < Date()
    }

    private func deleteMedicines(offsets: IndexSet) {
        let medicinesToDelete = offsets.map { filteredMedicines[$0] }

        for med in medicinesToDelete {
            NotificationManager.shared.cancelNotification(for: med)
            viewContext.delete(med)
            HapticsManager.notify(.warning)
        }
        do {
            try viewContext.save()
        } catch {
            print("Failed to delete: \(error.localizedDescription)")
        }
    }
}

#Preview {
    HomeView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
