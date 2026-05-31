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
    
    @State private var step: AddMedicineStep = .name
    @State private var name: String = ""
    @State private var medicineForm: String = ""
    @State private var strengthValue: String = ""
    @State private var strengthUnit: String = "mg"
    @State private var quantity: String = "10"
    @State private var quantityUnit: String = "tablets"
    @State private var isEditingQuantityManually = false
    @State private var manualQuantityText = ""
    @State private var purpose: String = ""
    @State private var expiryDate: Date = Date()
    @State private var dosage: String = ""
    @State private var image: UIImage? = nil
    @State private var pendingImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var showImageConfirmation = false
    @State private var showImageSourceOptions = false
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
    @FocusState private var isManualQuantityFocused: Bool

    private let medicineForms = ["Capsule", "Tablet", "Liquid", "Topical", "Cream", "Device", "Drops", "Injection", "Other"]
    private let strengthUnits = ["mg", "mcg", "g", "mL", "%", "IU", "Other"]
    private let quantityUnits = ["tablets", "capsules", "pills", "bottles", "tubes", "packs", "doses", "units", "other"]
    private let usedForExamples = ["Fever", "Headache", "Allergy", "Pain Relief", "Cold & Flu"]
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        header

                        stepContent
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 24)
                    .padding(.bottom, 150)
                }
                .background(Color(.systemBackground))

                bottomControls
                    .padding(.horizontal, 28)
                    .padding(.bottom, 18)
                    .background(
                        LinearGradient(
                            colors: [Color(.systemBackground).opacity(0), Color(.systemBackground), Color(.systemBackground)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    )
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if step != .name {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            goBack()
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
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
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            if step != .name {
                VStack(spacing: 2) {
                    Text(name)
                        .font(.headline)
                    if !medicineForm.isEmpty {
                        Text(medicineForm)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Image(systemName: headerIconName)
                .font(.system(size: 58, weight: .light))
                .foregroundStyle(.blue, .cyan, .purple)
                .symbolRenderingMode(.palette)
                .frame(maxWidth: .infinity)
                .padding(.top, step == .name ? 44 : 12)
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .name:
            inputStep(title: "Medication Name") {
                roundedTextField("Add Medication Name", text: $name)
            }
        case .form:
            selectionStep(title: "Choose the Medication Type", sections: [("Common Forms", Array(medicineForms.prefix(4))), ("More Forms", Array(medicineForms.dropFirst(4)))], selection: Binding(
                get: { medicineForm },
                set: { selectMedicineForm($0) }
            ))
        case .strength:
            inputStep(title: "Add the Medication Strength") {
                Text("Strength")
                    .font(.title3.bold())
                roundedTextField("200", text: $strengthValue)
                    .keyboardType(.decimalPad)
                Text("Choose Unit")
                    .font(.title3.bold())
                    .padding(.top, 12)
                optionList(strengthUnits, selection: $strengthUnit)
            }
        case .quantity:
            inputStep(title: "How Much Do You Have?") {
                Text("Quantity")
                    .font(.title3.bold())
                quantitySelector
                Text("Unit")
                    .font(.title3.bold())
                    .padding(.top, 12)
                optionList(quantityUnits, selection: $quantityUnit)
            }
        case .usedFor:
            inputStep(title: "What Is It Used For?") {
                roundedTextField("Fever, Headache, Allergy", text: $purpose)
                Text("Examples")
                    .font(.title3.bold())
                    .padding(.top, 12)
                optionList(usedForExamples, selection: $purpose)
            }
        case .dosage:
            inputStep(title: "Dosage / Instructions") {
                roundedTextField("Example: 1 pill twice a day", text: $dosage)
            }
        case .expiry:
            inputStep(title: "When Does It Expire?") {
                DatePicker("Expiry Date", selection: $expiryDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        case .image:
            inputStep(title: "Add a Medicine Image") {
                MedicineImageCard(
                    image: image,
                    isEditing: true,
                    actionTitle: image == nil ? "Add Image" : "Change Image"
                ) {
                    HapticsManager.impact(.medium)
                    showImageSourceOptions = true
                }
            }
        case .review:
            reviewStep
        }
    }

    private func inputStep<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            Text(title)
                .font(.system(size: 28, weight: .bold))
            content()
        }
    }

    private func selectionStep(title: String, sections: [(String, [String])], selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            Text(title)
                .font(.system(size: 28, weight: .bold))
            ForEach(sections, id: \.0) { section in
                VStack(alignment: .leading, spacing: 12) {
                    Text(section.0)
                        .font(.title3.bold())
                    optionList(section.1, selection: selection)
                }
            }
        }
    }

    private func roundedTextField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(.body)
            .padding(.horizontal, 20)
            .frame(height: 56)
            .background(Color(.systemGray6))
            .clipShape(Capsule())
    }

    private func optionList(_ options: [String], selection: Binding<String>) -> some View {
        VStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                Button {
                    selection.wrappedValue = option
                } label: {
                    HStack {
                        Text(option)
                            .font(.body)
                            .foregroundColor(.primary)
                        Spacer()
                        if selection.wrappedValue == option {
                            Image(systemName: "checkmark")
                                .font(.title3.bold())
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 18)
                    .contentShape(Rectangle())
                    .padding(.horizontal, 20)
                }
                if option != options.last {
                    Divider()
                        .padding(.leading, 20)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var quantitySelector: some View {
        VStack(spacing: 14) {
            HStack(spacing: 18) {
                Button {
                    adjustQuantity(by: -10)
                } label: {
                    Image(systemName: "minus")
                        .font(.title2.bold())
                        .frame(width: 54, height: 54)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(currentQuantity <= 0)
                .opacity(currentQuantity <= 0 ? 0.35 : 1)

                Spacer(minLength: 8)

                VStack(spacing: 6) {
                    if isEditingQuantityManually {
                        TextField("0", text: $manualQuantityText)
                            .font(.system(size: 46, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .focused($isManualQuantityFocused)
                            .onChange(of: manualQuantityText) {
                                manualQuantityText = manualQuantityText.filter { $0.isNumber }
                            }
                            .onSubmit {
                                commitManualQuantity()
                            }
                    } else {
                        Text("\(currentQuantity)")
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .contentTransition(.numericText())
                            .onTapGesture(count: 2) {
                                beginManualQuantityEntry()
                            }
                    }

                    Text(quantityUnit)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                .frame(minWidth: 120)

                Spacer(minLength: 8)

                Button {
                    adjustQuantity(by: 10)
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .frame(width: 54, height: 54)
                        .background(Color.blue.opacity(0.14))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            Text("Double-tap the number to type a custom quantity.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .toolbar {
            if isManualQuantityFocused {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        commitManualQuantity()
                    }
                }
            }
        }
    }

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Review & Save")
                .font(.system(size: 28, weight: .bold))

            VStack(spacing: 0) {
                reviewRow("Name", name)
                reviewRow("Form", medicineForm)
                reviewRow("Strength", strengthSummary.isEmpty ? "Skipped" : strengthSummary)
                reviewRow("Quantity", "\(quantity) \(quantityUnit)")
                reviewRow("Used For", purpose)
                reviewRow("Dosage", dosage.isEmpty ? "Skipped" : dosage)
                reviewRow("Expiry", formattedDate(expiryDate))
                reviewRow("Image", image == nil ? "Skipped" : "Added")
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    private func reviewRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .padding()
    }

    private var bottomControls: some View {
        VStack(spacing: 12) {
            Button {
                if step == .review {
                    saveMedicine()
                    dismiss()
                } else {
                    goNext()
                }
            } label: {
                Text(step == .review ? "Save" : "Next")
                    .font(.body.bold())
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
            }
            .buttonStyle(.borderedProminent)
            .clipShape(Capsule())
            .disabled(!canContinue)

            if step.allowsSkip {
                Button("Skip") {
                    skipCurrentStep()
                }
                .font(.body.bold())
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color(.secondarySystemBackground))
                .clipShape(Capsule())
            }
        }
    }

    private var canContinue: Bool {
        switch step {
        case .name:
            return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .form:
            return !medicineForm.isEmpty
        case .quantity:
            guard let value = Int16(quantity.trimmingCharacters(in: .whitespacesAndNewlines)) else { return false }
            return value >= 0
        default:
            return true
        }
    }

    private var strengthSummary: String {
        let trimmedStrength = strengthValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedStrength.isEmpty ? "" : "\(trimmedStrength) \(strengthUnit)"
    }

    private var currentQuantity: Int {
        max(Int(quantity.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0, 0)
    }

    private var headerIconName: String {
        switch step {
        case .form: return "pills"
        case .strength: return "capsule.portrait"
        case .quantity: return "number.circle"
        case .expiry: return "calendar"
        case .image: return "photo"
        case .review: return "checkmark.seal"
        default: return "pills.fill"
        }
    }

    private func goNext() {
        if step == .quantity, isEditingQuantityManually {
            commitManualQuantity()
        }

        withAnimation(.easeInOut) {
            step = step.next
        }
    }

    private func goBack() {
        withAnimation(.easeInOut) {
            step = step.previous
        }
    }

    private func skipCurrentStep() {
        if step == .strength {
            strengthValue = ""
        } else if step == .dosage {
            dosage = ""
        } else if step == .image {
            image = nil
            pendingImage = nil
        }
        goNext()
    }

    private func selectMedicineForm(_ form: String) {
        medicineForm = form
        quantityUnit = defaultQuantityUnit(for: form)
    }

    private func defaultQuantityUnit(for form: String) -> String {
        switch form {
        case "Capsule":
            return "capsules"
        case "Tablet":
            return "tablets"
        case "Liquid", "Drops":
            return "bottles"
        case "Topical", "Cream":
            return "tubes"
        case "Injection":
            return "doses"
        case "Device", "Other":
            return "units"
        default:
            return "units"
        }
    }

    private func adjustQuantity(by amount: Int) {
        let nextQuantity = max(currentQuantity + amount, 0)
        quantity = "\(nextQuantity)"
        manualQuantityText = quantity
        HapticsManager.impact(.light)
    }

    private func beginManualQuantityEntry() {
        manualQuantityText = quantity
        isEditingQuantityManually = true

        DispatchQueue.main.async {
            isManualQuantityFocused = true
        }
    }

    private func commitManualQuantity() {
        let sanitized = manualQuantityText.filter { $0.isNumber }
        quantity = "\(max(Int(sanitized) ?? 0, 0))"
        manualQuantityText = quantity
        isEditingQuantityManually = false
        isManualQuantityFocused = false
    }
    
    private func saveMedicine() {
        let newMed = Medicine(context: viewContext)
        newMed.id = UUID()
        newMed.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        newMed.purpose = purpose.trimmingCharacters(in: .whitespacesAndNewlines)
        newMed.dosage = dosage.trimmingCharacters(in: .whitespacesAndNewlines)
        newMed.expiryDate = expiryDate
        newMed.addedDate = Date()
        newMed.isArchived = false
        newMed.setValue(medicineForm, forKey: "medicineForm")
        newMed.setValue(strengthValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "strengthValue")
        newMed.setValue(strengthUnit, forKey: "strengthUnit")
        newMed.setValue(Int16(quantity.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0, forKey: "quantity")
        newMed.setValue(quantityUnit, forKey: "quantityUnit")
        
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

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

private enum AddMedicineStep: Int, CaseIterable {
    case name
    case form
    case strength
    case quantity
    case usedFor
    case dosage
    case expiry
    case image
    case review

    var next: AddMedicineStep {
        AddMedicineStep(rawValue: min(rawValue + 1, Self.review.rawValue)) ?? .review
    }

    var previous: AddMedicineStep {
        AddMedicineStep(rawValue: max(rawValue - 1, Self.name.rawValue)) ?? .name
    }

    var allowsSkip: Bool {
        self == .strength || self == .dosage || self == .image
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
