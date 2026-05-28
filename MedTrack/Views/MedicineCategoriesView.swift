//
//  MedicineCategoriesView.swift
//  MedTrack
//

import SwiftUI
import CoreData

struct MedicineCategoriesView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Medicine.name, ascending: true)],
        animation: .default)
    private var medicines: FetchedResults<Medicine>

    private var groupedSections: [PurposeMedicineSection] {
        let grouped = Dictionary(grouping: Array(medicines)) { medicine in
            normalizedPurpose(medicine.purpose)
        }

        return grouped.map { key, medicines in
            PurposeMedicineSection(
                title: key,
                medicines: medicines.sorted { lhs, rhs in
                    medicineName(lhs).localizedCaseInsensitiveCompare(medicineName(rhs)) == .orderedAscending
                }
            )
        }
        .sorted { lhs, rhs in
            if lhs.title == Self.uncategorizedTitle { return false }
            if rhs.title == Self.uncategorizedTitle { return true }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
    }

    private static let uncategorizedTitle = "Uncategorized"

    var body: some View {
        ScrollView {
            if medicines.isEmpty {
                emptyState
            } else {
                LazyVStack(alignment: .leading, spacing: 18) {
                    ForEach(groupedSections) { section in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(section.title)
                                .font(.headline)
                                .padding(.horizontal, 4)

                            VStack(spacing: 10) {
                                ForEach(section.medicines) { medicine in
                                    NavigationLink(destination: MedicineDetailView(medicine: medicine)) {
                                        MedicineCategoryRow(medicine: medicine)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Categories")
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "rectangle.3.group")
                .font(.system(size: 42, weight: .regular))
                .foregroundColor(.secondary)

            Text("No medicines yet")
                .font(.headline)

            Text("Medicines will appear here grouped by what they are used for once you add them.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 120)
    }

    private func normalizedPurpose(_ purpose: String?) -> String {
        let trimmed = purpose?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else { return Self.uncategorizedTitle }

        return trimmed
            .lowercased()
            .split(separator: " ")
            .map { word in
                word.prefix(1).uppercased() + word.dropFirst()
            }
            .joined(separator: " ")
    }

    private func medicineName(_ medicine: Medicine) -> String {
        let trimmed = medicine.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Unnamed Medicine" : trimmed
    }
}

private struct PurposeMedicineSection: Identifiable {
    let title: String
    let medicines: [Medicine]

    var id: String { title }
}

private struct MedicineCategoryRow: View {
    let medicine: Medicine

    var body: some View {
        HStack(spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 5) {
                Text(displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if let dosage = displayDosage {
                    Text(dosage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                if let expiryDate = medicine.expiryDate {
                    Text("Expires: \(formattedDate(expiryDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
    }

    private var thumbnail: some View {
        Group {
            if let imageData = medicine.image, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "pills.fill")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.secondary.opacity(0.10))
            }
        }
        .frame(width: 58, height: 58)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var displayName: String {
        let trimmed = medicine.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Unnamed Medicine" : trimmed
    }

    private var displayDosage: String? {
        let trimmed = medicine.dosage?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationView {
        MedicineCategoriesView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
