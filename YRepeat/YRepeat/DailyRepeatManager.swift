//
//  DailyRepeatManager.swift
//  YRepeat
//
//  Created by Dino Pelic on 15. 10. 2025..
//

import Foundation
import Combine
import UIKit

class DailyRepeatManager: ObservableObject {
    @Published var items: [DailyRepeatItem] = []
    @Published var todayDate: Date = Date()
    
    private let storageKey = "daily_repeat_items"
    private var timer: Timer?
    
    init() {
        loadItems()
        setupDailyReset()
        checkForNewDay()
    }
    
    // MARK: - CRUD Operations
    
    func addItem(name: String, targetValue: Int, incrementAmount: Int = 1, iconName: String = "circle.fill", color: String = "blue") {
        let item = DailyRepeatItem(
            name: name,
            targetValue: targetValue,
            incrementAmount: incrementAmount,
            iconName: iconName,
            color: color
        )
        items.append(item)
        saveItems()
    }
    
    func addFromTemplate(_ template: DailyRepeatTemplate) {
        let item = DailyRepeatItem(
            name: template.name,
            targetValue: template.targetValue,
            incrementAmount: template.incrementAmount,
            iconName: template.iconName,
            color: template.color
        )
        items.append(item)
        saveItems()
    }
    
    func updateItem(item: DailyRepeatItem, name: String, targetValue: Int, incrementAmount: Int, iconName: String, color: String) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].name = name
            items[index].targetValue = targetValue
            items[index].incrementAmount = incrementAmount
            items[index].iconName = iconName
            items[index].color = color
            // Preserve currentValue - don't reset progress!
            saveItems()
        }
    }
    
    func deleteItem(_ item: DailyRepeatItem) {
        items.removeAll { $0.id == item.id }
        saveItems()
    }
    
    func deleteItem(at offsets: IndexSet) {
        for index in offsets {
            items.remove(at: index)
        }
        saveItems()
    }
    
    // MARK: - Progress Management
    
    func incrementItem(_ item: DailyRepeatItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].increment()
            saveItems()
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
    
    func resetItem(_ item: DailyRepeatItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].resetForNewDay()
            saveItems()
        }
    }
    
    // MARK: - Daily Management
    
    private func setupDailyReset() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkForNewDay()
        }
    }
    
    private func checkForNewDay() {
        let calendar = Calendar.current
        let currentDate = Date()
        
        if !calendar.isDate(todayDate, inSameDayAs: currentDate) {
            // New day - reset all items
            for index in items.indices {
                items[index].resetForNewDay()
            }
            todayDate = currentDate
            saveItems()
        }
    }
    
    func resetAllForNewDay() {
        for index in items.indices {
            items[index].resetForNewDay()
        }
        todayDate = Date()
        saveItems()
    }
    
    // MARK: - Statistics
    
    var completedItemsCount: Int {
        return items.filter { $0.isCompleted }.count
    }
    
    var totalItemsCount: Int {
        return items.count
    }
    
    var completionRate: Double {
        guard totalItemsCount > 0 else { return 0 }
        return Double(completedItemsCount) / Double(totalItemsCount)
    }
    
    var totalProgress: Double {
        guard !items.isEmpty else { return 0 }
        let totalProgress = items.reduce(0.0) { $0 + $1.progress }
        return totalProgress / Double(items.count)
    }
    
    // MARK: - Persistence
    
    private func loadItems() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return
        }
        
        do {
            items = try JSONDecoder().decode([DailyRepeatItem].self, from: data)
        } catch {
            print("Failed to load daily repeat items: \(error)")
        }
    }
    
    private func saveItems() {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save daily repeat items: \(error)")
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}
