//
//  ProfileView.swift
//  MedTrack
//
//  Created by Aryan kumar on 8/18/25.
//

import SwiftUI

struct ProfileView: View {
    @AppStorage("profileName") private var name: String = ""
    @AppStorage("profileAge") private var age: String = ""
    @AppStorage("profileImage") private var imageData: Data?
    
    @State private var image: UIImage?
    @State private var showImagePicker = false
    @State private var showImageSourceOptions = false
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Picture")) {
                    VStack {
                        if let image = image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                        }
                        
                        Button("Change Picture") {
                            showImageSourceOptions = true
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                
                Section(header: Text("Personal Info")) {
                    TextField("Name", text: $name)
                    TextField("Age", text: $age)
                        .keyboardType(.numberPad)
                }
                
                Section {
                    Button("Save Changes") {
                        saveProfile()
                        HapticsManager.notify(.success)
                    }
                }
                
                Section {
                    Button("Clear Profile", role: .destructive) {
                        clearProfile()
                    }
                }
            }
            .navigationTitle("My Profile")
        }
        .onAppear {
            if let imageData = imageData {
                image = UIImage(data: imageData)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $image, sourceType: imageSource)
        }
        .confirmationDialog("Choose Image Source", isPresented: $showImageSourceOptions) {
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
    
    private func saveProfile() {
        if let image = image {
            imageData = image.jpegData(compressionQuality: 0.8)
        }
    }
    
    private func clearProfile() {
        name = ""
        age = ""
        imageData = nil
        image = nil
        HapticsManager.notify(.warning)
    }
}
