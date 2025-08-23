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
    @AppStorage("profileHeightCM") private var heightCM: Double = 0.0
    @AppStorage("profileHeightUnit") private var heightUnit: String = "cm"
    @AppStorage("profileWeightKG") private var weightKG: Double = 0.0
    @AppStorage("profileWeightUnit") private var weightUnit: String = "kg"
    @AppStorage("profileAllergies") private var allergies: String = ""
    @AppStorage("profileConditions") private var conditions: String = ""
    @AppStorage("profileImage") private var imageData: Data?

    @State private var image: UIImage?
    @State private var showImagePicker = false
    @State private var showImageSourceOptions = false
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
    
    @State private var heightFeet: String = ""
    @State private var heightInches: String = ""
    @State private var weightInput: String = ""
    
    let genderOptions = ["Male", "Female", "Other"]
    let bloodTypeOptions = ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"]
    let heightUnits = ["cm", "ft/in"]
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
                
                Section(header: Text("Height")) {
                    if heightUnit == "cm" {
                        HStack {
                            TextField("Height", value: $heightCM, format: .number)
                                .keyboardType(.decimalPad)
                            Text("cm")
                        }
                    } else {
                        HStack {
                            TextField("Feet", text: $heightFeet)
                                .keyboardType(.numberPad)
                                .frame(width: 60)

                            Text("ft")

                            TextField("Inches", text: $heightInches)
                                .keyboardType(.numberPad)
                                .frame(width: 60)

                            Text("in")
                        }
                    }

                    Picker("Unit", selection: $heightUnit) {
                        ForEach(heightUnits, id: \.self) { unit in
                            Text(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: heightUnit) {
                        convertHeight(to: heightUnit)
                    }
                }
                
                Section(header: Text("Weight")) {
                    HStack {
                        TextField("Weight", text: $weightInput)
                            .keyboardType(.decimalPad)

                        Picker("", selection: $weightUnit) {
                            ForEach(weightUnits, id: \.self) {
                                Text($0)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 100)
                        .onChange(of: weightUnit) {
                            convertWeight(to: weightUnit)
                        }
                    }
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

            if heightUnit == "ft/in" {
                convertHeight(to: "ft/in")
            }

            // Initialize weight input
            if weightUnit == "kg" {
                weightInput = String(format: "%.1f", weightKG)
            } else {
                let lb = weightKG * 2.20462
                weightInput = String(format: "%.1f", lb)
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

        if heightUnit == "cm" {
            // heightCM already bound
        } else {
            let ft = Double(heightFeet) ?? 0
            let inch = Double(heightInches) ?? 0
            heightCM = (ft * 30.48) + (inch * 2.54)
        }

        // Save weight
        if weightUnit == "kg" {
            weightKG = Double(weightInput) ?? 0
        } else {
            let lb = Double(weightInput) ?? 0
            weightKG = lb / 2.20462
        }
    }
    
    private func convertHeight(to unit: String) {
        if unit == "cm" {
            // Convert from ft/in to cm
            let ft = Double(heightFeet) ?? 0
            let inch = Double(heightInches) ?? 0
            heightCM = (ft * 30.48) + (inch * 2.54)
        } else {
            // Convert from cm to ft/in
            let totalInches = heightCM / 2.54
            let ft = Int(totalInches / 12)
            let inch = totalInches.truncatingRemainder(dividingBy: 12)
            heightFeet = "\(ft)"
            heightInches = String(format: "%.0f", inch)
        }
    }
    
    private func convertWeight(to unit: String) {
        let value = Double(weightInput) ?? 0
        if unit == "kg" {
            // Convert lb to kg
            weightKG = value / 2.20462
            weightInput = String(format: "%.1f", weightKG)
        } else {
            // Convert kg to lb
            let lb = weightKG * 2.20462
            weightInput = String(format: "%.1f", lb)
        }
    }
    
    private func clearProfile() {
        name = ""
        dob = Date()
        gender = "Other"
        email = ""
        bloodType = "O+"
        heightCM = 0.0
        heightUnit = "cm"
        heightFeet = ""
        heightInches = ""
        weightKG = 0.0
        weightUnit = "kg"
        weightInput = ""
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
