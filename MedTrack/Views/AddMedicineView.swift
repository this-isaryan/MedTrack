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
    @State private var dosage: String = ""
    @State private var image: UIImage? = nil
    @State private var pendingImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var showImageConfirmation = false
    @State private var showImageSourceOptions = false
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Medicine Info")) {
                    TextField("Medicine Name", text: $name)
                    TextField("Used For", text: $purpose)
                    TextField("Dosage (e.g. 1 pill twice a day)", text: $dosage)
                    DatePicker("Expiry Date", selection: $expiryDate, displayedComponents: .date)
                }
                
                Section(header: Text("Medicine Photo")) {
                    MedicineImageCard(
                        image: image,
                        isEditing: true,
                        actionTitle: image == nil ? "Add Image" : "Change Image"
                    ) {
                        HapticsManager.impact(.medium)
                        showImageSourceOptions = true
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

        }
    }
    
    private func saveMedicine() {
        let newMed = Medicine(context: viewContext)
        newMed.id = UUID()
        newMed.name = name
        newMed.purpose = purpose
        newMed.dosage = dosage
        newMed.expiryDate = expiryDate
        newMed.addedDate = Date()
        newMed.isArchived = false
        
        if let image = image {
            newMed.image = image.jpegData(compressionQuality: 0.8)
        }
        
        do {
            try viewContext.save()
            NotificationManager.shared.scheduleExpiryNotification(for: newMed)
            HapticsManager.notify(.success)
        } catch {
            print("Save failed: \(error.localizedDescription)")
        }
    }
}

struct MedicineImageCard: View {
    let image: UIImage?
    let isEditing: Bool
    let actionTitle: String
    let onImageAction: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "photo")
                            .font(.system(size: 36, weight: .regular))
                            .foregroundColor(.secondary)

                        Text("No medicine image added")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .background(Color.secondary.opacity(0.08))
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(16 / 10, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)

            if isEditing {
                Button(action: onImageAction) {
                    Label(actionTitle, systemImage: image == nil ? "photo.badge.plus" : "photo")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 6)
    }
}

struct MedicineImageConfirmationView: View {
    let image: UIImage
    let onCancel: () -> Void
    let onAdd: () -> Void

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 20) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: max(geometry.size.height * 0.65, 260))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)

                    Spacer()
                }
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Preview Image")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", action: onCancel)
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add", action: onAdd)
                    }
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    var sourceType: UIImagePickerController.SourceType
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent:ImagePicker) {
            self.parent = parent
        }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }
    }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}
