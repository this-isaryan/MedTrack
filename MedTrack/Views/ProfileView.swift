//
//  ProfileView.swift
//  MedTrack
//
//  Created by Aryan kumar on 8/18/25.
//

import SwiftUI

struct ProfileView: View {
    @Namespace private var profileImageNamespace
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
    @State private var pendingProfileImage: UIImage?
    @State private var showImagePicker = false
    @State private var showProfileImageAdjustment = false
    @State private var showImageSourceOptions = false
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var isEditing = false

    @State private var heightFeet: String = ""
    @State private var heightInches: String = ""

    let genderOptions = ["Male", "Female", "Other"]
    let bloodTypeOptions = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]
    let heightUnits = ["cm", "ft/in"]
    let weightUnits = ["kg", "lb"]

    var body: some View {
        Form {
            // Profile Picture
            Section {
                Group {
                    if isEditing {
                        VStack(spacing: 12) {
                            if let image = image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 150, height: 150)
                                    .clipShape(Circle())
                                    .matchedGeometryEffect(id: "profilePic", in: profileImageNamespace)
                            } else {
                                Image(systemName: "person.circle")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.gray)
                                    .matchedGeometryEffect(id: "profilePic", in: profileImageNamespace)
                            }

                            Button("Change Picture") {
                                showImageSourceOptions = true
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .transition(.opacity)
                    } else {
                        HStack(spacing: 16) {
                            if let image = image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                                    .matchedGeometryEffect(id: "profilePic", in: profileImageNamespace)
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.gray)
                                    .matchedGeometryEffect(id: "profilePic", in: profileImageNamespace)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(name.isEmpty ? "Your Name" : name.uppercased())
                                    .font(.title3)
                                    .fontWeight(.semibold)

                                if !email.isEmpty {
                                    Text(email)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .transition(.opacity)
                    }
                }
            }

            // Basic Info
            Section(header: Text("Basic Info")) {
                if isEditing {
                    TextField("Name", text: $name)
                    DatePicker("Date of Birth", selection: $dob, displayedComponents: .date)
                    Picker("Gender", selection: $gender) {
                        ForEach(genderOptions, id: \.self) { Text($0) }
                    }
                    TextField("Email Address", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                } else {
                    ProfileRow(label: "Date of Birth", value: formattedDate(dob))
                    ProfileRow(label: "Gender", value: gender)
                }
            }


            // Medical Info
            Section(header: Text("Medical Info")) {
                if isEditing {
                    Picker("Blood Type", selection: $bloodType) {
                        ForEach(bloodTypeOptions, id: \.self) { Text($0) }
                    }

                    if heightUnit == "cm" {
                        HStack {
                            TextField("Height", text: $height)
                                .keyboardType(.decimalPad)
                            Text("cm")
                        }
                    } else {
                        HStack {
                            Spacer()
                            TextField("Feet", text: $heightFeet)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                            Text("ft")
                            TextField("Inches", text: $heightInches)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                            Text("in")
                        }
                    }

                    Picker("Unit", selection: $heightUnit) {
                        ForEach(heightUnits, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: heightUnit) {
                        convertHeight(to: heightUnit)
                    }

                    HStack {
                        TextField("Weight", text: $weight)
                            .keyboardType(.decimalPad)
                        Picker("", selection: $weightUnit) {
                            ForEach(weightUnits, id: \.self) { Text($0) }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 100)
                        .onChange(of: weightUnit) {
                            convertWeight(to: weightUnit)
                        }
                    }

                    TextField("Known Allergies", text: $allergies, axis: .vertical)
                        .lineLimit(3...5)

                    TextField("Medical Conditions", text: $conditions, axis: .vertical)
                        .lineLimit(3...5)
                } else {
                    let heightDisplay = heightUnit == "cm" ? "\(height) cm" : "\(heightFeet) ft \(heightInches) in"


                    ProfileRow(label: "Blood Type", value: bloodType)
                    ProfileRow(label: "Height", value: heightDisplay)
                    ProfileRow(label: "Weight", value: "\(weight) \(weightUnit)")
                    ProfileRow(label: "Allergies", value: allergies)
                    ProfileRow(label: "Conditions", value: conditions)
                }
            }

            // Save Button
            if isEditing {
                Section {
                    Button("Save Changes") {
                        saveProfile()
                        isEditing = false
                        HapticsManager.notify(.success)
                    }
                }
            }
        }
        .navigationTitle("My Profile")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation(.easeInOut) {
                        isEditing.toggle()
                    }
                } label: {
                    Image(systemName: isEditing ? "xmark" : "pencil")
                }
            }
        }
        .onAppear {
            if let imageData = imageData {
                image = UIImage(data: imageData)
            }

            if heightUnit == "ft/in" && (heightFeet.isEmpty || heightInches.isEmpty) {
                convertHeight(to: "ft/in")
            }
            
            if weightUnit == "lb" {
                convertWeight(to: "lb")
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $pendingProfileImage, sourceType: imageSource)
        }
        .onChange(of: showImagePicker) {
            guard !showImagePicker, pendingProfileImage != nil else { return }
            showProfileImageAdjustment = true
        }
        .sheet(isPresented: $showProfileImageAdjustment) {
            if let pendingProfileImage {
                ProfileImageAdjustmentView(image: pendingProfileImage) { adjustedImage in
                    image = adjustedImage
                    imageData = adjustedImage.jpegData(compressionQuality: 0.8)
                    self.pendingProfileImage = nil
                    showProfileImageAdjustment = false
                    HapticsManager.notify(.success)
                } onCancel: {
                    self.pendingProfileImage = nil
                    showProfileImageAdjustment = false
                }
            }
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

    // MARK: - Helper Functions

    private func saveProfile() {
        if let image = image {
            imageData = image.jpegData(compressionQuality: 0.8)
        }
        if heightUnit == "cm" {
            // already in height
        } else {
            let ft = Double(heightFeet) ?? 0
            let inch = Double(heightInches) ?? 0
            let cm = (ft * 30.48) + (inch * 2.54)
            height = String(format: "%.1f", cm)
        }
    }

    private func convertHeight(to unit: String) {
        guard let cm = Double(height) else {
            heightFeet = ""
            heightInches = ""
            return
        }

        if unit == "ft/in" {
            let totalInches = cm / 2.54
            let ft = Int(totalInches / 12)
            let inch = totalInches.truncatingRemainder(dividingBy: 12)
            heightFeet = "\(ft)"
            heightInches = String(format: "%.0f", inch)
        }
    }

    private func convertWeight(to unit: String) {
        let value = Double(weight) ?? 0
        if unit == "kg" {
            let kg = value / 2.20462
            weight = String(format: "%.1f", kg)
        } else {
            let lb = value * 2.20462
            weight = String(format: "%.1f", lb)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct ProfileImageAdjustmentView: View {
    let image: UIImage
    let onSet: (UIImage) -> Void
    let onCancel: () -> Void

    @State private var scale = 1.0
    @State private var lastScale = 1.0
    @State private var offset = CGSize.zero
    @State private var lastOffset = CGSize.zero

    private let minScale = 1.0
    private let maxScale = 4.0
    private let outputSize = CGSize(width: 512, height: 512)

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                let frameSide = min(geometry.size.width - 48, 320)

                VStack(spacing: 24) {
                    Spacer(minLength: 16)

                    cropPreview(frameSide: frameSide)

                    Text("Move and scale")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 24)
                .navigationTitle("Adjust Picture")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", action: onCancel)
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Choose") {
                            onSet(adjustedImage(frameSide: frameSide))
                        }
                    }
                }
            }
        }
    }

    private func cropPreview(frameSide: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color.secondary.opacity(0.12))

            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: frameSide, height: frameSide)
                .scaleEffect(scale)
                .offset(offset)
                .clipShape(Circle())
                .gesture(combinedGesture(frameSide: frameSide))

            Circle()
                .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
        }
        .frame(width: frameSide, height: frameSide)
        .clipped()
    }

    private func combinedGesture(frameSide: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let proposedOffset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
                offset = clampedOffset(proposedOffset, scale: scale, frameSide: frameSide)
            }
            .onEnded { _ in
                offset = clampedOffset(offset, scale: scale, frameSide: frameSide)
                lastOffset = offset
            }
            .simultaneously(with:
                MagnificationGesture()
                    .onChanged { value in
                        let proposedScale = min(max(lastScale * value, minScale), maxScale)
                        scale = proposedScale
                        offset = clampedOffset(offset, scale: proposedScale, frameSide: frameSide)
                    }
                    .onEnded { _ in
                        scale = min(max(scale, minScale), maxScale)
                        offset = clampedOffset(offset, scale: scale, frameSide: frameSide)
                        lastScale = scale
                        lastOffset = offset
                    }
            )
    }

    private func adjustedImage(frameSide: CGFloat) -> UIImage {
        let originalSize = image.size
        let baseScale = max(frameSide / originalSize.width, frameSide / originalSize.height)
        let imageScale = baseScale * scale
        let cropSide = frameSide / imageScale
        let cropOrigin = CGPoint(
            x: ((originalSize.width - cropSide) / 2) - (offset.width / imageScale),
            y: ((originalSize.height - cropSide) / 2) - (offset.height / imageScale)
        )
        let cropRect = clampedCropRect(
            CGRect(origin: cropOrigin, size: CGSize(width: cropSide, height: cropSide)),
            imageSize: originalSize
        )
        let scale = max(outputSize.width / cropSide, outputSize.height / cropSide)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        return UIGraphicsImageRenderer(size: outputSize, format: format).image { _ in
            image.draw(
                in: CGRect(
                    x: -cropRect.minX * scale,
                    y: -cropRect.minY * scale,
                    width: originalSize.width * scale,
                    height: originalSize.height * scale
                )
            )
        }
    }

    private func clampedOffset(_ proposedOffset: CGSize, scale: CGFloat, frameSide: CGFloat) -> CGSize {
        let originalSize = image.size
        let baseScale = max(frameSide / originalSize.width, frameSide / originalSize.height)
        let displayedWidth = originalSize.width * baseScale * scale
        let displayedHeight = originalSize.height * baseScale * scale
        let maxX = max((displayedWidth - frameSide) / 2, 0)
        let maxY = max((displayedHeight - frameSide) / 2, 0)

        return CGSize(
            width: min(max(proposedOffset.width, -maxX), maxX),
            height: min(max(proposedOffset.height, -maxY), maxY)
        )
    }

    private func clampedCropRect(_ rect: CGRect, imageSize: CGSize) -> CGRect {
        let originX = min(max(rect.origin.x, 0), imageSize.width - rect.width)
        let originY = min(max(rect.origin.y, 0), imageSize.height - rect.height)

        return CGRect(
            x: originX,
            y: originY,
            width: rect.width,
            height: rect.height
        )
    }
}

// MARK: - View for Displaying Profile Info Rows

struct ProfileRow: View {
    var label: String
    var value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ProfileView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
