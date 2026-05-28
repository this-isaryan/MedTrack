//
//  NotificationManager.swift
//  MedTrack
//
//  Created by Aryan kumar on 8/6/25.
//

import Foundation
import UserNotifications
import Combine

struct ExpiryReminderRoute: Identifiable, Equatable {
    enum Action: Equatable {
        case openDetails
        case snooze
        case restock
    }

    let medicineID: UUID
    let action: Action

    var id: String {
        "\(medicineID.uuidString)-\(action)"
    }
}

final class NotificationNavigationRouter: ObservableObject {
    static let shared = NotificationNavigationRouter()

    @Published var route: ExpiryReminderRoute?

    private init() {}

    func openMedicine(id: UUID, action: ExpiryReminderRoute.Action) {
        route = ExpiryReminderRoute(medicineID: id, action: action)
    }
}

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    private override init() {
        super.init()
    }

    func configure() {
        UNUserNotificationCenter.current().delegate = self
        registerNotificationActions()
    }
    
    func requestPermission() {
        configure()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Permission error: \(error)")
            } else {
                print("Notification permission granted. \(granted)")
            }
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }

        let identifier = response.notification.request.identifier
        guard let medicineID = UUID(uuidString: identifier) else {
            print("Expiry notification action ignored: invalid medicine id \(identifier)")
            return
        }

        let routeAction: ExpiryReminderRoute.Action
        switch response.actionIdentifier {
        case "SNOOZE_EXPIRY_REMINDER":
            print("Expiry notification action tapped: Snooze for medicine \(medicineID)")
            routeAction = .snooze
        case "MARK_AS_RESTOCKED":
            print("Expiry notification action tapped: Restocked for medicine \(medicineID)")
            routeAction = .restock
        case UNNotificationDefaultActionIdentifier:
            print("Expiry notification body tapped for medicine \(medicineID)")
            routeAction = .openDetails
        default:
            print("Expiry notification action tapped: \(response.actionIdentifier) for medicine \(medicineID)")
            routeAction = .openDetails
        }

        DispatchQueue.main.async {
            NotificationNavigationRouter.shared.openMedicine(id: medicineID, action: routeAction)
        }
    }

    func requestPermisson() {
        requestPermission()
    }
    
    func scheduleExpiryNotification(for medicine: Medicine) {
        guard let id = medicine.id?.uuidString,
              let name = medicine.name,
              let expiryDate = medicine.expiryDate else {
            return
        }

        cancelNotification(for: medicine)
        
        let content = UNMutableNotificationContent()
        content.title = "Medicine Expiry Reminder"
        content.body = "\(name) is expiring soon. Open MedTrack to snooze or mark it as restocked."
        content.sound = .default
        content.categoryIdentifier = "EXPIRY_REMINDER"
        
        let triggerDate = nextExpiryReminderDate(for: medicine, expiryDate: expiryDate)

        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate), repeats: false)
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
    }
    func cancelNotification(for medicine: Medicine) {
        if let id = medicine.id?.uuidString {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        }
    }

    private func nextExpiryReminderDate(for medicine: Medicine, expiryDate: Date) -> Date {
        let now = Date()
        if let snoozedUntil = medicine.value(forKey: "expiryReminderSnoozedUntil") as? Date, snoozedUntil > now {
            return snoozedUntil
        }

        let sevenDaysBeforeExpiry = Calendar.current.date(byAdding: .day, value: -7, to: expiryDate) ?? expiryDate
        if sevenDaysBeforeExpiry > now {
            return sevenDaysBeforeExpiry
        }

        return Calendar.current.date(byAdding: .minute, value: 1, to: now) ?? now
    }

    private func registerNotificationActions() {
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_EXPIRY_REMINDER",
            title: "Snooze",
            options: [.foreground]
        )
        let restockedAction = UNNotificationAction(
            identifier: "MARK_AS_RESTOCKED",
            title: "Restocked",
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: "EXPIRY_REMINDER",
            actions: [snoozeAction, restockedAction],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}
