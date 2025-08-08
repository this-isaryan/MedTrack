//
//  NotificationManager.swift
//  MedTrack
//
//  Created by Aryan kumar on 8/6/25.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestPermisson() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Permission error: \(error)")
            } else {
                print("Notification permission granted. \(granted)")
            }
        }
    }
    
    func scheduleExpiryNotification(for medicine: Medicine) {
        guard let id = medicine.id?.uuidString,
              let name = medicine.name,
              let expiryDate = medicine.expiryDate else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Medicine Expiry Reminder"
        content.body = "\(name) is expiring soon!"
        content.sound = .default
        
        // Schedule for 7 days before expiry
        let triggerDate = Calendar.current.date(byAdding: .day, value: -7, to: expiryDate) ?? Date()
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day], from: triggerDate), repeats: false)
        
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
}
