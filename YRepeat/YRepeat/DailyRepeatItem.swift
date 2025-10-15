//
//  DailyRepeatItem.swift
//  YRepeat
//
//  Created by Dino Pelic on 15. 10. 2025..
//

import Foundation

struct DailyRepeatItem: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var targetValue: Int // The actual target value (e.g., 12000 steps, 8 glasses)
    var currentValue: Int = 0 // Current progress value
    var incrementAmount: Int = 1 // How much to increment per tap
    var iconName: String = "circle.fill"
    var color: String = "blue" // Color name for the item
    var createdAt: Date = Date()
    var lastCompleted: Date?
    
    // Computed properties
    var isCompleted: Bool {
        return currentValue >= targetValue
    }
    
    var progress: Double {
        guard targetValue > 0 else { return 0 }
        let actualProgress = Double(currentValue) / Double(targetValue)
        return min(actualProgress, 1.0)
    }
    
    var progressText: String {
        return "\(currentValue) / \(targetValue)"
    }
    
    var completionPercentage: Int {
        return Int(progress * 100)
    }
    
    // Reset for new day
    mutating func resetForNewDay() {
        currentValue = 0
    }
    
    // Increment progress
    mutating func increment() {
        currentValue += incrementAmount
        if isCompleted {
            lastCompleted = Date()
        }
    }
}

// Predefined templates for common daily repeats
struct DailyRepeatTemplate {
    let name: String
    let targetValue: Int
    let incrementAmount: Int
    let iconName: String
    let color: String
    
    static let templates: [DailyRepeatTemplate] = [
        DailyRepeatTemplate(name: "Drink Water", targetValue: 8, incrementAmount: 1, iconName: "drop.fill", color: "blue"),
        DailyRepeatTemplate(name: "Walk", targetValue: 15000, incrementAmount: 1000, iconName: "figure.walk", color: "green"),
        DailyRepeatTemplate(name: "Read", targetValue: 30, incrementAmount: 5, iconName: "book.fill", color: "purple"),
        DailyRepeatTemplate(name: "Exercise", targetValue: 30, incrementAmount: 5, iconName: "dumbbell.fill", color: "orange"),
        DailyRepeatTemplate(name: "Meditate", targetValue: 10, incrementAmount: 1, iconName: "leaf.fill", color: "mint"),
        DailyRepeatTemplate(name: "Practice Language", targetValue: 15, incrementAmount: 5, iconName: "globe", color: "cyan"),
        DailyRepeatTemplate(name: "Study", targetValue: 120, incrementAmount: 15, iconName: "graduationcap.fill", color: "indigo"),
        DailyRepeatTemplate(name: "Journal", targetValue: 1, incrementAmount: 1, iconName: "pencil", color: "pink"),
        DailyRepeatTemplate(name: "Push-ups", targetValue: 50, incrementAmount: 5, iconName: "figure.strengthtraining.traditional", color: "red"),
        DailyRepeatTemplate(name: "Practice Instrument", targetValue: 20, incrementAmount: 5, iconName: "music.note", color: "yellow")
    ]
}
