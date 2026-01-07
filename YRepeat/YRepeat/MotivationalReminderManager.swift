//
//  MotivationalReminderManager.swift
//  YRepeat
//
//  Created for motivational reminder feature
//

import Foundation
import UserNotifications
import SwiftUI
import Combine

class MotivationalReminderManager: ObservableObject {
    @Published var shouldShowMotivationalPopup = false
    @Published var currentMotivationalMessage = ""
    @AppStorage("notificationsEnabled") var notificationsEnabled = false
    @AppStorage("lastWorkoutDate") private var lastWorkoutDateString = ""

    private let motivationalMessages = [
        "💪 Your body is capable of amazing things. Hit the elliptical today!",
        "🔥 Every workout counts. Let's make today count!",
        "⚡️ The only bad workout is the one you didn't do.",
        "🎯 Progress, not perfection. Get moving!",
        "🚀 Your future self will thank you. Start now!",
        "💯 Consistency is key. Keep your streak alive!",
        "🏆 Champions are made in the gym. Be a champion today!",
        "⏰ The best time to work out was yesterday. The second best is now.",
        "🌟 You're stronger than you think. Prove it!",
        "🎪 No more excuses. Let's go!",
        "💎 Your health is your wealth. Invest in it!",
        "🔋 Recharge your energy with a good workout!",
        "🎨 Create the best version of yourself, one workout at a time.",
        "🌈 Small steps lead to big changes. Take one today!",
        "⚔️ Battle the laziness. You've got this!"
    ]

    init() {
        // Don't request permissions on init - only when user enables toggle
        // Check existing authorization status after app is fully initialized
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.checkNotificationStatus()
        }
    }

    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Notification Permissions

    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.notificationsEnabled = granted
                if granted {
                    self.scheduleWeeklyReminders()
                }
            }
        }
    }

    // MARK: - Check if User Needs Motivation

    func checkIfNeedsMotivation(ellipticalMinutes: Double, goalMinutes: Double, startOfWeek: Date) {
        let calendar = Calendar.current
        let now = Date()

        // Calculate days since start of week
        let daysSinceWeekStart = calendar.dateComponents([.day], from: startOfWeek, to: now).day ?? 0

        // Expected progress by this point in the week (linear)
        let expectedProgress = (Double(daysSinceWeekStart) / 7.0) * goalMinutes

        // If we're behind by more than 20%, show motivation
        let progressRatio = ellipticalMinutes / max(1, expectedProgress)

        // Also show if it's Wednesday or later and we have 0 minutes
        let isWednesdayOrLater = daysSinceWeekStart >= 3

        if progressRatio < 0.8 || (isWednesdayOrLater && ellipticalMinutes < 10) {
            showInAppMotivation()
        }
    }

    // MARK: - In-App Motivation

    func showInAppMotivation() {
        currentMotivationalMessage = motivationalMessages.randomElement() ?? "Let's get moving! 💪"
        shouldShowMotivationalPopup = true
    }

    func dismissMotivation() {
        shouldShowMotivationalPopup = false
    }

    // MARK: - Schedule Notifications

    func scheduleWeeklyReminders() {
        guard notificationsEnabled else { return }

        // Cancel existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        let center = UNUserNotificationCenter.current()

        // Schedule reminders for Tuesday, Thursday, and Saturday at 6 PM
        let reminderDays = [3, 5, 7] // Tuesday, Thursday, Saturday (1 = Sunday)

        for day in reminderDays {
            var dateComponents = DateComponents()
            dateComponents.weekday = day
            dateComponents.hour = 18 // 6 PM
            dateComponents.minute = 0

            let content = UNMutableNotificationContent()
            content.title = "Time to Move! 💪"
            content.body = motivationalMessages.randomElement() ?? "Don't forget your workout today!"
            content.sound = .default
            content.badge = 1

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "workout-reminder-\(day)",
                content: content,
                trigger: trigger
            )

            center.add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                }
            }
        }

        // Also schedule a "week ending soon" reminder for Sunday at 4 PM
        var sundayComponents = DateComponents()
        sundayComponents.weekday = 1 // Sunday
        sundayComponents.hour = 16 // 4 PM
        sundayComponents.minute = 0

        let sundayContent = UNMutableNotificationContent()
        sundayContent.title = "Week Ending Soon! ⏰"
        sundayContent.body = "Last chance to hit your weekly goal! Let's finish strong! 🏆"
        sundayContent.sound = .default
        sundayContent.badge = 1

        let sundayTrigger = UNCalendarNotificationTrigger(dateMatching: sundayComponents, repeats: true)
        let sundayRequest = UNNotificationRequest(
            identifier: "workout-reminder-week-end",
            content: sundayContent,
            trigger: sundayTrigger
        )

        center.add(sundayRequest)
    }

    // MARK: - Update Last Workout Date

    func updateLastWorkoutDate(_ date: Date) {
        let formatter = ISO8601DateFormatter()
        lastWorkoutDateString = formatter.string(from: date)
    }

    func getLastWorkoutDate() -> Date? {
        guard !lastWorkoutDateString.isEmpty else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: lastWorkoutDateString)
    }
}
