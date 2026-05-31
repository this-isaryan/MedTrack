//
//  MedicineDetailView.swift
//  MedTrack
//
//  Created by Aryan kumar on 8/4/25.
//

import SwiftUI
import UIKit

struct MedicineDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var medicine: Medicine
    let notificationAction: ExpiryReminderRoute.Action?
    
    @State private var showDeleteConfirmation = false
    
    @State private var originalName: String = ""
    @State private var originalPurpose: String = ""
    @State private var originalDosage: String = ""
    @State private var originalExpiryDate: Date = Date()
    @State private var originalImageData: Data? = nil
    @State private var originalMedicineForm: String = ""
    @State private var originalStrengthValue: String = ""
    @State private var originalStrengthUnit: String = ""
    @State private var originalQuantity: String = ""
    @State private var originalQuantityUnit: String = ""
    
    @State private var name: String = ""
    @State private var purpose: String = ""
    @State private var expiryDate: Date = Date()
    @State private var dosage: String = ""
    @State private var medicineForm: String = ""
    @State private var strengthValue: String = ""
    @State private var strengthUnit: String = ""
    @State private var quantity: String = ""
    @State private var quantityUnit: String = ""
    @State private var image: UIImage? = nil
    @State private var pendingImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var showImageConfirmation = false
    @State private var showImageSourceOptions = false
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var showSnoozeOptions = false
    @State private var showCustomSnoozeSheet = false
    @State private var customSnoozeDate = Date()
    @State private var showRestockSheet = false
    @State private var restockExpiryDate = Date()
    @State private var confirmationMessage: String?
    @State private var didHandleNotificationAction = false
    
    @State private var isEditing = false

    init(medicine: Medicine, notificationAction: ExpiryReminderRoute.Action? = nil) {
        self.medicine = medicine
        self.notificationAction = notificationAction
    }
    
    var body: some View {
        Form {
            Section(header: Text("Edit Medicine")) {
                TextField("Name", text: $name)
                    .disabled(!isEditing)
                    .opacity(isEditing ? 1 : 0.6)
                    .animation(.easeOut, value: isEditing)
                
                TextField("Used For", text: $purpose)
                    .disabled(!isEditing)
                    .opacity(isEditing ? 1 : 0.6)
                    .animation(.easeOut, value: isEditing)

                TextField("Form", text: $medicineForm)
                    .disabled(!isEditing)
                    .opacity(isEditing ? 1 : 0.6)
                    .animation(.easeOut, value: isEditing)

                HStack {
                    TextField("Strength", text: $strengthValue)
                        .keyboardType(.decimalPad)
                    Spacer(minLength: 16)
                    TextField("Unit", text: $strengthUnit)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
                .disabled(!isEditing)
                .opacity(isEditing ? 1 : 0.6)
                .animation(.easeOut, value: isEditing)

                HStack {
                    TextField("Quantity", text: $quantity)
                        .keyboardType(.numberPad)
                    Spacer(minLength: 16)
                    TextField("Unit", text: $quantityUnit)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 110)
                }
                .disabled(!isEditing)
                .opacity(isEditing ? 1 : 0.6)
                .animation(.easeOut, value: isEditing)
                
                TextField("Dosage", text: $dosage)
                    .disabled(!isEditing)
                    .opacity(isEditing ? 1 : 0.6)
                    .animation(.easeOut, value: isEditing)
                
                DatePicker("Expiry Date", selection: $expiryDate, displayedComponents: .date)
                    .disabled(!isEditing)
                    .opacity(isEditing ? 1 : 0.6)
                    .animation(.easeOut, value: isEditing)
                
                HStack {
                    Text("Added on:")
                    Spacer()
                    Text(formattedDate(medicine.addedDate))
                        .foregroundColor(.gray)
                }
            }
            
            Section(header: Text("Medicine Image")) {
                MedicineImageCard(
                    image: image,
                    isEditing: isEditing,
                    actionTitle: image == nil ? "Add Image" : "Change Image"
                ) {
                        showImageSourceOptions = true
                }
            }

            if shouldShowExpiryActions {
                Section(header: Text("Expiry Reminder")) {
                    if let snoozedUntil = reminderDateValue(forKey: "expiryReminderSnoozedUntil"), snoozedUntil > Date() {
                        HStack {
                            Label("Snoozed until", systemImage: "bell.slash")
                            Spacer()
                            Text(formattedDate(snoozedUntil))
                                .foregroundColor(.secondary)
                        }
                    }

                    Button {
                        customSnoozeDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                        showSnoozeOptions = true
                    } label: {
                        Label("Snooze Reminder", systemImage: "clock")
                    }

                    Button {
                        restockExpiryDate = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
                        showRestockSheet = true
                    } label: {
                        Label("Mark as Restocked", systemImage: "arrow.clockwise.circle")
                    }
                }
            }
            
            if isEditing {
                Section {
                    Button("Save Changes") {
                        HapticsManager.notify(.success)
                        withAnimation {
                            updateMedicine()
                            isEditing = false
                            saveOriginalValues()
                        }
                    }
                    .disabled(!hasChanges || name.isEmpty || purpose.isEmpty)
                }
                .transition(.move(edge: .bottom) .combined(with: .opacity))
            }
            if isEditing {
                Section {
                    Button(role: .destructive) {
                        HapticsManager.notify(.error)
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Medicine", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Medicine Details")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if isEditing {
                    Button("Cancel") {
                        HapticsManager.impact(.medium)
                        withAnimation {
                            // Reset fields and exit editing mode
                            name = originalName
                            purpose = originalPurpose
                            dosage = originalDosage
                            medicineForm = originalMedicineForm
                            strengthValue = originalStrengthValue
                            strengthUnit = originalStrengthUnit
                            quantity = originalQuantity
                            quantityUnit = originalQuantityUnit
                            expiryDate = originalExpiryDate
                            if let imageData = originalImageData {
                                image = UIImage(data: imageData)
                            } else {
                                image = nil
                            }
                            pendingImage = nil
                            isEditing = false
                        }
                    }
                } else {
                    Button("Edit") {
                        HapticsManager.impact(.light)
                        withAnimation {
                            isEditing = true
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $pendingImage, sourceType: imageSource)
        }
        .onChange(of: showImagePicker) {
            guard !showImagePicker, pendingImage != nil else { return }
            showImageConfirmation = true
        }
        .sheet(isPresented: $showImageConfirmation) {
            if let pendingImage {
                MedicineImageConfirmationView(image: pendingImage) {
                    self.pendingImage = nil
                    showImageConfirmation = false
                } onAdd: {
                    image = pendingImage
                    self.pendingImage = nil
                    showImageConfirmation = false
                    HapticsManager.notify(.success)
                }
            }
        }
        .confirmationDialog("Choose Image Source", isPresented: $showImageSourceOptions, titleVisibility: .visible) {
            Button("Camera") {
                imageSource = .camera
                showImagePicker = true
            }
            Button("Photo Library") {
                imageSource = .photoLibrary
                showImagePicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Snooze Reminder", isPresented: $showSnoozeOptions, titleVisibility: .visible) {
            Button("Remind Tomorrow") {
                snoozeReminder(until: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
            }
            Button("Remind in 3 Days") {
                snoozeReminder(until: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date())
            }
            Button("Remind on Expiry Date") {
                snoozeReminder(until: medicine.expiryDate ?? Date())
            }
            Button("Custom Date") {
                showCustomSnoozeSheet = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showCustomSnoozeSheet) {
            CustomSnoozeDateView(snoozeDate: $customSnoozeDate) {
                showCustomSnoozeSheet = false
            } onSave: {
                snoozeReminder(until: customSnoozeDate)
                showCustomSnoozeSheet = false
            }
        }
        .sheet(isPresented: $showRestockSheet) {
            RestockMedicineView(expiryDate: $restockExpiryDate) {
                showRestockSheet = false
            } onSave: {
                markAsRestocked(newExpiryDate: restockExpiryDate)
                showRestockSheet = false
            }
        }
        .alert("Reminder Updated", isPresented: Binding(
            get: { confirmationMessage != nil },
            set: { if !$0 { confirmationMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(confirmationMessage ?? "")
        }
        .alert("Are you sure?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteMedicine()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .onAppear {
            originalName = medicine.name ?? ""
            originalPurpose = medicine.purpose ?? ""
            originalDosage = medicine.dosage ?? ""
            originalExpiryDate = medicine.expiryDate ?? Date()
            originalImageData = medicine.image
            originalMedicineForm = medicineStringValue(forKey: "medicineForm")
            originalStrengthValue = medicineStringValue(forKey: "strengthValue")
            originalStrengthUnit = medicineStringValue(forKey: "strengthUnit")
            originalQuantity = medicineQuantityString()
            originalQuantityUnit = medicineStringValue(forKey: "quantityUnit")
            
            name = medicine.name ?? ""
            purpose = medicine.purpose ?? ""
            dosage = medicine.dosage ?? ""
            medicineForm = originalMedicineForm
            strengthValue = originalStrengthValue
            strengthUnit = originalStrengthUnit
            quantity = originalQuantity
            quantityUnit = originalQuantityUnit
            expiryDate = medicine.expiryDate ?? Date()
            if let imageData = medicine.image {
                image = UIImage(data: imageData)
            }
            handleNotificationActionIfNeeded()
        }
    }
    
    private func updateMedicine() {
        let didChangeExpiryDate = medicine.expiryDate != expiryDate

        medicine.name = name
        medicine.purpose = purpose
        medicine.dosage = dosage
        medicine.expiryDate = expiryDate
        medicine.setValue(medicineForm, forKey: "medicineForm")
        medicine.setValue(strengthValue, forKey: "strengthValue")
        medicine.setValue(strengthUnit, forKey: "strengthUnit")
        medicine.setValue(Int16(quantity.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0, forKey: "quantity")
        medicine.setValue(quantityUnit, forKey: "quantityUnit")
        
        if let image = image {
            medicine.image = image.jpegData(compressionQuality: 0.8)
        }
        if didChangeExpiryDate {
            setReminderDateValue(nil, forKey: "expiryReminderSnoozedUntil")
            setReminderDateValue(nil, forKey: "expiryReminderSentAt")
        }
        
        do {
            try viewContext.save()
            NotificationManager.shared.cancelNotification(for: medicine)
            NotificationManager.shared.scheduleExpiryNotification(for: medicine)
        } catch {
            print("Error saving edits: \(error.localizedDescription)")
        }
    }
    
    private func formattedDate(_ date: Date?) -> String {
            guard let date = date else { return "N/A" }
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
    }

    private var shouldShowExpiryActions: Bool {
        guard let expiryDate = medicine.expiryDate else { return false }
        return isExpiringSoon(expiryDate) || isExpired(expiryDate)
    }

    private func isExpiringSoon(_ date: Date) -> Bool {
        let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        return daysLeft >= 0 && daysLeft <= 7
    }

    private func isExpired(_ date: Date) -> Bool {
        date < Date()
    }

    private func snoozeReminder(until date: Date) {
        setReminderDateValue(date, forKey: "expiryReminderSnoozedUntil")
        setReminderDateValue(nil, forKey: "expiryReminderSentAt")

        do {
            try viewContext.save()
            NotificationManager.shared.scheduleExpiryNotification(for: medicine)
            confirmationMessage = "Expiry reminder snoozed until \(formattedDate(date))."
            HapticsManager.notify(.success)
        } catch {
            print("Error snoozing reminder: \(error.localizedDescription)")
        }
    }

    private func markAsRestocked(newExpiryDate: Date) {
        medicine.expiryDate = newExpiryDate
        setReminderDateValue(nil, forKey: "expiryReminderSnoozedUntil")
        setReminderDateValue(nil, forKey: "expiryReminderSentAt")
        setReminderDateValue(Date(), forKey: "lastRestockedAt")

        expiryDate = newExpiryDate

        do {
            try viewContext.save()
            NotificationManager.shared.scheduleExpiryNotification(for: medicine)
            saveOriginalValues()
            confirmationMessage = "Medicine marked as restocked. A new expiry reminder has been scheduled."
            HapticsManager.notify(.success)
        } catch {
            print("Error marking as restocked: \(error.localizedDescription)")
        }
    }

    private func reminderDateValue(forKey key: String) -> Date? {
        medicine.value(forKey: key) as? Date
    }

    private func setReminderDateValue(_ date: Date?, forKey key: String) {
        medicine.setValue(date, forKey: key)
    }

    private func medicineStringValue(forKey key: String) -> String {
        medicine.value(forKey: key) as? String ?? ""
    }

    private func medicineQuantityString() -> String {
        let value = medicine.value(forKey: "quantity") as? Int16 ?? 0
        return value == 0 ? "" : "\(value)"
    }

    private func handleNotificationActionIfNeeded() {
        guard !didHandleNotificationAction else { return }
        didHandleNotificationAction = true

        switch notificationAction {
        case .snooze:
            print("Opening Snooze Reminder flow from notification for medicine \(medicine.id?.uuidString ?? "unknown")")
            customSnoozeDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            DispatchQueue.main.async {
                showSnoozeOptions = true
            }
        case .restock:
            print("Opening Mark as Restocked flow from notification for medicine \(medicine.id?.uuidString ?? "unknown")")
            restockExpiryDate = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
            DispatchQueue.main.async {
                showRestockSheet = true
            }
        case .openDetails:
            print("Opening medicine details from notification for medicine \(medicine.id?.uuidString ?? "unknown")")
        case .none:
            break
        }
    }
    
    private var hasChanges: Bool {
        name != originalName ||
        purpose != originalPurpose ||
        dosage != originalDosage ||
        medicineForm != originalMedicineForm ||
        strengthValue != originalStrengthValue ||
        strengthUnit != originalStrengthUnit ||
        quantity != originalQuantity ||
        quantityUnit != originalQuantityUnit ||
        expiryDate != originalExpiryDate ||
        image?.jpegData(compressionQuality: 0.8) != originalImageData
    }
    
    private func saveOriginalValues() {
        originalName = name
        originalPurpose = purpose
        originalDosage = dosage
        originalExpiryDate = expiryDate
        originalImageData = image?.jpegData(compressionQuality: 0.8)
        originalMedicineForm = medicineForm
        originalStrengthValue = strengthValue
        originalStrengthUnit = strengthUnit
        originalQuantity = quantity
        originalQuantityUnit = quantityUnit
    }
    
    private func deleteMedicine() {
        NotificationManager.shared.cancelNotification(for: medicine)
        viewContext.delete(medicine)
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error deleting medicine: \(error.localizedDescription)")
        }
    }
}

private struct CustomSnoozeDateView: View {
    @Binding var snoozeDate: Date
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section {
                    DatePicker("Remind Me On", selection: $snoozeDate, in: Date()..., displayedComponents: .date)
                }
            }
            .navigationTitle("Custom Snooze")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                }
            }
        }
    }
}

private struct RestockMedicineView: View {
    @Binding var expiryDate: Date
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Restock Details")) {
                    DatePicker("New Expiry Date", selection: $expiryDate, in: Date()..., displayedComponents: .date)
                }
            }
            .navigationTitle("Mark as Restocked")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                }
            }
        }
    }
}
