//
//  NotificationManager.swift
//  YRepeat
//
//  Created for Calendar feature
//

import Foundation
import UserNotifications
import UIKit

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
            } else if let error = error {
                print("❌ Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleNotifications(for eventId: UUID, date: Date, todoTitle: String) {
        // Cancel existing notifications for this event
        cancelNotifications(for: eventId)
        
        // Schedule 3 notifications per day: 9 AM, 2 PM, 7 PM
        let times = [9, 14, 19] // Hours in 24-hour format
        
        for (index, hour) in times.enumerated() {
            var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
            components.hour = hour
            components.minute = 0
            
            guard let notificationDate = Calendar.current.date(from: components) else { continue }
            
            // Only schedule if the notification time is in the future (allows scheduling for today if times haven't passed)
            guard notificationDate > Date() else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = "Medication Reminder"
            content.body = todoTitle
            content.sound = .default
            content.badge = 1
            content.userInfo = [
                "eventId": eventId.uuidString,
                "date": date.timeIntervalSince1970
            ]
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let identifier = "\(eventId.uuidString)_\(index)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Failed to schedule notification: \(error.localizedDescription)")
                } else {
                    print("✅ Scheduled notification for \(notificationDate)")
                }
            }
        }
    }
    
    func cancelNotifications(for eventId: UUID) {
        let identifiers = [
            "\(eventId.uuidString)_0",
            "\(eventId.uuidString)_1",
            "\(eventId.uuidString)_2"
        ]
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        print("✅ Cancelled notifications for event: \(eventId)")
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("✅ Cancelled all notifications")
    }
    
    /// Checks if notifications are already scheduled for a specific event
    func hasNotificationsScheduled(for eventId: UUID, completion: @escaping (Bool) -> Void) {
        let identifiers = [
            "\(eventId.uuidString)_0",
            "\(eventId.uuidString)_1",
            "\(eventId.uuidString)_2"
        ]
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let scheduledIdentifiers = Set(requests.map { $0.identifier })
            let eventIdentifiers = Set(identifiers)
            let hasNotifications = !eventIdentifiers.isDisjoint(with: scheduledIdentifiers)
            completion(hasNotifications)
        }
    }
}

