//
//  HabitHeaderComponents.swift
//  YRepeat
//
//  Created for Habits feature
//

import SwiftUI

struct HabitHeaderView: View {
    @Binding var isMenuShowing: Bool
    let onAdd: () -> Void
    @ObservedObject var manager: HabitManager

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                MenuButton(isMenuShowing: $isMenuShowing)

                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 44, height: 44)
                            .shadow(color: .pink.opacity(0.3), radius: 8, x: 0, y: 4)

                        Image(systemName: "heart.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Text("Habits")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                Spacer()
                
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                        )
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            // Encouragement text
            if !manager.habits.isEmpty {
                Text(encouragementText)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    private var encouragementText: String {
        let activeStreaks = manager.habits.filter { $0.isActiveToday }.count
        let totalStreaks = manager.habits.reduce(0) { $0 + $1.currentStreak }
        
        if activeStreaks == manager.habits.count {
            return "🌟 Amazing! All your habits are active today!"
        } else if totalStreaks > 0 {
            return "💪 You're building something incredible. Keep going!"
        } else {
            return "✨ Every journey begins with a single step."
        }
    }
}

struct HabitStatsView: View {
    @ObservedObject var manager: HabitManager
    
    var body: some View {
        let activeHabits = manager.habits.filter { $0.isActiveToday }.count
        let totalStreaks = manager.habits.reduce(0) { $0 + $1.currentStreak }
        let completionRate = manager.habits.isEmpty ? 0 : Double(activeHabits) / Double(manager.habits.count)
        
        HStack(spacing: 12) {
            // Today's Progress Card
            StatCard(
                title: "Today",
                value: "\(activeHabits)/\(manager.habits.count)",
                icon: "checkmark.circle.fill",
                color: .green,
                footer: "Completed"
            )
            
            // Total Streak Card
            StatCard(
                title: "Streak",
                value: "\(totalStreaks)",
                icon: "flame.fill",
                color: .orange,
                footer: "Total Days"
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let footer: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(footer)
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

