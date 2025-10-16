//
//  TaskHistoryItem.swift
//  YRepeat
//
//  Created by Dino Pelic on 15. 10. 2025..
//

import Foundation

struct TaskHistoryItem: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var targetValue: Int
    var iconName: String
    var color: String
    var completedAt: Date
    var completionCount: Int = 1 // How many times this task has been completed
    
    // Computed properties
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: completedAt)
    }
    
    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: completedAt, relativeTo: Date())
    }
    
    var displayText: String {
        if completionCount > 1 {
            return "Completed \(completionCount) times"
        } else {
            return "Completed"
        }
    }
}
