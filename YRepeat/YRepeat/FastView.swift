//
//  FastView.swift
//  YRepeat
//
//  Created for Fasting feature
//

import SwiftUI

struct FastView: View {
    var embedded: Bool = false
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var manager = FastManager()
    @State private var showingStartFast = false
    @State private var showingDeleteConfirmation = false
    @State private var showingDeleteAllConfirmation = false
    @State private var fastToDelete: Fast?
    @State private var selectedFastType: FastType = .sixteenEight
    @State private var customHours: Int = 16
    @State private var showingHistory = false
    
    // Animation state
    @State private var animateContent = false
    
    var body: some View {
        ZStack {
            // Premium gradient background - only if not embedded
            if !embedded {
                LiquidBackgroundView()
            }
            
            VStack(spacing: 0) {
                // Header - only if not embedded
                if !embedded {
                    FastHeaderView()
                        .zIndex(1)
                }
                
                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // History Button (CTA)
                        HStack {
                            Spacer()
                            Button(action: {
                                showingHistory = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("History")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(20)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        if let fast = manager.activeFast {
                            activeFastView(fast: fast)
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                                .id("\(fast.id.uuidString)-\(fast.startTime.timeIntervalSince1970)")
                        } else {
                            emptyStateView
                                .transition(.opacity)
                                .padding(.top, 40)
                        }
                    }
                    .padding(.bottom, 100)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .sheet(isPresented: $showingStartFast) {
            startFastSheet
        }
        .sheet(isPresented: $showingHistory) {
            FastHistoryView(manager: manager)
        }
        .alert("End Fast", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("End Fast", role: .destructive) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    manager.stopFast()
                }
            }
        } message: {
            Text("Are you sure you want to end this fast?")
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
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateContent = true
            }
        }
    }
    
    // MARK: - Active Fast View
    
    private func activeFastView(fast: Fast) -> some View {
        VStack(spacing: 32) {
            // Circular Progress
            FastCircularProgressView(fast: fast)
            
            // Phase Card
            fastingPhaseCard(fast: fast)
            
            // Stats
            FastStatsView(fast: fast, manager: manager)
                .padding(.horizontal, 20)
            
            // Action Button
            Button(action: {
                showingDeleteConfirmation = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 20))
                    Text("End Fast")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.red.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(20)
                .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Fasting Phase Card
    
    private func fastingPhaseCard(fast: Fast) -> some View {
        let phase = fast.currentPhase
        let nextPhase = getNextPhase(current: phase)
        
        return VStack(spacing: 16) {
            // Current Phase Header
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(phase.color.opacity(0.2))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: phase.icon)
                        .font(.system(size: 28))
                        .foregroundColor(phase.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(phase.rawValue)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(phase.description)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }
                
                Spacer()
            }
            
            // Phase Progress
            if let nextPhase = nextPhase {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Next: \(nextPhase.rawValue)")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Spacer()
                        
                        Text("\(Int(fast.phaseProgress * 100))%")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 6)
                            
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [phase.color, nextPhase.color],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * fast.phaseProgress, height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
            
            // Motivation
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundColor(.yellow)
                
                Text(phase.motivationalMessage)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [
                            phase.color.opacity(0.3),
                            phase.color.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .padding(.horizontal, 20)
    }
    
    private func getNextPhase(current: FastingPhase) -> FastingPhase? {
        let allPhases = FastingPhase.allCases
        guard let currentIndex = allPhases.firstIndex(of: current),
              currentIndex < allPhases.count - 1 else {
            return nil
        }
        return allPhases[currentIndex + 1]
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 24) {
                // Animated Icon
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

                    Image(systemName: "moon.stars.fill")
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
                    Text("Start Your Fast")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Track your fasting journey and visualize your progress.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            
            Button {
                showingStartFast = true
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
                        Image(systemName: "play.fill")
                            .font(.system(size: 20))
                        Text("Begin Fast")
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
    
    // MARK: - Start Fast Sheet
    
    private var startFastSheet: some View {
        NavigationView {
            ZStack {
                LiquidBackgroundView()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Fast Types Grid
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                            ForEach(FastType.allCases.filter { $0 != .custom }, id: \.self) { type in
                                Button {
                                    selectedFastType = type
                                    manager.startFast(type: type)
                                    showingStartFast = false
                                } label: {
                                    VStack(spacing: 12) {
                                        Text(type.displayName)
                                            .font(.system(size: 24, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        
                                        Text("\(type.hours) Hours")
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 24)
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
                        }
                        .padding(.horizontal, 20)
                        
                        // Custom Duration Section
                        VStack(spacing: 16) {
                            Text("Custom Duration")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 20) {
                                HStack {
                                    Text("\(customHours) Hours")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                
                                Slider(value: Binding(
                                    get: { Double(customHours) },
                                    set: { customHours = Int($0) }
                                ), in: 1...168, step: 1)
                                .tint(themeManager.backgroundColors.first ?? .purple)
                                
                                Button {
                                    manager.startFast(type: .custom, customHours: customHours)
                                    showingStartFast = false
                                } label: {
                                    Text("Start Custom Fast")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.white.opacity(0.1))
                                        .foregroundColor(.white)
                                        .cornerRadius(16)
                                }
                            }
                            .padding(24)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(.ultraThinMaterial)
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle("Start Fast")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingStartFast = false
                    }
                }
            }
        }
    }
}

#Preview {
    FastView()
        .environmentObject(ThemeManager())
}
