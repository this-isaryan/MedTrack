//
//  EditMedicineView.swift
//  MedTrack
//
//  Created by Aryan kumar on 8/4/25.
//

import SwiftUI

struct EditMedicineView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var medicine: Medicine
    
    @State private var name: String = ""
    @State private var purpose: String = ""
    @State private var expiryDate: Date = Date()
    
    var body: some View {
        Form {
            Section(header: Text("Edit Medicine")) {
                TextField("Name", text: $name)
                TextField("Purpose", text: $purpose)
                DatePicker("Expiry Date", selection: $expiryDate, displayedComponents: .date)
            }
            
            Section {
                Button("Save Changes") {
                    updateMedicine()
                    dismiss()
                }
                .disabled(name.isEmpty || purpose.isEmpty)
            }
        }
        .navigationTitle("Edit")
        .onAppear {
            name = medicine.name ?? ""
            purpose = medicine.purpose ?? ""
            expiryDate = medicine.expiryDate ?? Date()
        }
    }
    private func updateMedicine() {
        medicine.name = name
        medicine.purpose = purpose
        medicine.expiryDate = expiryDate
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving edits: \(error.localizedDescription)")
        }
    }
}
