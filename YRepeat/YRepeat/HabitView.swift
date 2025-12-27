//
//  HabitView.swift
//  YRepeat
//
//  Created for Habits feature
//

import SwiftUI

struct HabitView: View {
    @EnvironmentObject var manager: HabitManager
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var isMenuShowing: Bool
    @State private var showingAddHabit = false
    @State private var selectedHabit: Habit?
    @State private var editingHabit: Habit?
    @State private var showingCelebration = false
    @State private var celebrationMessage = ""
    @State private var showingQuote = false
    @State private var currentQuote: MotivationalQuote?
    
    // Animation states
    @State private var animateContent = false
    
    var body: some View {
        ZStack {
            // Premium background
            LiquidBackgroundView()
            
            VStack(spacing: 0) {
                // Header
                HabitHeaderView(isMenuShowing: $isMenuShowing, onAdd: { showingAddHabit = true }, manager: manager)
                    .zIndex(1)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Stats & Progress
                        if !manager.habits.isEmpty {
                            HabitStatsView(manager: manager)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // Content
                        if manager.habits.isEmpty {
                            emptyStateView
                                .padding(.top, 40)
                                .transition(.opacity)
                        } else {
                            habitLists
                        }
                    }
                    .padding(.top, 24) // Added top padding
                    .padding(.bottom, 100) // Space for tab bar
                }
                .scrollContentBackground(.hidden)
            }
        }
        .sheet(isPresented: $showingAddHabit) {
            AddHabitView(manager: manager)
        }
        .sheet(item: $editingHabit) { habit in
            EditHabitView(manager: manager, habit: habit)
        }
        .overlay {
            if showingCelebration {
                HabitCelebrationOverlay(
                    isShowing: $showingCelebration,
                    message: celebrationMessage,
                    streak: selectedHabit?.currentStreak ?? 0
                )
                .zIndex(100)
            }
        }
        .overlay {
            if showingQuote, let quote = currentQuote {
                QuoteOverlay(
                    isShowing: $showingQuote,
                    quote: quote
                )
                .zIndex(90)
            }
        }
        .onAppear {
            manager.checkDailyStreaks()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateContent = true
            }
        }
    }
    
    // MARK: - Habit Lists
    
    private var habitLists: some View {
        VStack(spacing: 32) {
            // Good Habits
            let goodHabits = manager.habits.filter { $0.isGoodHabit }
            if !goodHabits.isEmpty {
                VStack(spacing: 16) {
                    sectionHeader(title: "Building Good Habits", icon: "arrow.up.circle.fill", color: .green)
                    
                    ForEach(goodHabits) { habit in
                        HabitCardView(
                            habit: habit,
                            onTap: { handleHabitTap(habit) },
                            onEdit: { editingHabit = habit },
                            onDelete: { withAnimation { manager.deleteHabit(habit) } },
                            onResetProgress: { manager.resetHabitProgress(habit) }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Bad Habits
            let badHabits = manager.habits.filter { !$0.isGoodHabit }
            if !badHabits.isEmpty {
                VStack(spacing: 16) {
                    sectionHeader(title: "Breaking Bad Habits", icon: "arrow.down.circle.fill", color: .red)
                    
                    ForEach(badHabits) { habit in
                        HabitCardView(
                            habit: habit,
                            onTap: { handleHabitTap(habit) },
                            onEdit: { editingHabit = habit },
                            onDelete: { withAnimation { manager.deleteHabit(habit) } },
                            onResetProgress: { manager.resetHabitProgress(habit) }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
                .padding(6)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
        }
    }
    
    private func handleHabitTap(_ habit: Habit) {
        let wasActiveToday = habit.isActiveToday
        
        manager.markHabitCompleted(habit)
        
        // Reload to get updated habit
        if let updatedHabit = manager.habits.first(where: { $0.id == habit.id }) {
            // Show celebration if just completed
            if !wasActiveToday && updatedHabit.isActiveToday {
                selectedHabit = updatedHabit // Update selected habit for overlay
                
                let newStreak = updatedHabit.currentStreak
                
                // Check for milestone
                if let milestoneMessage = MotivationalQuote.getMilestoneMessage(for: newStreak) {
                    celebrationMessage = milestoneMessage
                } else {
                    let quote = MotivationalQuote.getRandomQuote(for: updatedHabit.isGoodHabit)
                    celebrationMessage = quote.text
                }
                
                withAnimation {
                    showingCelebration = true
                }
                
                // Show quote after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    let quote = MotivationalQuote.getRandomQuote(for: updatedHabit.isGoodHabit)
                    currentQuote = quote
                    withAnimation {
                        showingQuote = true
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 24) {
                // Animated heart icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: themeManager.backgroundColors.map { $0.opacity(0.3) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)

                    Image(systemName: "heart.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: themeManager.backgroundColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(animateContent ? 1.05 : 0.95)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateContent)
                }

                VStack(spacing: 12) {
                    Text("Start Your Journey")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Whether you want to build good habits or break bad ones, every step counts.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                VStack(alignment: .leading, spacing: 16) {
                    tipRow(icon: "arrow.up.circle.fill", text: "Start small - one habit at a time", color: .green)
                    tipRow(icon: "arrow.down.circle.fill", text: "Track progress - every day matters", color: .red)
                    tipRow(icon: "flame.fill", text: "Build streaks - consistency is key", color: .orange)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.1), lineWidth: 1))
                )
                .padding(.horizontal, 32)
            }

            Button {
                showingAddHabit = true
            } label: {
                ZStack {
                    // Base theme gradient
                    LinearGradient(
                        colors: themeManager.backgroundColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )

                    // White overlay to brighten
                    LinearGradient(
                        colors: [.white.opacity(0.3), .white.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Button content
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                        Text("Create Your First Habit")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .cornerRadius(20)
                .shadow(color: themeManager.backgroundColors.first?.opacity(0.5) ?? .clear, radius: 15, x: 0, y: 8)
            }
            .padding(.horizontal, 40)
        }
    }
    
    private func tipRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

#Preview {
    HabitView(isMenuShowing: .constant(false))
        .environmentObject(HabitManager())
        .environmentObject(ThemeManager())
}
