//
//  DailyRepeatManager.swift
//  YRepeat
//
//  Created by Dino Pelic on 15. 10. 2025..
//

import Foundation
import Combine
import UIKit
internal import CoreData

class DailyRepeatManager: ObservableObject {
    @Published var items: [DailyRepeatItem] = []
    @Published var taskHistory: [TaskHistoryItem] = []
    @Published var todayDate: Date = Date()
    
    private let persistenceController: PersistenceController
    private let context: NSManagedObjectContext
    private var timer: Timer?
    
    init(persistenceController: PersistenceController = PersistenceController.shared) {
        self.persistenceController = persistenceController
        self.context = persistenceController.container.viewContext
        loadItems()
        loadTaskHistory()
        setupDailyReset()
        checkForNewDay()
    }
    
    // MARK: - CRUD Operations
    
    func addItem(name: String, targetValue: Int, incrementAmount: Int = 1, iconName: String = "circle.fill", color: String = "blue") {
        let entity = DailyRepeatItemEntity(context: context)
        entity.id = UUID()
        entity.name = name
        entity.targetValue = Int32(targetValue)
        entity.incrementAmount = Int32(incrementAmount)
        entity.iconName = iconName
        entity.color = color
        entity.currentValue = 0
        entity.createdAt = Date()
        
        try? context.save()
        loadItems()
    }
    
    func addFromTemplate(_ template: DailyRepeatTemplate) {
        let entity = DailyRepeatItemEntity(context: context)
        entity.id = UUID()
        entity.name = template.name
        entity.targetValue = Int32(template.targetValue)
        entity.incrementAmount = Int32(template.incrementAmount)
        entity.iconName = template.iconName
        entity.color = template.color
        entity.currentValue = 0
        entity.createdAt = Date()
        
        try? context.save()
        loadItems()
    }
    
    func updateItem(item: DailyRepeatItem, name: String, targetValue: Int, incrementAmount: Int, iconName: String, color: String) {
        if let entity = getEntity(for: item) {
            entity.name = name
            entity.targetValue = Int32(targetValue)
            entity.incrementAmount = Int32(incrementAmount)
            entity.iconName = iconName
            entity.color = color
            // Preserve currentValue - don't reset progress!
            try? context.save()
            loadItems()
        }
    }
    
    func deleteItem(_ item: DailyRepeatItem) {
        if let entity = getEntity(for: item) {
            context.delete(entity)
            try? context.save()
            loadItems()
        }
    }
    
    func deleteItem(at offsets: IndexSet) {
        for index in offsets {
            let item = items[index]
            if let entity = getEntity(for: item) {
                context.delete(entity)
            }
        }
        try? context.save()
        loadItems()
    }
    
    // MARK: - Progress Management
    
    func incrementItem(_ item: DailyRepeatItem) {
        if let entity = getEntity(for: item) {
            entity.currentValue += entity.incrementAmount
            if entity.currentValue >= entity.targetValue {
                entity.lastCompleted = Date()
                // Add to task history
                addToTaskHistory(item: item)
            }
            try? context.save()
            loadItems()
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
    
    func resetItem(_ item: DailyRepeatItem) {
        if let entity = getEntity(for: item) {
            entity.currentValue = 0
            try? context.save()
            loadItems()
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
            resetAllForNewDay()
        }
    }
    
    func resetAllForNewDay() {
        let fetchRequest: NSFetchRequest<DailyRepeatItemEntity> = DailyRepeatItemEntity.fetchRequest()
        
        do {
            let entities = try context.fetch(fetchRequest)
            for entity in entities {
                entity.currentValue = 0
            }
            try? context.save()
            todayDate = Date()
            loadItems()
        } catch {
            print("Failed to reset items for new day: \(error)")
        }
    }
    
    // MARK: - Task History Management
    
    private func addToTaskHistory(item: DailyRepeatItem) {
        // Check if task already exists in history for today
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Find existing task history item for today
        if let existingIndex = taskHistory.firstIndex(where: { historyItem in
            historyItem.name == item.name &&
            calendar.isDate(historyItem.completedAt, inSameDayAs: today)
        }) {
            // Increment completion count
            taskHistory[existingIndex].completionCount += 1
            taskHistory[existingIndex].completedAt = Date()
        } else {
            // Add new task to history
            let historyItem = TaskHistoryItem(
                name: item.name,
                targetValue: item.targetValue,
                iconName: item.iconName,
                color: item.color,
                completedAt: Date()
            )
            taskHistory.insert(historyItem, at: 0) // Add to beginning
        }
        
        // Save to UserDefaults (simple persistence for now)
        saveTaskHistory()
    }
    
    func restartTaskFromHistory(_ historyItem: TaskHistoryItem) {
        // Create a new task based on the history item
        addItem(
            name: historyItem.name,
            targetValue: historyItem.targetValue,
            incrementAmount: 1, // Default increment
            iconName: historyItem.iconName,
            color: historyItem.color
        )
    }
    
    func clearTaskHistory() {
        taskHistory.removeAll()
        saveTaskHistory()
    }
    
    private func loadTaskHistory() {
        if let data = UserDefaults.standard.data(forKey: "task_history"),
           let history = try? JSONDecoder().decode([TaskHistoryItem].self, from: data) {
            taskHistory = history
        }
    }
    
    private func saveTaskHistory() {
        if let data = try? JSONEncoder().encode(taskHistory) {
            UserDefaults.standard.set(data, forKey: "task_history")
        }
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
        let fetchRequest: NSFetchRequest<DailyRepeatItemEntity> = DailyRepeatItemEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \DailyRepeatItemEntity.createdAt, ascending: true)]
        
        do {
            let entities = try context.fetch(fetchRequest)
            items = entities.compactMap { entity in
                guard let id = entity.id,
                      let name = entity.name,
                      let iconName = entity.iconName,
                      let color = entity.color else {
                    return nil
                }
                
                return DailyRepeatItem(
                    id: id,
                    name: name,
                    targetValue: Int(entity.targetValue),
                    currentValue: Int(entity.currentValue),
                    incrementAmount: Int(entity.incrementAmount),
                    iconName: iconName,
                    color: color,
                    createdAt: entity.createdAt ?? Date(),
                    lastCompleted: entity.lastCompleted
                )
            }
        } catch {
            print("Failed to load daily repeat items: \(error)")
            items = []
        }
    }
    
    private func getEntity(for item: DailyRepeatItem) -> DailyRepeatItemEntity? {
        let fetchRequest: NSFetchRequest<DailyRepeatItemEntity> = DailyRepeatItemEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", item.id as CVarArg)
        
        do {
            let entities = try context.fetch(fetchRequest)
            return entities.first
        } catch {
            print("Failed to fetch entity: \(error)")
            return nil
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}
