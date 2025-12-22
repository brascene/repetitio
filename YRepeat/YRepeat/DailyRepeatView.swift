//
//  DailyRepeatView.swift
//  YRepeat
//
//  Created by Dino Pelic on 15. 10. 2025..
//

import SwiftUI

enum DailySegment: String, CaseIterable {
    case daily = "Daily"
    case history = "History"
}

struct DailyRepeatView: View {
    @EnvironmentObject var manager: DailyRepeatManager
    @State private var showingAddItem = false
    @State private var showingTemplates = false
    @State private var selectedItem: DailyRepeatItem?
    @State private var showingCelebration = false
    @State private var completedGoalName = ""
    @State private var showingResetConfirmation = false
    @State private var selectedSegment: DailySegment = .daily
    @State private var showingClearHistoryAlert = false
    
    var body: some View {
        ZStack {
            // New Liquid Background
            LiquidBackgroundView()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Custom Segmented Control
                ModernSegmentedControl(selectedSegment: $selectedSegment)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                
                // Content based on selected segment
                if selectedSegment == .daily {
                    if manager.items.isEmpty {
                        emptyStateView
                    } else {
                        contentView
                    }
                } else {
                    tasksHistoryContentView
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
        .onAppear {
            // Check for new day when view appears (additional safeguard)
            manager.checkForNewDay()
        }
        .alert("Reset All Progress", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                withAnimation {
                    manager.resetAllProgress()
                }
            }
        } message: {
            Text("Are you sure you want to reset all daily repeat progress to zero? This action cannot be undone.")
        }
        .alert("Clear All History", isPresented: $showingClearHistoryAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                withAnimation {
                    manager.clearTaskHistory()
                }
            }
        } message: {
            Text("Are you sure you want to delete all \(manager.taskHistory.count) completed tasks?")
        }
    }
    
    // MARK: - Tasks History Content
    
    private var tasksHistoryContentView: some View {
        TasksHistoryContent(
            dailyRepeatManager: manager,
            onRestartTask: restartTaskFromHistory
        )
    }
    
    private func restartTaskFromHistory(_ historyItem: TaskHistoryItem) {
        // Restart the task from history
        manager.restartTaskFromHistory(historyItem)
        
        // Switch to daily segment
        selectedSegment = .daily
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Daily Repeat")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.9)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                Spacer()
                
                if selectedSegment == .daily {
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
                        
                        if !manager.items.isEmpty {
                            Divider()
                            
                            Button(role: .destructive) {
                                showingResetConfirmation = true
                            } label: {
                                Label("Reset All Progress", systemImage: "arrow.counterclockwise")
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.blue))
                            .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                } else {
                    if !manager.taskHistory.isEmpty {
                        Button {
                            showingClearHistoryAlert = true
                        } label: {
                            Image(systemName: "trash.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            
            // Progress Overview
            if !manager.items.isEmpty {
                ModernProgressOverviewCard(manager: manager)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                ForEach(manager.items) { item in
                    ModernDailyCard(
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
                        onDecrement: {
                            manager.decrementItem(item)
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

#Preview {
    DailyRepeatView()
        .environmentObject(DailyRepeatManager())
}
