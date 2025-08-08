//
//  MedicineViewModel.swift
//  MedTrack
//
//  Created by Aryan kumar on 8/2/25.
//

import Foundation
import CoreData

class MedicineViewModel: ObservableObject {
    @Published var name = ""
    @Published var purpose = ""
    @Published var expiryDate = Date()
    @Published var dosage = ""
    
    func save(context: NSManagedObjectContext) {
        let newMed = Medicine(context: context)
        newMed.id = UUID()
        newMed.name = name
        newMed.purpose = purpose
        newMed.expiryDate = expiryDate
        newMed.dosage = dosage
        newMed.addedDate = Date()
        newMed.isArchived = false
        
        do {
            try context.save()
        } catch {
            print("Failed to save: \(error.localizedDescription)")
        }
    }
}
