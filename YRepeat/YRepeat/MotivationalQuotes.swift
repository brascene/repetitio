//
//  MotivationalQuotes.swift
//  YRepeat
//
//  Created for Habits feature
//

import Foundation

struct MotivationalQuote {
    let text: String
    let author: String?
    
    static let goodHabitQuotes: [MotivationalQuote] = [
        MotivationalQuote(text: "Every day is a fresh start. You're doing amazing! 🌟", author: nil),
        MotivationalQuote(text: "Small steps lead to big changes. Keep going! 💪", author: nil),
        MotivationalQuote(text: "You're building something incredible, one day at a time.", author: nil),
        MotivationalQuote(text: "Progress, not perfection. You've got this! ✨", author: nil),
        MotivationalQuote(text: "The best time to plant a tree was 20 years ago. The second best time is now.", author: "Chinese Proverb"),
        MotivationalQuote(text: "You don't have to be great to start, but you have to start to be great.", author: "Zig Ziglar"),
        MotivationalQuote(text: "Success is the sum of small efforts repeated day in and day out.", author: "Robert Collier"),
        MotivationalQuote(text: "The only way to do great work is to love what you do.", author: "Steve Jobs"),
        MotivationalQuote(text: "Your future is created by what you do today, not tomorrow.", author: nil),
        MotivationalQuote(text: "Every expert was once a beginner. Keep going! 🚀", author: nil),
    ]
    
    static let badHabitQuotes: [MotivationalQuote] = [
        MotivationalQuote(text: "You're stronger than your excuses. Keep fighting! 💪", author: nil),
        MotivationalQuote(text: "Every day you resist is a victory. You're winning! 🏆", author: nil),
        MotivationalQuote(text: "Breaking free takes courage, and you have it. Keep going!", author: nil),
        MotivationalQuote(text: "You're not defined by your past. Today is a new beginning. ✨", author: nil),
        MotivationalQuote(text: "The chains of habit are too weak to be felt until they are too strong to be broken.", author: "Warren Buffett"),
        MotivationalQuote(text: "You have power over your mind - not outside events. Realize this, and you will find strength.", author: "Marcus Aurelius"),
        MotivationalQuote(text: "It does not matter how slowly you go as long as you do not stop.", author: "Confucius"),
        MotivationalQuote(text: "The first and best victory is to conquer self.", author: "Plato"),
        MotivationalQuote(text: "You're choosing yourself over the habit. That's powerful! 🌟", author: nil),
        MotivationalQuote(text: "Every moment you resist is building your strength. Keep it up! 💎", author: nil),
    ]
    
    static let streakMilestones: [Int: String] = [
        1: "First day down! You've started your journey. 🎉",
        3: "Three days strong! You're building momentum. 💪",
        7: "One week! You're creating real change. 🌟",
        14: "Two weeks! This is becoming part of who you are. ✨",
        21: "Three weeks! They say it takes 21 days to form a habit - you're doing it! 🎊",
        30: "One month! You're unstoppable! 🚀",
        50: "50 days! You're a habit champion! 🏆",
        100: "100 days! This is incredible dedication! 💎",
        200: "200 days! You're an inspiration! 🌈",
        365: "One year! You've transformed your life! 🎉"
    ]
    
    static func getRandomQuote(for isGoodHabit: Bool) -> MotivationalQuote {
        let quotes = isGoodHabit ? goodHabitQuotes : badHabitQuotes
        return quotes.randomElement() ?? quotes[0]
    }
    
    static func getMilestoneMessage(for streak: Int) -> String? {
        return streakMilestones[streak]
    }
}

