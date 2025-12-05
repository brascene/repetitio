//
//  HabitView.swift
//  YRepeat
//
//  Created for Habits feature
//

import SwiftUI

struct HabitView: View {
    @EnvironmentObject var manager: HabitManager
    @State private var showingAddHabit = false
    @State private var selectedHabit: Habit?
    @State private var showingCelebration = false
    @State private var celebrationMessage = ""
    @State private var showingQuote = false
    @State private var currentQuote: MotivationalQuote?
    @State private var dailyCheckDone = false
    
    var body: some View {
        ZStack {
            // Premium gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.15, blue: 0.3),
                    Color(red: 0.05, green: 0.1, blue: 0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Motivational Banner
                if !manager.habits.isEmpty {
                    motivationalBanner
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                }
                
                // Content
                if manager.habits.isEmpty {
                    emptyStateView
                } else {
                    contentView
                }
            }
        }
        .sheet(isPresented: $showingAddHabit) {
            AddHabitView(manager: manager)
        }
        .sheet(item: $selectedHabit) { habit in
            EditHabitView(manager: manager, habit: habit)
        }
        .overlay {
            if showingCelebration {
                HabitCelebrationOverlay(
                    isShowing: $showingCelebration,
                    message: celebrationMessage,
                    streak: selectedHabit?.currentStreak ?? 0
                )
            }
        }
        .overlay {
            if showingQuote, let quote = currentQuote {
                QuoteOverlay(
                    isShowing: $showingQuote,
                    quote: quote
                )
            }
        }
        .onAppear {
            manager.checkDailyStreaks()
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Habits")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                Spacer()
                
                Button {
                    showingAddHabit = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.pink)
                }
            }
            
            // Encouragement text
            if !manager.habits.isEmpty {
                Text(encouragementText)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    private var encouragementText: String {
        let activeStreaks = manager.habits.filter { $0.isActiveToday }.count
        let totalStreaks = manager.habits.reduce(0) { $0 + $1.currentStreak }
        
        if activeStreaks == manager.habits.count {
            return "🌟 Amazing! All your habits are active today!"
        } else if totalStreaks > 0 {
            return "💪 You're building something incredible. Keep going!"
        } else {
            return "✨ Every journey begins with a single step. You've got this!"
        }
    }
    
    // MARK: - Motivational Banner
    
    private var motivationalBanner: some View {
        let activeHabits = manager.habits.filter { $0.isActiveToday }.count
        let totalStreaks = manager.habits.reduce(0) { $0 + $1.currentStreak }
        
        return GlassmorphicCard {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today's Progress")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(activeHabits)/\(manager.habits.count)")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.pink, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            Text("Active Today")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Divider()
                            .frame(height: 40)
                            .foregroundColor(.white.opacity(0.3))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(totalStreaks)")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .yellow],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            Text("Total Streak")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 20) {
                // Good Habits Section
                let goodHabits = manager.habits.filter { $0.isGoodHabit }
                if !goodHabits.isEmpty {
                    sectionHeader(title: "Building Good Habits", icon: "arrow.up.circle.fill", color: .green)
                    
                    ForEach(goodHabits) { habit in
                        HabitCard(
                            habit: habit,
                            onTap: {
                                handleHabitTap(habit)
                            },
                            onEdit: {
                                selectedHabit = habit
                            },
                            onDelete: {
                                manager.deleteHabit(habit)
                            }
                        )
                    }
                }
                
                // Bad Habits Section
                let badHabits = manager.habits.filter { !$0.isGoodHabit }
                if !badHabits.isEmpty {
                    sectionHeader(title: "Breaking Bad Habits", icon: "arrow.down.circle.fill", color: .red)
                    
                    ForEach(badHabits) { habit in
                        HabitCard(
                            habit: habit,
                            onTap: {
                                handleHabitTap(habit)
                            },
                            onEdit: {
                                selectedHabit = habit
                            },
                            onDelete: {
                                manager.deleteHabit(habit)
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.top, 8)
    }
    
    private func handleHabitTap(_ habit: Habit) {
        let wasActiveToday = habit.isActiveToday
        
        manager.markHabitCompleted(habit)
        
        // Reload to get updated habit
        if let updatedHabit = manager.habits.first(where: { $0.id == habit.id }) {
            // Show celebration if just completed
            if !wasActiveToday && updatedHabit.isActiveToday {
                let newStreak = updatedHabit.currentStreak
                
                // Check for milestone
                if let milestoneMessage = MotivationalQuote.getMilestoneMessage(for: newStreak) {
                    celebrationMessage = milestoneMessage
                } else {
                    let quote = MotivationalQuote.getRandomQuote(for: updatedHabit.isGoodHabit)
                    celebrationMessage = quote.text
                }
                
                showingCelebration = true
                
                // Show quote after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    let quote = MotivationalQuote.getRandomQuote(for: updatedHabit.isGoodHabit)
                    currentQuote = quote
                    showingQuote = true
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                // Animated heart icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.pink.opacity(0.3), .purple.opacity(0.2)],
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
                                colors: [.pink, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(spacing: 12) {
                    Text("Start Your Journey")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Whether you want to build good habits or break bad ones, every step counts. You're capable of amazing things! 💪")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 40)
                }
                
                VStack(spacing: 16) {
                    Text("💡 Tips:")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 8)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        tipRow(icon: "arrow.up.circle.fill", text: "Start small - one habit at a time", color: .green)
                        tipRow(icon: "arrow.down.circle.fill", text: "Track your progress - every day matters", color: .red)
                        tipRow(icon: "flame.fill", text: "Build streaks - consistency is key", color: .orange)
                        tipRow(icon: "heart.fill", text: "Be kind to yourself - progress over perfection", color: .pink)
                    }
                    .padding(.horizontal, 40)
                }
            }
            
            Button {
                showingAddHabit = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                    Text("Create Your First Habit")
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(PremiumButton(color: .pink, isProminent: true))
            .padding(.horizontal, 40)
            
            Spacer()
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

// MARK: - Habit Card

struct HabitCard: View {
    let habit: Habit
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isPressed = false
    
    private func emojiForIcon(_ iconName: String) -> String {
        let iconMap: [String: String] = [
            "star.fill": "⭐", "heart.fill": "❤️", "flame.fill": "🔥", "leaf.fill": "🍃", "book.fill": "📚",
            "dumbbell.fill": "🏋️", "moon.fill": "🌙", "sun.max.fill": "☀️", "drop.fill": "💧", "bolt.fill": "⚡",
            "figure.walk": "🚶", "figure.run": "🏃", "figure.yoga": "🧘", "figure.strengthtraining.traditional": "💪",
            "cup.and.saucer.fill": "☕", "fork.knife": "🍴", "wineglass.fill": "🍷", "mug.fill": "☕",
            "apple.fill": "🍎", "banana.fill": "🍌", "pizza.fill": "🍕", "fish.fill": "🐟",
            "car.fill": "🚗", "airplane": "✈️", "bicycle": "🚲", "house.fill": "🏠",
            "bed.double.fill": "🛏️", "pills.fill": "💊", "music.note": "🎵", "camera.fill": "📷",
            "gamecontroller.fill": "🎮", "tv.fill": "📺", "bell.fill": "🔔", "clock.fill": "🕐",
            "checkmark.circle.fill": "✅", "trophy.fill": "🏆", "crown.fill": "👑"
        ]
        return iconMap[iconName] ?? "⭐"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
                        .frame(width: 70, height: 70)
                        .shadow(color: colorFromString(habit.color).opacity(0.4), radius: 10, x: 0, y: 5)
                    
                    Group {
                        if UIImage(systemName: habit.iconName) != nil {
                            Image(systemName: habit.iconName)
                                .font(.system(size: 32, weight: .semibold))
                        } else {
                            Text(emojiForIcon(habit.iconName))
                                .font(.system(size: 28))
                        }
                    }
                    .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    // Habit Name
                    HStack {
                        Text(habit.name)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Status indicator
                        if habit.isActiveToday {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.green)
                        }
                    }
                    
                    // Status text
                    Text(statusText)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                    
                    // Streak info
                    HStack(spacing: 16) {
                        streakBadge(title: "Current", value: habit.currentStreak, color: .orange)
                        streakBadge(title: "Best", value: habit.longestStreak, color: .blue)
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
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(20)
            .background(
                ZStack {
                    // Base glass effect
                    VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)
                    
                    // Gradient overlay based on status
                    LinearGradient(
                        colors: habit.isActiveToday
                            ? [
                                colorFromString(habit.color).opacity(0.25),
                                colorFromString(habit.color).opacity(0.15)
                            ]
                            : [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            
            // Action Button
            Button {
                onTap()
            } label: {
                HStack {
                    Spacer()
                    
                    if habit.isActiveToday {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                            Text("Completed Today!")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.green)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: habit.isGoodHabit ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                .font(.system(size: 18))
                            Text(habit.isGoodHabit ? "Mark as Done" : "Mark as Resisted")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.9)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 16)
                .background(
                    ZStack {
                        if habit.isActiveToday {
                            Color.green.opacity(0.2)
                        } else {
                            LinearGradient(
                                colors: [
                                    colorFromString(habit.color).opacity(0.3),
                                    colorFromString(habit.color).opacity(0.2)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        }
                    }
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(habit.isActiveToday)
        }
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(habit.isActiveToday ? 0.4 : 0.2),
                            Color.white.opacity(habit.isActiveToday ? 0.2 : 0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: habit.isActiveToday ? 2 : 1.5
                )
        )
        .shadow(
            color: habit.isActiveToday 
                ? colorFromString(habit.color).opacity(0.3)
                : Color.black.opacity(0.2),
            radius: habit.isActiveToday ? 15 : 10,
            x: 0,
            y: habit.isActiveToday ? 8 : 5
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }
    
    private var statusText: String {
        if habit.isActiveToday {
            return "✅ Completed today!"
        } else if habit.currentStreak > 0 {
            return "🔥 \(habit.currentStreak) day streak - keep it going!"
        } else if habit.daysSinceLastCompletion == 1 {
            return "💔 Streak broken yesterday - start fresh today!"
        } else {
            return habit.isGoodHabit 
                ? "✨ Ready to start your journey"
                : "💪 Ready to resist today"
        }
    }
    
    private func streakBadge(title: String, value: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, color.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.08)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func colorFromString(_ colorName: String) -> Color {
        // Check if it's a hex color
        if colorName.hasPrefix("#") {
            return hexStringToColor(colorName) ?? .blue
        }
        
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
        default: return .blue
        }
    }
    
    private func hexStringToColor(_ hex: String) -> Color? {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        return Color(red: r, green: g, blue: b)
    }
}

// MARK: - Shared Icon Data

struct HabitIcons {
    static let all: [(sfSymbol: String, emoji: String)] = [
        // Basic & Common
        ("star.fill", "⭐"), ("heart.fill", "❤️"), ("flame.fill", "🔥"), ("leaf.fill", "🍃"), ("book.fill", "📚"),
        ("dumbbell.fill", "🏋️"), ("moon.fill", "🌙"), ("sun.max.fill", "☀️"), ("drop.fill", "💧"), ("bolt.fill", "⚡"),
        
        // Activities & Fitness
        ("figure.walk", "🚶"), ("figure.run", "🏃"), ("figure.yoga", "🧘"), ("figure.strengthtraining.traditional", "💪"),
        ("figure.dance", "💃"), ("figure.skiing.downhill", "⛷️"), ("figure.surfing", "🏄"), ("figure.climbing", "🧗"),
        ("sportscourt.fill", "🏟️"), ("basketball.fill", "🏀"), ("soccerball", "⚽"), ("football.fill", "🏈"),
        ("tennis.racket", "🎾"), ("figure.swimming", "🏊"), ("bicycle", "🚴"), ("figure.cycling", "🚴"),
        ("figure.archery", "🏹"), ("figure.boxing", "🥊"), ("figure.golf", "⛳"), ("figure.hiking", "🥾"),
        ("figure.hunting", "🎯"), ("figure.jumprope", "🦘"), ("figure.pilates", "🧘"), ("figure.rowing", "🚣"),
        
        // Food & Drink
        ("cup.and.saucer.fill", "☕"), ("fork.knife", "🍴"), ("wineglass.fill", "🍷"), ("mug.fill", "☕"),
        ("takeoutbag.and.cup.and.straw.fill", "🥤"), ("birthday.cake.fill", "🎂"), ("carrot.fill", "🥕"),
        ("apple.fill", "🍎"), ("banana.fill", "🍌"), ("orange.fill", "🍊"), ("strawberry.fill", "🍓"),
        ("fish.fill", "🐟"), ("pizza.fill", "🍕"), ("tray.fill", "🍽️"), ("takeoutbag.fill", "🥡"),
        ("bowl.fill", "🥣"), ("spoon.fill", "🥄"), ("fork.fill", "🍴"), ("knife.fill", "🔪"),
        ("waterbottle.fill", "💧"), ("popcorn.fill", "🍿"), ("icecream.fill", "🍦"), ("lollipop", "🍭"),
        ("candybar.fill", "🍫"), ("gift.fill", "🎁"), ("party.popper.fill", "🎉"),
        
        // Transportation
        ("car.fill", "🚗"), ("airplane", "✈️"), ("tram.fill", "🚊"), ("bus.fill", "🚌"),
        ("bicycle", "🚲"), ("fuelpump.fill", "⛽"), ("car.2.fill", "🚙"), ("sailboat.fill", "⛵"),
        
        // Home & Daily Life
        ("house.fill", "🏠"), ("bed.double.fill", "🛏️"), ("shower.fill", "🚿"), ("toothbrush.fill", "🪥"),
        ("pills.fill", "💊"), ("cross.case.fill", "➕"), ("bandage.fill", "🩹"), ("stethoscope", "🩺"),
        
        // Health & Wellness
        ("brain.head.profile", "🧠"), ("eye.fill", "👁️"), ("ear.fill", "👂"), ("hand.raised.fill", "✋"),
        ("hand.thumbsup.fill", "👍"), ("heart.text.square.fill", "💚"), ("lungs.fill", "🫁"),
        
        // Creative & Entertainment
        ("music.note", "🎵"), ("guitars.fill", "🎸"), ("paintbrush.fill", "🖌️"), ("camera.fill", "📷"),
        ("photo.fill", "📸"), ("film.fill", "🎬"), ("gamecontroller.fill", "🎮"), ("tv.fill", "📺"),
        ("laptopcomputer", "💻"), ("iphone", "📱"), ("ipad", "📱"),
        
        // Learning & Work
        ("pencil", "✏️"), ("pencil.tip", "✏️"), ("highlighter", "🖍️"), ("bookmark.fill", "🔖"),
        ("tag.fill", "🏷️"), ("graduationcap.fill", "🎓"), ("briefcase.fill", "💼"),
        
        // Time & Reminders
        ("bell.fill", "🔔"), ("alarm.fill", "⏰"), ("clock.fill", "🕐"), ("timer", "⏱️"),
        ("calendar", "📅"), ("clock.badge.checkmark.fill", "✅"),
        
        // Status & Actions
        ("checkmark.circle.fill", "✅"), ("xmark.circle.fill", "❌"), ("plus.circle.fill", "➕"),
        ("minus.circle.fill", "➖"), ("questionmark.circle.fill", "❓"), ("exclamationmark.triangle.fill", "⚠️"),
        ("info.circle.fill", "ℹ️"), ("star.circle.fill", "⭐"), ("heart.circle.fill", "❤️"), ("flame.circle.fill", "🔥"),
        
        // Nature & Weather
        ("leaf.circle.fill", "🍃"), ("bolt.circle.fill", "⚡"), ("drop.circle.fill", "💧"),
        ("sun.circle.fill", "☀️"), ("moon.circle.fill", "🌙"), ("cloud.fill", "☁️"), ("cloud.rain.fill", "🌧️"),
        ("snowflake", "❄️"), ("tornado", "🌪️"), ("hurricane", "🌀"), ("tree.fill", "🌳"), ("flower.fill", "🌸"),
        
        // Animals
        ("pawprint.fill", "🐾"), ("fish.fill", "🐟"), ("bird.fill", "🐦"), ("tortoise.fill", "🐢"),
        ("ladybug.fill", "🐞"), ("ant.fill", "🐜"), ("butterfly.fill", "🦋"),
        
        // Achievement & Status
        ("crown.fill", "👑"), ("trophy.fill", "🏆"), ("medal.fill", "🥇"), ("rosette", "🏵️"),
        ("seal.fill", "🔰"), ("shield.fill", "🛡️"), ("star.square.fill", "⭐"), ("heart.square.fill", "❤️")
    ]
}

// MARK: - Add Habit View

struct AddHabitView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var manager: HabitManager
    @State private var habitName = ""
    @State private var isGoodHabit = true
    @State private var selectedIcon = "star.fill"
    @State private var selectedIconEmoji = "⭐"
    @State private var selectedColor = "blue"
    @State private var customColor: Color = .blue
    @State private var showingColorPicker = false
    
    var icons: [(sfSymbol: String, emoji: String)] {
        return HabitIcons.all
    }
    
    let colors = ["blue", "green", "purple", "orange", "red", "pink", "yellow", "mint", "cyan", "indigo"]
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.15),
                        Color(red: 0.1, green: 0.15, blue: 0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Habit Type Selector
                        VStack(spacing: 16) {
                            Text("What kind of habit?")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 16) {
                                habitTypeButton(
                                    title: "Start",
                                    subtitle: "Building a good habit",
                                    icon: "arrow.up.circle.fill",
                                    color: .green,
                                    isSelected: isGoodHabit
                                ) {
                                    isGoodHabit = true
                                    hideKeyboard()
                                }
                                
                                habitTypeButton(
                                    title: "Stop",
                                    subtitle: "Breaking a bad habit",
                                    icon: "arrow.down.circle.fill",
                                    color: .red,
                                    isSelected: !isGoodHabit
                                ) {
                                    isGoodHabit = false
                                    hideKeyboard()
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // Name Input
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Habit Name")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            
                            TextField("e.g., Exercise daily", text: $habitName)
                                .textFieldStyle(.plain)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.15))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                )
                                .foregroundColor(.white)
                                .autocapitalization(.sentences)
                                .submitLabel(.done)
                                .onSubmit {
                                    hideKeyboard()
                                }
                        }
                        .padding(.horizontal, 20)
                        
                        // Icon Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Choose an Icon")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(alignment: .top, spacing: 12) {
                                    ForEach(0..<(icons.count + 4) / 5, id: \.self) { columnIndex in
                                        VStack(spacing: 8) {
                                            ForEach(0..<5, id: \.self) { rowIndex in
                                                let iconIndex = columnIndex * 5 + rowIndex
                                                if iconIndex < icons.count {
                                                    iconButton(iconData: icons[iconIndex])
                                                } else {
                                                    Color.clear
                                                        .frame(width: 50, height: 50)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 4)
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Color Selection
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Choose a Color")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button {
                                    showingColorPicker.toggle()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "eyedropper.full")
                                            .font(.system(size: 14))
                                        Text("Custom")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.15))
                                    )
                                }
                            }
                            
                            if showingColorPicker {
                                ColorPicker("", selection: $customColor, supportsOpacity: false)
                                    .labelsHidden()
                                    .frame(height: 50)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.1))
                                    )
                                    .onChange(of: customColor) { _, newColor in
                                        selectedColor = colorToHexString(newColor)
                                        hideKeyboard()
                                    }
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(colors, id: \.self) { color in
                                        colorButton(color: color)
                                    }
                                }
                                .padding(.horizontal, 4)
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Create Button
                        Button {
                            hideKeyboard()
                            if !habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                manager.addHabit(
                                    name: habitName.trimmingCharacters(in: .whitespacesAndNewlines),
                                    isGoodHabit: isGoodHabit,
                                    iconName: selectedIcon,
                                    color: selectedColor
                                )
                                dismiss()
                            }
                        } label: {
                            Text("Create Habit")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PremiumButton(color: isGoodHabit ? .green : .red, isProminent: true))
                        .disabled(habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
                .onTapGesture {
                    hideKeyboard()
                }
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        hideKeyboard()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func habitTypeButton(title: String, subtitle: String, icon: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(isSelected ? .white : color.opacity(0.6))
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        isSelected
                            ? LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? Color.white.opacity(0.4) : Color.white.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
    }
    
    private func iconButton(iconData: (sfSymbol: String, emoji: String)) -> some View {
        Button {
            selectedIcon = iconData.sfSymbol
            selectedIconEmoji = iconData.emoji
            hideKeyboard()
        } label: {
            Group {
                if UIImage(systemName: iconData.sfSymbol) != nil {
                    Image(systemName: iconData.sfSymbol)
                        .font(.system(size: 24))
                } else {
                    Text(iconData.emoji)
                        .font(.system(size: 24))
                }
            }
            .foregroundColor(selectedIcon == iconData.sfSymbol ? .white : .white.opacity(0.7))
            .frame(width: 50, height: 50)
            .background(
                Circle()
                    .fill(selectedIcon == iconData.sfSymbol ? Color.pink.opacity(0.4) : Color.white.opacity(0.1))
            )
            .overlay(
                Circle()
                    .stroke(selectedIcon == iconData.sfSymbol ? Color.pink : Color.white.opacity(0.2), lineWidth: selectedIcon == iconData.sfSymbol ? 2 : 1)
            )
        }
    }
    
    private func colorButton(color: String) -> some View {
        Button {
            selectedColor = color
            showingColorPicker = false
            hideKeyboard()
        } label: {
            Circle()
                .fill(colorFromString(color))
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                )
                .shadow(color: selectedColor == color ? colorFromString(color).opacity(0.6) : .clear, radius: 8)
        }
    }
    
    private func emojiForIcon(_ iconName: String) -> String {
        return icons.first(where: { $0.sfSymbol == iconName })?.emoji ?? "⭐"
    }
    
    private func colorFromString(_ colorName: String) -> Color {
        // Check if it's a hex color
        if colorName.hasPrefix("#") {
            return hexStringToColor(colorName) ?? .blue
        }
        
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
        default: return .blue
        }
    }
    
    private func colorToHexString(_ color: Color) -> String {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
    
    private func hexStringToColor(_ hex: String) -> Color? {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        return Color(red: r, green: g, blue: b)
    }
}

// MARK: - Edit Habit View

struct EditHabitView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var manager: HabitManager
    let habit: Habit
    
    @State private var habitName: String
    @State private var selectedIcon: String
    @State private var selectedIconEmoji: String
    @State private var selectedColor: String
    @State private var customColor: Color = .blue
    @State private var showingColorPicker = false
    
    var icons: [(sfSymbol: String, emoji: String)] {
        return HabitIcons.all
    }
    
    let colors = ["blue", "green", "purple", "orange", "red", "pink", "yellow", "mint", "cyan", "indigo"]
    
    init(manager: HabitManager, habit: Habit) {
        self.manager = manager
        self.habit = habit
        _habitName = State(initialValue: habit.name)
        _selectedIcon = State(initialValue: habit.iconName)
        _selectedColor = State(initialValue: habit.color)
        
        // Find emoji for the icon
        let iconEmoji = HabitIcons.all.first(where: { $0.sfSymbol == habit.iconName })?.emoji ?? "⭐"
        _selectedIconEmoji = State(initialValue: iconEmoji)
        
        // Initialize customColor from stored color
        _customColor = State(initialValue: Self.initialColorFromString(habit.color))
    }
    
    private static func initialColorFromString(_ colorName: String) -> Color {
        // Check if it's a hex color
        if colorName.hasPrefix("#") {
            return hexStringToColorStatic(colorName) ?? .blue
        }
        
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
        default: return .blue
        }
    }
    
    private static func hexStringToColorStatic(_ hex: String) -> Color? {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        return Color(red: r, green: g, blue: b)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.15),
                        Color(red: 0.1, green: 0.15, blue: 0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Name Input
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Habit Name")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            
                            TextField("Habit name", text: $habitName)
                                .textFieldStyle(.plain)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.15))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                )
                                .foregroundColor(.white)
                                .submitLabel(.done)
                                .onSubmit {
                                    hideKeyboard()
                                }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // Icon Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Choose an Icon")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(alignment: .top, spacing: 12) {
                                    ForEach(0..<(icons.count + 4) / 5, id: \.self) { columnIndex in
                                        VStack(spacing: 8) {
                                            ForEach(0..<5, id: \.self) { rowIndex in
                                                let iconIndex = columnIndex * 5 + rowIndex
                                                if iconIndex < icons.count {
                                                    iconButton(iconData: icons[iconIndex])
                                                } else {
                                                    Color.clear
                                                        .frame(width: 50, height: 50)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 4)
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Color Selection
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Choose a Color")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button {
                                    showingColorPicker.toggle()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "eyedropper.full")
                                            .font(.system(size: 14))
                                        Text("Custom")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.15))
                                    )
                                }
                            }
                            
                            if showingColorPicker {
                                ColorPicker("", selection: $customColor, supportsOpacity: false)
                                    .labelsHidden()
                                    .frame(height: 50)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.1))
                                    )
                                    .onChange(of: customColor) { _, newColor in
                                        selectedColor = colorToHexString(newColor)
                                        hideKeyboard()
                                    }
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(colors, id: \.self) { color in
                                        colorButton(color: color)
                                    }
                                }
                                .padding(.horizontal, 4)
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Save Button
                        Button {
                            hideKeyboard()
                            if !habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                manager.updateHabit(
                                    habit: habit,
                                    name: habitName.trimmingCharacters(in: .whitespacesAndNewlines),
                                    iconName: selectedIcon,
                                    color: selectedColor
                                )
                                dismiss()
                            }
                        } label: {
                            Text("Save Changes")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PremiumButton(color: .pink, isProminent: true))
                        .disabled(habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
                .onTapGesture {
                    hideKeyboard()
                }
            }
            .navigationTitle("Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        hideKeyboard()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func iconButton(iconData: (sfSymbol: String, emoji: String)) -> some View {
        Button {
            selectedIcon = iconData.sfSymbol
            selectedIconEmoji = iconData.emoji
            hideKeyboard()
        } label: {
            Group {
                if UIImage(systemName: iconData.sfSymbol) != nil {
                    Image(systemName: iconData.sfSymbol)
                        .font(.system(size: 24))
                } else {
                    Text(iconData.emoji)
                        .font(.system(size: 24))
                }
            }
            .foregroundColor(selectedIcon == iconData.sfSymbol ? .white : .white.opacity(0.7))
            .frame(width: 50, height: 50)
            .background(
                Circle()
                    .fill(selectedIcon == iconData.sfSymbol ? Color.pink.opacity(0.4) : Color.white.opacity(0.1))
            )
            .overlay(
                Circle()
                    .stroke(selectedIcon == iconData.sfSymbol ? Color.pink : Color.white.opacity(0.2), lineWidth: selectedIcon == iconData.sfSymbol ? 2 : 1)
            )
        }
    }
    
    private func colorButton(color: String) -> some View {
        Button {
            selectedColor = color
            showingColorPicker = false
            hideKeyboard()
        } label: {
            Circle()
                .fill(colorFromString(color))
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                )
                .shadow(color: selectedColor == color ? colorFromString(color).opacity(0.6) : .clear, radius: 8)
        }
    }
    
    private func emojiForIcon(_ iconName: String) -> String {
        return icons.first(where: { $0.sfSymbol == iconName })?.emoji ?? "⭐"
    }
    
    private func colorFromString(_ colorName: String) -> Color {
        // Check if it's a hex color
        if colorName.hasPrefix("#") {
            return hexStringToColor(colorName) ?? .blue
        }
        
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
        default: return .blue
        }
    }
    
    private func colorToHexString(_ color: Color) -> String {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
    
    private func hexStringToColor(_ hex: String) -> Color? {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        return Color(red: r, green: g, blue: b)
    }
}

// MARK: - Celebration Overlay

struct HabitCelebrationOverlay: View {
    @Binding var isShowing: Bool
    let message: String
    let streak: Int
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    isShowing = false
                }
            
            VStack(spacing: 24) {
                // Celebration Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.pink.opacity(0.3), .purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .blur(radius: 30)
                    
                    Image(systemName: streak >= 7 ? "trophy.fill" : streak >= 3 ? "flame.fill" : "star.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(spacing: 12) {
                    Text("🎉 Amazing!")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(message)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    if streak > 1 {
                        Text("🔥 \(streak) day streak!")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .yellow],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }
            }
            .padding(40)
            .background(
                ZStack {
                    VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)
                    LinearGradient(
                        colors: [.pink.opacity(0.2), .purple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .cornerRadius(30)
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(40)
        }
        .transition(.opacity.combined(with: .scale))
    }
}

// MARK: - Quote Overlay

struct QuoteOverlay: View {
    @Binding var isShowing: Bool
    let quote: MotivationalQuote
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    isShowing = false
                }
            
            VStack(spacing: 20) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(quote.text)
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 40)
                
                if let author = quote.author {
                    Text("— \(author)")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .italic()
                }
                
                Button {
                    isShowing = false
                } label: {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PremiumButton(color: .pink, isProminent: true))
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }
            .padding(40)
            .background(
                ZStack {
                    VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)
                    LinearGradient(
                        colors: [.blue.opacity(0.2), .purple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .cornerRadius(30)
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(40)
        }
        .transition(.opacity.combined(with: .scale))
    }
}

#Preview {
    HabitView()
        .environmentObject(HabitManager())
}

