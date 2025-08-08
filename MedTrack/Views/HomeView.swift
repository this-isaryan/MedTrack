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
        if searchText.isEmpty {
            return Array(medicines)
        } else {
            return medicines.filter {
                ($0.name ?? "").localizedCaseInsensitiveContains(searchText) ||
                ($0.purpose ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    @State private var searchText: String = ""
    @State private var showAddForm = false

    var body: some View {
        NavigationView {
            List {
                ForEach(filteredMedicines) { medicine in
                    NavigationLink(destination: EditMedicineView(medicine: medicine)) {
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
}

#Preview {
    HomeView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
