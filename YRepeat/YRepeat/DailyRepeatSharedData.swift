//
//  DailyRepeatSharedData.swift
//  YRepeat
//
//  Shared data storage for Daily Repeat widget
//

import Foundation

struct WidgetDailyItem: Codable {
    let name: String
    let progress: Double
    let iconName: String
    let color: String

    var progressPercentage: Int {
        return Int(progress * 100)
    }
}

struct DailyProgressData: Codable {
    let totalItems: Int
    let completedItems: Int
    let totalProgress: Double
    let lastUpdated: Date
    let items: [WidgetDailyItem]

    var progressPercentage: Int {
        return Int(totalProgress * 100)
    }

    var itemsRemaining: Int {
        return totalItems - completedItems
    }
}

class DailyRepeatSharedData {
    // Use the existing App Group or create a new one
    static let appGroupIdentifier = "group.com.yrepeat.appblocking"

    private static var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupIdentifier)
    }

    private static let progressKey = "dailyProgressData_v2"

    // MARK: - Save Progress

    static func saveProgress(totalItems: Int, completedItems: Int, totalProgress: Double, items: [WidgetDailyItem] = []) {
        guard let defaults = sharedDefaults else {
            print("Widget Error: Failed to access shared defaults group.com.yrepeat.appblocking")
            return
        }

        let data = DailyProgressData(
            totalItems: totalItems,
            completedItems: completedItems,
            totalProgress: totalProgress,
            lastUpdated: Date(),
            items: items
        )

        do {
            let encoder = JSONEncoder()
            let encoded = try encoder.encode(data)
            defaults.set(encoded, forKey: progressKey)
            defaults.synchronize()
            print("Widget Success: Saved \(items.count) items to shared defaults")
        } catch {
            print("Widget Error: Failed to save progress data: \(error)")
        }
    }

    // MARK: - Load Progress

    static func loadProgress() -> DailyProgressData? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: progressKey) else {
            return nil
        }

        do {
            let decoder = JSONDecoder()
            let progress = try decoder.decode(DailyProgressData.self, from: data)
            return progress
        } catch {
            print("Failed to load progress data: \(error)")
            return nil
        }
    }
}
