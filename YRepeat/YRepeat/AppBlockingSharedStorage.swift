//
//  AppBlockingSharedStorage.swift
//  YRepeat
//
//  Created for App Blocking feature - Shared between app and extension
//

import Foundation
import FamilyControls

class AppBlockingSharedStorage {
    // IMPORTANT: Replace this with your actual App Group identifier
    // Format: group.com.yourcompany.yrepeat
    static let appGroupIdentifier = "group.com.yrepeat.appblocking"

    private static var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupIdentifier)
    }

    // Keys for shared storage
    private enum Keys {
        static let selectedAppsData = "selectedAppsData"
        static let startTimeHour = "startTimeHour"
        static let startTimeMinute = "startTimeMinute"
        static let endTimeHour = "endTimeHour"
        static let endTimeMinute = "endTimeMinute"
    }

    // MARK: - Save Methods

    static func saveSelectedApps(_ selection: FamilyActivitySelection) {
        guard let defaults = sharedDefaults else {
            print("Failed to access shared defaults")
            return
        }

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(selection)
            defaults.set(data, forKey: Keys.selectedAppsData)
            defaults.synchronize()
        } catch {
            print("Failed to save selected apps to shared storage: \(error)")
        }
    }

    static func saveTimeRange(startTime: Date, endTime: Date) {
        guard let defaults = sharedDefaults else {
            print("Failed to access shared defaults")
            return
        }

        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)

        defaults.set(startComponents.hour, forKey: Keys.startTimeHour)
        defaults.set(startComponents.minute, forKey: Keys.startTimeMinute)
        defaults.set(endComponents.hour, forKey: Keys.endTimeHour)
        defaults.set(endComponents.minute, forKey: Keys.endTimeMinute)
        defaults.synchronize()
    }

    // MARK: - Load Methods

    static func loadSelectedApps() -> FamilyActivitySelection {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: Keys.selectedAppsData) else {
            return FamilyActivitySelection()
        }

        do {
            let decoder = JSONDecoder()
            let selection = try decoder.decode(FamilyActivitySelection.self, from: data)
            return selection
        } catch {
            print("Failed to load selected apps from shared storage: \(error)")
        }

        return FamilyActivitySelection()
    }

    static func loadTimeRange() -> (startTime: Date, endTime: Date) {
        guard let defaults = sharedDefaults else {
            // Default: 9 PM - 6 AM
            return (
                Calendar.current.date(from: DateComponents(hour: 21, minute: 0))!,
                Calendar.current.date(from: DateComponents(hour: 6, minute: 0))!
            )
        }

        let startHour = defaults.integer(forKey: Keys.startTimeHour)
        let startMinute = defaults.integer(forKey: Keys.startTimeMinute)
        let endHour = defaults.integer(forKey: Keys.endTimeHour)
        let endMinute = defaults.integer(forKey: Keys.endTimeMinute)

        let calendar = Calendar.current
        let startTime = calendar.date(from: DateComponents(hour: startHour, minute: startMinute)) ??
                       calendar.date(from: DateComponents(hour: 21, minute: 0))!
        let endTime = calendar.date(from: DateComponents(hour: endHour, minute: endMinute)) ??
                     calendar.date(from: DateComponents(hour: 6, minute: 0))!

        return (startTime, endTime)
    }
}
