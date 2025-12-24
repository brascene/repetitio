//
//  HabitManager.swift
//  YRepeat
//
//  Created for Habits feature
//

import Foundation
import Combine
import UIKit
internal import CoreData

struct Habit: Identifiable {
    let id: UUID
    var name: String
    var isGoodHabit: Bool
    var currentStreak: Int
    var longestStreak: Int
    var lastCompletedDate: Date?
    let createdAt: Date
    var iconName: String
    var color: String
    
    var isActiveToday: Bool {
        guard let lastDate = lastCompletedDate else { return false }
        return Calendar.current.isDateInToday(lastDate)
    }
    
    var daysSinceLastCompletion: Int {
        guard let lastDate = lastCompletedDate else {
            return Int.max // Never completed
        }
        let lastDay = Calendar.current.startOfDay(for: lastDate)
        let today = Calendar.current.startOfDay(for: Date())
        let days = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
        return days
    }
    
    var streakStatus: StreakStatus {
        if isActiveToday {
            return .active
        } else if daysSinceLastCompletion == 1 {
            return .pending
        } else {
            return .inactive
        }
    }
}

enum StreakStatus {
    case active
    case pending
    case inactive
}

class HabitManager: ObservableObject {
    @Published var habits: [Habit] = []
    
    private let persistenceController: PersistenceController
    private let context: NSManagedObjectContext
    private var foregroundObserver: NSObjectProtocol?
    private var activeObserver: NSObjectProtocol?
    
    init(persistenceController: PersistenceController = PersistenceController.shared) {
        self.persistenceController = persistenceController
        self.context = persistenceController.container.viewContext
        
        loadHabits()
        checkDailyStreaks()
        setupAppLifecycleObserver()
    }
    
    private func setupAppLifecycleObserver() {
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkDailyStreaks()
        }
        
        activeObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkDailyStreaks()
        }
    }
    
    deinit {
        if let observer = foregroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = activeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - CRUD Operations
    
    func addHabit(name: String, isGoodHabit: Bool, iconName: String = "star.fill", color: String = "blue") {
        let entity = HabitEntity(context: context)
        entity.id = UUID()
        entity.name = name
        entity.isGoodHabit = isGoodHabit
        entity.currentStreak = 0
        entity.longestStreak = 0
        entity.iconName = iconName
        entity.color = color
        entity.createdAt = Date()
        
        try? context.save()
        loadHabits()
    }
    
    func updateHabit(habit: Habit, name: String, iconName: String, color: String) {
        guard let entity = getHabitEntity(for: habit.id) else { return }
        
        entity.name = name
        entity.iconName = iconName
        entity.color = color
        
        try? context.save()
        loadHabits()
    }
    
    func deleteHabit(_ habit: Habit) {
        guard let entity = getHabitEntity(for: habit.id) else { return }
        
        context.delete(entity)
        try? context.save()
        loadHabits()
    }
    
    // MARK: - Streak Management
    
    func markHabitCompleted(_ habit: Habit) {
        guard let entity = getHabitEntity(for: habit.id) else { return }
        
        let today = Calendar.current.startOfDay(for: Date())
        let lastDate = entity.lastCompletedDate.map { Calendar.current.startOfDay(for: $0) }
        
        // Check if already completed today
        if let lastDate = lastDate, lastDate == today {
            return // Already completed today
        }
        
        // Check if streak continues (completed yesterday)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
        if let lastDate = lastDate, lastDate == yesterday {
            // Continue streak
            entity.currentStreak += 1
        } else {
            // New streak or broken streak
            entity.currentStreak = 1
        }
        
        // Update longest streak
        if entity.currentStreak > entity.longestStreak {
            entity.longestStreak = entity.currentStreak
        }
        
        entity.lastCompletedDate = Date()
        
        try? context.save()
        loadHabits()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }

    /// Resets the habit's current progress (streak) back to zero and clears the last completed date.
    /// This is used when the user "breaks" a bad habit or wants to restart a good habit streak.
    func resetHabitProgress(_ habit: Habit) {
        guard let entity = getHabitEntity(for: habit.id) else { return }

        entity.currentStreak = 0
        entity.lastCompletedDate = nil

        try? context.save()
        loadHabits()

        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    func checkDailyStreaks() {
        let fetchRequest: NSFetchRequest<HabitEntity> = HabitEntity.fetchRequest()
        
        do {
            let entities = try context.fetch(fetchRequest)
            let today = Calendar.current.startOfDay(for: Date())
            var hasChanges = false
            
            for entity in entities {
                guard let lastDate = entity.lastCompletedDate else { continue }
                
                let lastCompletedDay = Calendar.current.startOfDay(for: lastDate)
                let daysSince = Calendar.current.dateComponents([.day], from: lastCompletedDay, to: today).day ?? 0
                
                // If streak is broken (more than 1 day since last completion)
                if daysSince > 1 && entity.currentStreak > 0 {
                    entity.currentStreak = 0
                    hasChanges = true
                }
            }
            
            if hasChanges {
                try context.save()
                loadHabits()
            }
        } catch {
            print("Failed to check daily streaks: \(error)")
        }
    }
    
    // MARK: - Persistence
    
    private func loadHabits() {
        let fetchRequest: NSFetchRequest<HabitEntity> = HabitEntity.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \HabitEntity.isGoodHabit, ascending: false),
            NSSortDescriptor(keyPath: \HabitEntity.createdAt, ascending: true)
        ]
        
        do {
            let entities = try context.fetch(fetchRequest)
            habits = entities.compactMap { entity in
                guard let id = entity.id,
                      let name = entity.name,
                      let iconName = entity.iconName,
                      let color = entity.color else {
                    return nil
                }
                
                return Habit(
                    id: id,
                    name: name,
                    isGoodHabit: entity.isGoodHabit,
                    currentStreak: Int(entity.currentStreak),
                    longestStreak: Int(entity.longestStreak),
                    lastCompletedDate: entity.lastCompletedDate,
                    createdAt: entity.createdAt ?? Date(),
                    iconName: iconName,
                    color: color
                )
            }
        } catch {
            print("Failed to load habits: \(error)")
            habits = []
        }
    }
    
    private func getHabitEntity(for habitId: UUID) -> HabitEntity? {
        let fetchRequest: NSFetchRequest<HabitEntity> = HabitEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", habitId as CVarArg)
        
        do {
            let entities = try context.fetch(fetchRequest)
            return entities.first
        } catch {
            print("Failed to fetch habit entity: \(error)")
            return nil
        }
    }
}

