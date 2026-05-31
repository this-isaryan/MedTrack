//
//  HomeView.swift
//  MedTrack
//
//  Created by Aryan kumar on 8/2/25.
//

import SwiftUI
import CoreData
import UIKit

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var notificationRouter: NotificationNavigationRouter

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Medicine.expiryDate, ascending: true)],
        animation: .default)
    private var medicines: FetchedResults<Medicine>

    @State private var searchText: String = ""
    @State private var showAddForm = false
    @State private var selectedFilter: FilterOption = .all
    @State private var selectedNotificationRoute: ExpiryReminderRoute?

    enum FilterOption: String, CaseIterable, Identifiable {
        case all = "All"
        case expirationSoon = "Expiring Soon"
        case expired = "Expired"

        var id: String { self.rawValue }
    }

    private var filteredMedicines: [Medicine] {
        var baseList = medicines.filter { med in
            searchText.isEmpty ||
            (med.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (med.purpose?.localizedCaseInsensitiveContains(searchText) ?? false)
        }

        switch selectedFilter {
        case .expirationSoon:
            baseList = baseList.filter { isExpiringSoon($0.expiryDate) }
        case .expired:
            baseList = baseList.filter { isExpired($0.expiryDate) }
        default:
            break
        }

        return baseList
    }

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Group {
            if medicines.isEmpty {
                emptyStateView
            } else {
                medicineList
            }
        }
        .navigationTitle("My Medicines")
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            if let route = notificationRouter.route {
                selectedNotificationRoute = route
            }
        }
        .onReceive(notificationRouter.$route) { route in
            guard let route else { return }
            selectedNotificationRoute = route
        }
        .onChange(of: selectedNotificationRoute) { _, route in
            if route == nil {
                notificationRouter.route = nil
            }
        }
        .navigationDestination(item: $selectedNotificationRoute) { route in
            notificationDestination(for: route)
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search by name or used for")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddForm = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddForm) {
            AddMedicineView()
                .environment(\.managedObjectContext, viewContext)
        }
    }

    private var medicineList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(FilterOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.bottom, 4)

                if filteredMedicines.isEmpty {
                    noResultsView
                } else {
                    ForEach(filteredMedicines) { medicine in
                        NavigationLink(destination: MedicineDetailView(medicine: medicine)) {
                            HomeMedicineCard(
                                medicine: medicine,
                                formattedExpiryDate: formattedDate(medicine.expiryDate),
                                expiryStatus: expiryStatus(for: medicine.expiryDate)
                            )
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteMedicine(medicine)
                            } label: {
                                Label("Delete Medicine", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 104)
        }
    }

    private var emptyStateView: some View {
        ScrollView {
            VStack(spacing: 14) {
                Image(systemName: "pills")
                    .font(.system(size: 42, weight: .regular))
                    .foregroundColor(.secondary)

                Text("No medicines yet")
                    .font(.headline)

                Text("Add your first medicine to start tracking expiry dates and reminders.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Button {
                    showAddForm = true
                } label: {
                    Text("Add a medicine to get started")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 120)
        }
    }

    private var noResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 34, weight: .semibold))
                .foregroundColor(.secondary)

            Text(isSearching ? "No matching medicines found" : "No medicines in this filter")
                .font(.headline)
                .foregroundColor(.primary)

            Text(isSearching ? "Try a different medicine name or used for value." : "Try switching back to All medicines.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 56)
        .padding(.bottom, 80)
    }

    @ViewBuilder
    private func notificationDestination(for route: ExpiryReminderRoute) -> some View {
        if let medicine = medicines.first(where: { $0.id == route.medicineID }) {
            MedicineDetailView(medicine: medicine, notificationAction: route.action)
        } else {
            Text("Medicine not found")
                .navigationTitle("Medicine Details")
                .onAppear {
                    print("Notification route medicine not found: \(route.medicineID)")
                }
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func isExpiringSoon(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        return daysLeft >= 0 && daysLeft <= 7
    }

    private func isExpired(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        return date < Date()
    }

    private func expiryStatus(for date: Date?) -> HomeMedicineCard.ExpiryStatus {
        if isExpired(date) {
            return .expired
        }

        if isExpiringSoon(date) {
            return .expiringSoon
        }

        return .safe
    }

    private func deleteMedicine(_ medicine: Medicine) {
        NotificationManager.shared.cancelNotification(for: medicine)
        viewContext.delete(medicine)
        HapticsManager.notify(.warning)

        do {
            try viewContext.save()
        } catch {
            print("Failed to delete: \(error.localizedDescription)")
        }
    }

    private func deleteMedicines(offsets: IndexSet) {
        let medicinesToDelete = offsets.map { filteredMedicines[$0] }

        for med in medicinesToDelete {
            deleteMedicine(med)
        }
    }
}

private struct HomeMedicineCard: View {
    let medicine: Medicine
    let formattedExpiryDate: String
    let expiryStatus: ExpiryStatus

    enum ExpiryStatus {
        case expired
        case expiringSoon
        case safe

        var title: String {
            switch self {
            case .expired:
                return "Expired"
            case .expiringSoon:
                return "Expiring Soon"
            case .safe:
                return "Safe"
            }
        }

        var foregroundColor: Color {
            switch self {
            case .expired:
                return .red
            case .expiringSoon:
                return .orange
            case .safe:
                return .green
            }
        }

        var backgroundColor: Color {
            foregroundColor.opacity(0.12)
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            thumbnail

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(displayName)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    statusBadge
                }

                Text("Used For: \(displayUsedFor)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                metadataRow

                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption.weight(.semibold))
                    Text("Expires \(formattedExpiryDate)")
                        .font(.caption.weight(.medium))
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 5)
    }

    private var thumbnail: some View {
        Group {
            if let imageData = medicine.image, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.blue.opacity(0.10))

                    Image(systemName: "pills.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var statusBadge: some View {
        Text(expiryStatus.title)
            .font(.caption2.weight(.bold))
            .foregroundColor(expiryStatus.foregroundColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(expiryStatus.backgroundColor)
            .clipShape(Capsule())
    }

    @ViewBuilder
    private var metadataRow: some View {
        if !metadataItems.isEmpty {
            HStack(spacing: 6) {
                ForEach(metadataItems, id: \.self) { item in
                    Text(item)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.primary.opacity(0.72))
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(Capsule())
                }
            }
            .lineLimit(1)
        }
    }

    private var metadataItems: [String] {
        [displayForm, displayStrength, displayQuantity].compactMap { $0 }
    }

    private var displayName: String {
        let trimmed = medicine.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Unnamed Medicine" : trimmed
    }

    private var displayUsedFor: String {
        let trimmed = medicine.purpose?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Not specified" : trimmed
    }

    private var displayForm: String? {
        stringValue(forKey: "medicineForm")
    }

    private var displayStrength: String? {
        guard let value = stringValue(forKey: "strengthValue") else { return nil }
        let unit = stringValue(forKey: "strengthUnit")
        return [value, unit].compactMap { $0 }.joined(separator: " ")
    }

    private var displayQuantity: String? {
        guard medicine.entity.attributesByName["quantity"] != nil,
              let number = medicine.value(forKey: "quantity") as? NSNumber,
              number.intValue > 0 else {
            return nil
        }

        let unit = stringValue(forKey: "quantityUnit")
        return [number.stringValue, unit].compactMap { $0 }.joined(separator: " ")
    }

    private func stringValue(forKey key: String) -> String? {
        guard medicine.entity.attributesByName[key] != nil,
              let value = medicine.value(forKey: key) as? String else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

#Preview {
    HomeView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
