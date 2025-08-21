//
//  ProfileView.swift
//  MedTrack
//
//  Created by Aryan kumar on 8/18/25.
//

import SwiftUI

struct ProfileView: View {
    @AppStorage("profileName") private var name: String = ""
    @AppStorage("profileDOB") private var dob: Date = Date()
    @AppStorage("profileGender") private var gender: String = "Other"
    @AppStorage("profileEmail") private var email: String = ""
    @AppStorage("profileBloodType") private var bloodType: String = "O+"
    @AppStorage("profileHeight") private var height: String = ""
    @AppStorage("profileHeightUnit") private var heightUnit: String = "cm"
    @AppStorage("profileWeight") private var weight: String = ""
    @AppStorage("profileWeightUnit") private var weightUnit: String = "kg"
    @AppStorage("profileAllergies") private var allergies: String = ""
    @AppStorage("profileConditions") private var conditions: String = ""
    @AppStorage("profileImage") private var imageData: Data?

    @State private var image: UIImage?
    @State private var showImagePicker = false
    @State private var showImageSourceOptions = false
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
    
    let genderOptions = ["Male", "Female", "Other"]
    let bloodTypeOptions = ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"]
    let heightUnits = ["cm", "in"]
    let weightUnits = ["kg", "lb"]

    var body: some View {
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
                        HapticsManager.impact(.medium)
                        showImageSourceOptions = true
                    }
                }
                .frame(maxWidth: .infinity)
            }

//            Basic Info Section
            Section(header: Text("Basic Info")) {
                TextField("Full Name", text: $name)
                DatePicker("Date of Birth", selection: $dob, displayedComponents: .date)
                
                Picker("Gender", selection: $gender) {
                    ForEach(genderOptions, id: \.self) {
                        Text($0)
                    }
                }
                
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
            }
            
//            Medical Info Section
            Section(header: Text("Medical Info")) {
                Picker("Blood Type", selection: $bloodType) {
                    ForEach(bloodTypeOptions, id: \.self) {
                        Text($0)
                    }
                }
                
                HStack {
                    TextField("Height", text: $height)
                        .keyboardType(.decimalPad)
                    Picker("", selection: $heightUnit) {
                        ForEach(heightUnits, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 100)
                }
                
                HStack {
                    TextField("Weight", text: $weight)
                        .keyboardType(.decimalPad)
                    Picker("", selection: $weightUnit) {
                        ForEach(weightUnits, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 100)
                }
                
                TextField("Known Alleregies", text: $allergies, axis: .vertical)
                    .lineLimit(3...5)
                
                TextField("Medical Conditions", text: $conditions, axis: .vertical)
                    .lineLimit(3...5)
            }

//            Action Buttons
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
        dob = Date()
        gender = "Other"
        email = ""
        bloodType = "O+"
        height = ""
        heightUnit = "cm"
        weight = ""
        weightUnit = "kg"
        allergies = ""
        conditions = ""
        imageData = nil
        image = nil
        HapticsManager.notify(.warning)
    }
}

#Preview {
    ProfileView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
