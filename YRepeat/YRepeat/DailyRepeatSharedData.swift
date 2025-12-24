//
//  DailyRepeatSharedData.swift
//  YRepeat
//
//  Shared data storage for Daily Repeat widget
//

import Foundation

struct DailyProgressData: Codable {
    let totalItems: Int
    let completedItems: Int
    let totalProgress: Double
    let lastUpdated: Date

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

    private static let progressKey = "dailyProgressData"

    // MARK: - Save Progress

    static func saveProgress(totalItems: Int, completedItems: Int, totalProgress: Double) {
        guard let defaults = sharedDefaults else {
            print("Failed to access shared defaults for widget")
            return
        }

        let data = DailyProgressData(
            totalItems: totalItems,
            completedItems: completedItems,
            totalProgress: totalProgress,
            lastUpdated: Date()
        )

        do {
            let encoder = JSONEncoder()
            let encoded = try encoder.encode(data)
            defaults.set(encoded, forKey: progressKey)
            defaults.synchronize()
        } catch {
            print("Failed to save progress data: \(error)")
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
