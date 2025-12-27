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
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var isMenuShowing: Bool
    @State private var showingAddItem = false
    @State private var showingTemplates = false
    @State private var selectedItem: DailyRepeatItem?
    @State private var showingCelebration = false
    @State private var completedGoalName = ""
    @State private var showingResetConfirmation = false
    @State private var selectedSegment: DailySegment = .daily
    @State private var showingClearHistoryAlert = false
    @State private var itemToDelete: DailyRepeatItem?
    @State private var showingDeleteConfirmation = false
    
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
        .alert("Delete Goal", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let item = itemToDelete {
                    withAnimation {
                        manager.deleteItem(item)
                    }
                    itemToDelete = nil
                }
            }
        } message: {
            if let item = itemToDelete {
                Text("Are you sure you want to delete '\(item.name)'? This action cannot be undone.")
            }
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
                MenuButton(isMenuShowing: $isMenuShowing)

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
        List {
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
                        itemToDelete = item
                        showingDeleteConfirmation = true
                    }
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        itemToDelete = item
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    Button {
                        manager.decrementItem(item)
                    } label: {
                        Label("Decrement", systemImage: "minus.circle")
                    }
                    .tint(.orange)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
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
                            colors: themeManager.backgroundColors.map { $0.opacity(0.6) },
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
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                        Text("Create Goal")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .cornerRadius(20)
                .shadow(color: themeManager.backgroundColors.first?.opacity(0.5) ?? .clear, radius: 15, x: 0, y: 8)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }
    
}

#Preview {
    DailyRepeatView(isMenuShowing: .constant(false))
        .environmentObject(DailyRepeatManager())
        .environmentObject(ThemeManager())
}
