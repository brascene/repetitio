//
//  HistoryManager.swift
//  YRepeat
//
//  Created by Dino Pelic on 15. 10. 2025..
//

import Foundation
import Combine

class HistoryManager: ObservableObject {
    @Published var items: [HistoryItem] = []

    private let storageKey = "yrepeat_history"

    init() {
        loadHistory()
    }

    func saveItem(videoURL: String, videoId: String, startTime: Double, endTime: Double, repeatCount: Int, videoTitle: String? = nil) {
        let item = HistoryItem(
            videoURL: videoURL,
            videoId: videoId,
            videoTitle: videoTitle,
            startTime: startTime,
            endTime: endTime,
            repeatCount: repeatCount,
            savedAt: Date()
        )

        items.insert(item, at: 0) // Add to beginning
        saveHistory()
    }

    func deleteItem(at offsets: IndexSet) {
        for index in offsets {
            items.remove(at: index)
        }
        saveHistory()
    }

    func deleteItem(_ item: HistoryItem) {
        items.removeAll { $0.id == item.id }
        saveHistory()
    }

    func clearAll() {
        items.removeAll()
        saveHistory()
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return
        }

        do {
            items = try JSONDecoder().decode([HistoryItem].self, from: data)
        } catch {
            print("Failed to load history: \(error)")
        }
    }

    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save history: \(error)")
        }
    }
}
