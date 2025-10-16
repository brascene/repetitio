//
//  DataMigrationManager.swift
//  YRepeat
//
//  Created by Dino Pelic on 15. 10. 2025..
//

import Foundation
internal import CoreData

class DataMigrationManager {
    static let shared = DataMigrationManager()
    
    private let migrationKey = "data_migrated_to_coredata"
    
    private init() {}
    
    func migrateDataIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: migrationKey) else {
            print("Data already migrated to Core Data")
            return
        }
        
        print("Starting data migration from UserDefaults to Core Data...")
        
        migrateHistoryData()
        migrateDailyRepeatData()
        
        UserDefaults.standard.set(true, forKey: migrationKey)
        print("Data migration completed successfully")
    }
    
    private func migrateHistoryData() {
        guard let data = UserDefaults.standard.data(forKey: "yrepeat_history") else {
            print("No history data to migrate")
            return
        }
        
        do {
            let items = try JSONDecoder().decode([HistoryItem].self, from: data)
            let context = PersistenceController.shared.container.viewContext
            
            for item in items {
                let entity = HistoryItemEntity(context: context)
                entity.id = item.id
                entity.url = item.videoURL
                entity.videoID = item.videoId
                entity.title = item.videoTitle
                entity.startTime = String(item.startTime)
                entity.endTime = String(item.endTime)
                entity.repeatCount = Int32(item.repeatCount)
                entity.createdAt = item.savedAt
            }
            
            try context.save()
            print("Migrated \(items.count) history items to Core Data")
            
            // Remove old UserDefaults data
            UserDefaults.standard.removeObject(forKey: "yrepeat_history")
            
        } catch {
            print("Failed to migrate history data: \(error)")
        }
    }
    
    private func migrateDailyRepeatData() {
        guard let data = UserDefaults.standard.data(forKey: "daily_repeat_items") else {
            print("No daily repeat data to migrate")
            return
        }
        
        do {
            let items = try JSONDecoder().decode([DailyRepeatItem].self, from: data)
            let context = PersistenceController.shared.container.viewContext
            
            for item in items {
                let entity = DailyRepeatItemEntity(context: context)
                entity.id = item.id
                entity.name = item.name
                entity.targetValue = Int32(item.targetValue)
                entity.currentValue = Int32(item.currentValue)
                entity.incrementAmount = Int32(item.incrementAmount)
                entity.iconName = item.iconName
                entity.color = item.color
                entity.createdAt = item.createdAt
                entity.lastCompleted = item.lastCompleted
            }
            
            try context.save()
            print("Migrated \(items.count) daily repeat items to Core Data")
            
            // Remove old UserDefaults data
            UserDefaults.standard.removeObject(forKey: "daily_repeat_items")
            
        } catch {
            print("Failed to migrate daily repeat data: \(error)")
        }
    }
    
    func resetMigrationFlag() {
        UserDefaults.standard.removeObject(forKey: migrationKey)
        print("Migration flag reset - data will be migrated on next app launch")
    }
}
