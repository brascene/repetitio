//
//  HabitCardView.swift
//  YRepeat
//
//  Created for Habits feature
//

import SwiftUI

struct HabitCardView: View {
    let habit: Habit
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onResetProgress: () -> Void
    
    @State private var isPressed = false
    @State private var showingResetConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Main Card Content
            HStack(spacing: 16) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    colorFromString(habit.color),
                                    colorFromString(habit.color).opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60) // Slightly smaller for better proportion
                        .shadow(color: colorFromString(habit.color).opacity(0.4), radius: 8, x: 0, y: 4)
                    
                    Group {
                        if UIImage(systemName: habit.iconName) != nil {
                            Image(systemName: habit.iconName)
                                .font(.system(size: 28, weight: .semibold))
                        } else {
                            Text(HabitIcons.emojiForIcon(habit.iconName))
                                .font(.system(size: 24))
                        }
                    }
                    .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    // Habit Name
                    HStack {
                        Text(habit.name)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Status indicator icon
                        if habit.isActiveToday {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    
                    // Status text
                    Text(statusText)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                    
                    // Streak info (Compact)
                    HStack(spacing: 12) {
                        compactStreakBadge(value: habit.currentStreak, icon: "flame.fill", color: .orange)
                        if habit.longestStreak > 0 {
                            compactStreakBadge(value: habit.longestStreak, icon: "trophy.fill", color: .yellow)
                        }
                    }
                }
                
                Spacer()
                
                // Menu
                Menu {
                    Button {
                        onEdit()
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        showingResetConfirmation = true
                    } label: {
                        Label(habit.isGoodHabit ? "Reset Streak" : "I Broke It", systemImage: "arrow.counterclockwise")
                    }
                    .disabled(habit.currentStreak == 0 && habit.lastCompletedDate == nil)
                    
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20, weight: .bold)) // Bold for better visibility
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(16)
            .background(
                ZStack {
                    // Modern Material Background
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark) // Force dark blurred look
                    
                    // Subtle Gradient Overlay
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: habit.isActiveToday
                                    ? [
                                        colorFromString(habit.color).opacity(0.15),
                                        colorFromString(habit.color).opacity(0.05)
                                    ]
                                    : [
                                        Color.white.opacity(0.05),
                                        Color.white.opacity(0.02)
                                    ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(habit.isActiveToday ? 0.3 : 0.15),
                                Color.white.opacity(habit.isActiveToday ? 0.1 : 0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24)) // Ensure clips
            
            // Action Button (Integrated)
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    onTap()
                }
            } label: {
                HStack {
                    Spacer()
                    
                    if habit.isActiveToday {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                            Text("Completed")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.green.opacity(0.9))
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: habit.isGoodHabit ? "arrow.up" : "arrow.down")
                                .font(.system(size: 16, weight: .bold))
                            Text(habit.isGoodHabit ? "Mark Done" : "Mark Resisted")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 14)
                .background(
                    ZStack {
                        if habit.isActiveToday {
                            Color.green.opacity(0.15)
                        } else {
                            LinearGradient(
                                colors: [
                                    colorFromString(habit.color).opacity(0.4),
                                    colorFromString(habit.color).opacity(0.2)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        }
                    }
                )
                .cornerRadius(16)
            }
            .buttonStyle(PlainButtonStyle()) // Remove default button tap effect to handle custom scale
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .disabled(habit.isActiveToday)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.2)) // Shadow backdrop
                .blur(radius: 10)
                .offset(y: 5)
        )
        // Container scale effect on press
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in
            isPressed = pressing
        }) {
            // Action handled by menu
        }
        .alert(
            habit.isGoodHabit ? "Reset habit streak?" : "You broke this habit?",
            isPresented: $showingResetConfirmation
        ) {
            Button("Cancel", role: .cancel) { }
            Button("Confirm", role: .destructive) {
                onResetProgress()
            }
        } message: {
            Text("This will reset your current streak to 0.")
        }
    }
    
    private var statusText: String {
        if habit.isActiveToday {
            return "Completed today!"
        } else if habit.currentStreak > 0 {
            return "\(habit.currentStreak) day streak"
        } else {
            return habit.isGoodHabit ? "Do this today" : "Avoid this today"
        }
    }
    
    private func compactStreakBadge(value: Int, icon: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            
            Text("\(value)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.2))
        )
        .overlay(
            Capsule()
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func colorFromString(_ colorName: String) -> Color {
        // Simple mapping, can be moved to a shared utility
        switch colorName.lowercased() {
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        case "red": return .red
        case "pink": return .pink
        case "yellow": return .yellow
        case "mint": return .mint
        case "cyan": return .cyan
        case "indigo": return .indigo
        default: 
            if colorName.hasPrefix("#") {
                return Color(hex: colorName) ?? .blue
            }
            return .blue
        }
    }
}

