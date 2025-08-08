//
//  AddMedicineView.swift
//  MedTrack
//
//  Created by Aryan kumar on 8/4/25.
//

import SwiftUI

struct AddMedicineView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var purpose: String = ""
    @State private var expiryDate: Date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Medicine Info")) {
                    TextField("Medicine Name", text: $name)
                    TextField("Purpose", text: $purpose)
                    DatePicker("Expiry Date", selection: $expiryDate, displayedComponents: .date)
                }
                
                Section {
                    Button("Save") {
                        saveMedicine()
                        dismiss()
                    }
                    .disabled(name.isEmpty || purpose.isEmpty)
                }
            }
            .navigationTitle("Add Medicine")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func saveMedicine() {
        let newMed = Medicine(context: viewContext)
        newMed.id = UUID()
        newMed.name = name
        newMed.purpose = purpose
        newMed.expiryDate = expiryDate
        newMed.addedDate = Date()
        newMed.isArchived = false
        
        do {
            try viewContext.save()
            NotificationManager.shared.scheduleExpiryNotification(for: newMed)
        } catch {
            print("Save failed: \(error.localizedDescription)")
        }
    }
}
