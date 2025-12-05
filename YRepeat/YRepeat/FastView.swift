//
//  FastView.swift
//  YRepeat
//
//  Created for Fasting feature
//

import SwiftUI

enum FastSegment: String, CaseIterable {
    case current = "Current"
    case history = "History"
}

struct FastView: View {
    @StateObject private var manager = FastManager()
    @State private var showingStartFast = false
    @State private var showingDeleteConfirmation = false
    @State private var showingDeleteAllConfirmation = false
    @State private var fastToDelete: Fast?
    @State private var selectedFastType: FastType = .sixteenEight
    @State private var customHours: Int = 16
    @State private var selectedSegment: FastSegment = .current
    
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
                
                // Segmented Control
                segmentedControlView
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                
                // Main Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        if selectedSegment == .current {
                            if let fast = manager.activeFast {
                                // Active Fast View
                                activeFastView(fast: fast)
                            } else {
                                // No Active Fast View
                                emptyStateView
                            }
                        } else {
                            // History View
                            historyView
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showingStartFast) {
            startFastSheet
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
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 32))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Fast")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Segmented Control
    
    private var segmentedControlView: some View {
        Picker("Segment", selection: $selectedSegment) {
            ForEach(FastSegment.allCases, id: \.self) { segment in
                Text(segment.rawValue).tag(segment)
            }
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - Active Fast View
    
    private func activeFastView(fast: Fast) -> some View {
        VStack(spacing: 32) {
            // Circular Progress Indicator
            circularProgressView(fast: fast)
            
            // Fasting Phase Indicator
            fastingPhaseCard(fast: fast)
            
            // Fast Info Cards
            VStack(spacing: 16) {
                fastInfoCard(
                    title: "Elapsed",
                    value: formatTime(fast.elapsedHours),
                    icon: "clock.fill",
                    color: .blue
                )
                
                fastInfoCard(
                    title: "Remaining",
                    value: formatTime(fast.remainingHours),
                    icon: "hourglass.bottomhalf.filled",
                    color: .purple
                )
                
                fastInfoCard(
                    title: "Goal",
                    value: formatTime(Double(fast.goalHours)),
                    icon: "target",
                    color: .green
                )
            }
            
            // Action Buttons
            HStack(spacing: 16) {
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "stop.circle.fill")
                        Text("End Fast")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PremiumButton(color: .red, isProminent: true))
            }
        }
    }
    
    // MARK: - Fasting Phase Card
    
    private func fastingPhaseCard(fast: Fast) -> some View {
        let phase = fast.currentPhase
        let nextPhase = getNextPhase(current: phase)
        
        return GlassmorphicCard {
            VStack(spacing: 16) {
                // Current Phase
                HStack(spacing: 12) {
                    Image(systemName: phase.icon)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [phase.color, phase.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(phase.rawValue)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(phase.description)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
                
                // Motivational Message
                HStack {
                    Text(phase.motivationalMessage)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [phase.color, phase.color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Spacer()
                }
                .padding(.top, 4)
                
                // Phase Progress Bar
                if let nextPhase = nextPhase {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Progress to \(nextPhase.rawValue)")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Spacer()
                            
                            Text("\(Int(fast.phaseProgress * 100))%")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 8)
                                
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [phase.color, nextPhase.color],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * fast.phaseProgress, height: 8)
                                    .animation(.linear(duration: 0.3), value: fast.phaseProgress)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.top, 8)
                }
            }
        }
    }
    
    private func getNextPhase(current: FastingPhase) -> FastingPhase? {
        let allPhases = FastingPhase.allCases
        guard let currentIndex = allPhases.firstIndex(of: current),
              currentIndex < allPhases.count - 1 else {
            return nil
        }
        return allPhases[currentIndex + 1]
    }
    
    // MARK: - History View
    
    private var historyView: some View {
        VStack(spacing: 20) {
            if manager.fastHistory.isEmpty {
                emptyHistoryView
            } else {
                // History Header with Delete All
                HStack {
                    Text("Fast History")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        showingDeleteAllConfirmation = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                            Text("Delete All")
                        }
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.2))
                        )
                    }
                }
                .padding(.horizontal, 4)
                
                // History List
                LazyVStack(spacing: 12) {
                    ForEach(manager.fastHistory) { fast in
                        fastHistoryCard(fast: fast)
                    }
                }
            }
        }
    }
    
    private var emptyHistoryView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.5))
            
            Text("No Fast History")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Completed fasts will appear here")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    private func fastHistoryCard(fast: Fast) -> some View {
        GlassmorphicCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(fast.fastType.displayName)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(formatDate(fast.startTime))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        VStack(alignment: .trailing, spacing: 6) {
                            Text(formatTime(fast.durationHours))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            if fast.isCompleted {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                    Text("Completed")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(.green)
                            } else {
                                Text("Incomplete")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        // Delete button inline
                        Button(action: {
                            fastToDelete = fast
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.red)
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(Color.red.opacity(0.2))
                                )
                        }
                    }
                }
                
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * fast.progress, height: 6)
                    }
                }
                .frame(height: 6)
                
                // Goal info
                HStack {
                    Text("Goal: \(formatTime(Double(fast.goalHours)))")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                    
                    if let endTime = fast.endTime {
                        Text("Ended: \(formatDate(endTime))")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
    }
    
    // MARK: - Circular Progress View
    
    private func circularProgressView(fast: Fast) -> some View {
        ZStack {
            // Outer glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.purple.opacity(0.3),
                            Color.blue.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 100,
                        endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .blur(radius: 30)
            
            // Background circle with glass effect
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 280, height: 280)
                
                // Progress ring background
                Circle()
                    .stroke(
                        Color.white.opacity(0.1),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 260, height: 260)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: fast.progress)
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color.purple,
                                Color.blue,
                                Color.cyan,
                                Color.purple
                            ],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 260, height: 260)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Color.purple.opacity(0.5), radius: 15, x: 0, y: 0)
                    .animation(.linear(duration: 0.3), value: fast.progress)
                
                // Inner content
                VStack(spacing: 8) {
                    Text(formatTime(fast.elapsedHours))
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    Text("hours")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(Int(fast.progress * 100))%")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 4)
                }
            }
            .background(
                VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)
                    .clipShape(Circle())
            )
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 280, height: 280)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 30, x: 0, y: 15)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Fast Info Card
    
    private func fastInfoCard(title: String, value: String, icon: String, color: Color) -> some View {
        GlassmorphicCard {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(value)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 32) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.purple.opacity(0.2),
                                Color.blue.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .blur(radius: 20)
                
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.top, 40)
            
            VStack(spacing: 12) {
                Text("Start Your Fast")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Track your fasting journey with beautiful progress visualization")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: {
                showingStartFast = true
            }) {
                HStack {
                    Image(systemName: "play.circle.fill")
                    Text("Start Fast")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PremiumButton(color: .purple, isProminent: true))
            .padding(.horizontal, 40)
            .padding(.top, 20)
        }
    }
    
    // MARK: - Start Fast Sheet
    
    private var startFastSheet: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.15),
                        Color(red: 0.1, green: 0.15, blue: 0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Fast Type Selection
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Fast Type")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(FastType.allCases.filter { $0 != .custom }, id: \.self) { type in
                                    fastTypeButton(type: type)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Custom Hours
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Custom Duration")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            GlassmorphicCard {
                                VStack(spacing: 16) {
                                    HStack {
                                        Text("Hours")
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Text("\(customHours)")
                                            .font(.system(size: 24, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                    }
                                    
                                    Slider(value: Binding(
                                        get: { Double(customHours) },
                                        set: { customHours = Int($0) }
                                    ), in: 1...168, step: 1)
                                    .tint(.purple)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    manager.startFast(type: .custom, customHours: customHours)
                                    showingStartFast = false
                                }
                            }) {
                                HStack {
                                    Image(systemName: "play.circle.fill")
                                    Text("Start Custom Fast")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PremiumButton(color: .purple, isProminent: true))
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Start Fast")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingStartFast = false
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private func fastTypeButton(type: FastType) -> some View {
        Button(action: {
            selectedFastType = type
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                manager.startFast(type: type)
                showingStartFast = false
            }
        }) {
            VStack(spacing: 8) {
                Text(type.displayName)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("\(type.hours) hours")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
        .buttonStyle(PremiumButton(color: .purple))
    }
    
    // MARK: - Helper Functions
    
    private func formatTime(_ hours: Double) -> String {
        let totalMinutes = Int(hours * 60)
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        
        if h > 0 && m > 0 {
            return "\(h)h \(m)m"
        } else if h > 0 {
            return "\(h)h"
        } else {
            return "\(m)m"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    FastView()
}

