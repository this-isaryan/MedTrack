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
    @State private var showImagePicker = false
    @State private var showImageSourceOptions = false
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Medicine Info")) {
                    TextField("Medicine Name", text: $name)
                    TextField("Purpose", text: $purpose)
                    TextField("Dosage (e.g. 1 pill twice a day)", text: $dosage)
                    DatePicker("Expiry Date", selection: $expiryDate, displayedComponents: .date)
                }
                
                Section(header: Text("Medicine Photo")) {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Text("No Image Selected")
                            .foregroundColor(.gray)
                    }
                    Button("Select Image") {
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
                    ImagePicker(image: $image, sourceType: imageSource)
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
        } catch {
            print("Save failed: \(error.localizedDescription)")
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
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}
