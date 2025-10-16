//
//  DailyRepeatView.swift
//  YRepeat
//
//  Created by Dino Pelic on 15. 10. 2025..
//

import SwiftUI

struct DailyRepeatView: View {
    @EnvironmentObject var manager: DailyRepeatManager
    @State private var showingAddItem = false
    @State private var showingTemplates = false
    @State private var selectedItem: DailyRepeatItem?
    @State private var showingCelebration = false
    @State private var completedGoalName = ""
    
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
                
                // Content
                if manager.items.isEmpty {
                    emptyStateView
                } else {
                    contentView
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddDailyRepeatView(manager: manager)
        }
        .sheet(isPresented: $showingTemplates) {
            DailyRepeatTemplatesView(manager: manager)
        }
        .sheet(item: $selectedItem) { item in
            EditDailyRepeatView(manager: manager, item: item)
                .onAppear {
                    print("EditDailyRepeatView appeared for: \(item.name)")
                }
        }
        .overlay {
            if showingCelebration {
                CelebrationOverlay(
                    isShowing: $showingCelebration,
                    goalName: completedGoalName
                )
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "repeat.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Daily Repeat")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                Spacer()
                
                Menu {
                    Button {
                        showingAddItem = true
                    } label: {
                        Label("Create Custom", systemImage: "pencil")
                    }
                    
                    Button {
                        showingTemplates = true
                    } label: {
                        Label("Quick Templates", systemImage: "square.grid.2x2")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                }
            }
            
            // Progress Overview
            if !manager.items.isEmpty {
                progressOverviewView
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Progress Overview
    
    private var progressOverviewView: some View {
        GlassmorphicCard {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.blue)
                    Text("Today's Progress")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                }
                
                HStack(spacing: 20) {
                    // Completion Rate
                    VStack(spacing: 4) {
                        Text("\(manager.completedItemsCount)/\(manager.totalItemsCount)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Completed")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    // Overall Progress
                    VStack(spacing: 4) {
                        Text("\(Int(manager.totalProgress * 100))%")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Overall")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                // Progress Bar
                ProgressView(value: manager.totalProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(y: 2)
            }
        }
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                ForEach(manager.items) { item in
                    DailyRepeatCard(
                        item: item,
                        onTap: {
                            let wasCompleted = item.isCompleted
                            manager.incrementItem(item)
                            
                            // Check if goal was just completed
                            if !wasCompleted && manager.items.first(where: { $0.id == item.id })?.isCompleted == true {
                                completedGoalName = item.name
                                showingCelebration = true
                            }
                        },
                        onEdit: {
                            print("Edit tapped for item: \(item.name) with ID: \(item.id)")
                            selectedItem = item
                        },
                        onDelete: {
                            withAnimation {
                                manager.deleteItem(item)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "repeat.circle.badge.plus")
                    .font(.system(size: 70))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(spacing: 8) {
                    Text("No Daily Goals Yet")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Text("Create your first daily repeat goal\nto start building habits")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
            }
            
            Button {
                showingAddItem = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text("Create Goal")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PremiumButton(color: .blue, isProminent: true))
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

// MARK: - Daily Repeat Card

struct DailyRepeatCard: View {
    let item: DailyRepeatItem
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isPressed = false
    @State private var showingActionSheet = false
    
    var body: some View {
        GlassmorphicCard {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [colorFromString(item.color), colorFromString(item.color).opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: item.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    // Name and Progress
                    HStack {
                        Text(item.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        if item.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                        }
                    }
                    
                    // Progress Text
                    Text(item.progressText)
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                    
                    // Progress Bar
                    ProgressView(value: item.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: colorFromString(item.color)))
                        .scaleEffect(y: 1.5)
                }
                
                // Tap Indicator
                VStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("+\(item.incrementAmount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("TAP")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0.8, maximumDistance: 15, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {
            // Long press detected - show action sheet
            showingActionSheet = true
        })
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text(item.name),
                message: Text("Choose an action"),
                buttons: [
                    .default(Text("Edit Goal")) {
                        onEdit()
                    },
                    .destructive(Text("Delete Goal")) {
                        onDelete()
                    },
                    .cancel()
                ]
            )
        }
    }
    
    private func colorFromString(_ colorName: String) -> Color {
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
}

#Preview {
    DailyRepeatView()
        .environmentObject(DailyRepeatManager())
}
