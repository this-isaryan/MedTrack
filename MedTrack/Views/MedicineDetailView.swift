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
    
    @State private var showDeleteConfirmation = false
    
    @State private var originalName: String = ""
    @State private var originalPurpose: String = ""
    @State private var originalDosage: String = ""
    @State private var originalExpiryDate: Date = Date()
    @State private var originalImageData: Data? = nil
    
    @State private var name: String = ""
    @State private var purpose: String = ""
    @State private var expiryDate: Date = Date()
    @State private var dosage: String = ""
    @State private var image: UIImage? = nil
    @State private var showImagePicker = false
    @State private var showImageSourceOptions = false
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
    
    @State private var isEditing = false
    
    var body: some View {
        Form {
            Section(header: Text("Edit Medicine")) {
                TextField("Name", text: $name)
                    .disabled(!isEditing)
                    .opacity(isEditing ? 1 : 0.6)
                    .animation(.easeOut, value: isEditing)
                
                TextField("Purpose", text: $purpose)
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
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                } else {
                    Text("No image available")
                        .foregroundColor(.gray)
                }
                
                if isEditing {
                    Button("Change Image") {
                        showImageSourceOptions = true
                    }
                    .transition(.opacity)
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
                            expiryDate = originalExpiryDate
                            if let imageData = originalImageData {
                                image = UIImage(data: imageData)
                            }
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
            ImagePicker(image: $image, sourceType: imageSource)
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
            
            name = medicine.name ?? ""
            purpose = medicine.purpose ?? ""
            dosage = medicine.dosage ?? ""
            expiryDate = medicine.expiryDate ?? Date()
            if let imageData = medicine.image {
                image = UIImage(data: imageData)
            }
        }
    }
    
    private func updateMedicine() {
        medicine.name = name
        medicine.purpose = purpose
        medicine.dosage = dosage
        medicine.expiryDate = expiryDate
        
        if let image = image {
            medicine.image = image.jpegData(compressionQuality: 0.8)
        }
        
        do {
            try viewContext.save()
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
    
    private var hasChanges: Bool {
        name != originalName ||
        purpose != originalPurpose ||
        dosage != originalDosage ||
        expiryDate != originalExpiryDate ||
        image?.jpegData(compressionQuality: 0.8) != originalImageData
    }
    
    private func saveOriginalValues() {
        originalName = name
        originalPurpose = purpose
        originalDosage = dosage
        originalExpiryDate = expiryDate
        originalImageData = image?.jpegData(compressionQuality: 0.8)
    }
    
    private func deleteMedicine() {
        viewContext.delete(medicine)
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error deleting medicine: \(error.localizedDescription)")
        }
    }
}
