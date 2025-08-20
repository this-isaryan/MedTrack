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
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Medicine.expiryDate, ascending: true)],
        animation: .default)
    
    private var medicines: FetchedResults<Medicine>
    private var filteredMedicines: [Medicine] {
        var baseList = medicines.filter { med in searchText.isEmpty || (med.name?.localizedCaseInsensitiveContains(searchText) ?? false) || (med.purpose?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
        if selectedFilter == .expirationSoon {
            baseList = baseList.filter { isExpiringSoon($0.expiryDate)}
        } else if selectedFilter == .expired {
            baseList = baseList.filter { isExpired($0.expiryDate)}
        }
        return baseList
    }

    @State private var searchText: String = ""
    @State private var showAddForm = false
    
    enum FilterOption: String, CaseIterable, Identifiable {
    case all = "All"
    case expirationSoon = "Expiring Soon"
    case expired = "Expired"
        
        var id: String {self.rawValue}
    }
    
    @State private var selectedFilter: FilterOption = .all

    var body: some View {
        NavigationView {
            List {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(FilterOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                ForEach(filteredMedicines) { medicine in
                    NavigationLink(destination: MedicineDetailView(medicine: medicine)) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(medicine.name ?? "Unnamed")
                                .font(.headline)
                            Text("For: \(medicine.purpose ?? "Unknown")")
                                .font(.subheadline)
                            Text("Expires: \(formattedDate(medicine.expiryDate))")
                                .font(.caption)
                                .foregroundColor(.gray)

                            if isExpiringSoon(medicine.expiryDate) {
                                Text("⚠️ Expiring Soon")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                                    .padding(.top, 2)
                            } else if isExpired(medicine.expiryDate) {
                                Text("🚫 Expired")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                                    .padding(.top, 2)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteMedicines)
            }
            .navigationTitle("My Medicines")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search by name or purpose")

            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddForm = true
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                        NavigationLink(destination: ProfileView()) {
                            Image(systemName: "person.crop.circle")
                        }
                    }
            }
            .sheet(isPresented: $showAddForm) {
                AddMedicineView()
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func deleteMedicines(offsets: IndexSet) {
        for index in offsets {
            let med = medicines[index]
            viewContext.delete(med)
            HapticsManager.notify(.warning)
        }
        do {
            try viewContext.save()
        } catch {
            print("Failed to delete: \(error.localizedDescription)")
        }
    }
    
    private func isExpiringSoon(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        return daysLeft >= 0 && daysLeft <= 7
    }
    
    private func isExpired(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        return daysLeft < 0
    }
}

#Preview {
    HomeView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
