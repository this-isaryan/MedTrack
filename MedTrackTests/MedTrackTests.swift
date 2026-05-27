//
//  MedTrackTests.swift
//  MedTrackTests
//
//  Created by Aryan kumar on 8/2/25.
//

import Testing
import CoreData
@testable import MedTrack

struct MedTrackTests {

    @MainActor
    @Test func medicineViewModelSavePersistsExpectedFields() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let expiryDate = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 15)))

        let viewModel = MedicineViewModel()
        viewModel.name = "Atorvastatin"
        viewModel.purpose = "Cholesterol"
        viewModel.dosage = "1 tablet daily"
        viewModel.expiryDate = expiryDate

        viewModel.save(context: context)

        let request = Medicine.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", "Atorvastatin")

        let medicines = try context.fetch(request)
        let medicine = try #require(medicines.first)

        #expect(medicine.id != nil)
        #expect(medicine.name == "Atorvastatin")
        #expect(medicine.purpose == "Cholesterol")
        #expect(medicine.dosage == "1 tablet daily")
        #expect(medicine.expiryDate == expiryDate)
        #expect(medicine.addedDate != nil)
        #expect(medicine.isArchived == false)
    }

    @MainActor
    @Test func medicinesCanBeFetchedByExpiryDateAscending() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let earlierDate = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 1)))
        let laterDate = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 7, day: 1)))

        let laterMedicine = Medicine(context: context)
        laterMedicine.id = UUID()
        laterMedicine.name = "Later"
        laterMedicine.expiryDate = laterDate

        let earlierMedicine = Medicine(context: context)
        earlierMedicine.id = UUID()
        earlierMedicine.name = "Earlier"
        earlierMedicine.expiryDate = earlierDate

        try context.save()

        let request = Medicine.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Medicine.expiryDate, ascending: true)]

        let medicines = try context.fetch(request)

        #expect(medicines.map(\.name) == ["Earlier", "Later"])
    }
}
