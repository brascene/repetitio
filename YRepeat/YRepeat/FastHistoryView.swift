//
//  FastHistoryView.swift
//  YRepeat
//
//  Created for Fasting feature
//

import SwiftUI

struct FastHistoryView: View {
    @ObservedObject var manager: FastManager
    @Environment(\.dismiss) var dismiss
    @State private var fastToDelete: Fast?
    @State private var showingDeleteAllConfirmation = false
    
    var body: some View {
        ZStack {
            LiquidBackgroundView()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                    
                    Text("History")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if !manager.fastHistory.isEmpty {
                        Button(action: {
                            showingDeleteAllConfirmation = true
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 20))
                                .foregroundColor(.red.opacity(0.8))
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(Color.white.opacity(0.1)))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 20)
                
                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        if manager.fastHistory.isEmpty {
                            emptyHistoryView
                                .padding(.top, 100)
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(manager.fastHistory) { fast in
                                    FastHistoryRowView(
                                        fast: fast,
                                        onDelete: {
                                            fastToDelete = fast
                                        }
                                    )
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .alert("Delete Fast", isPresented: Binding(
            get: { fastToDelete != nil },
            set: { if !$0 { fastToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let fast = fastToDelete {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        manager.deleteFast(fast)
                    }
                }
                fastToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this fast? This action cannot be undone.")
        }
        .alert("Delete All Fasts", isPresented: $showingDeleteAllConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    manager.deleteAllFasts()
                }
            }
        } message: {
            Text("Are you sure you want to delete all fasts? This action cannot be undone.")
        }
    }
    
    private var emptyHistoryView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Text("No History Yet")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Your completed fasts will appear here.")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

