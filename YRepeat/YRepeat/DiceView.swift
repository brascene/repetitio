//
//  DiceView.swift
//  YRepeat
//
//  Created for Dice rolling feature
//

import SwiftUI

struct DiceView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var isMenuShowing: Bool
    @State private var diceNumber = 1
    @State private var isRolling = false
    @State private var rotationX: Double = 0
    @State private var rotationY: Double = 0
    @State private var rotationZ: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var numberOfDice = 1
    @State private var diceResults: [Int] = [1]
    @State private var rollHistory: [RollResult] = []
    @State private var bounceOffset: CGFloat = 0
    @State private var showControls = false

    var body: some View {
        ZStack {
            // Theme-aware background
            LinearGradient(
                colors: themeManager.backgroundColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .zIndex(10)

                // Dice Count Selector
                if showControls {
                    diceCountSelector
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(5)
                }

                // Dice Display
                diceDisplayArea
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if !showControls {
                            rollDice()
                        }
                    }
                    // If controls are shown, maybe tapping outside closes them?
                    // Or just let user tap dice to roll.
                    // User said "pressing anywhere on the new dice view"
            }
            .padding(.bottom, 20)
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                MenuButton(isMenuShowing: $isMenuShowing)

                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: themeManager.backgroundColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 44, height: 44)
                            .shadow(color: themeManager.backgroundColors.first?.opacity(0.3) ?? .clear, radius: 8, x: 0, y: 4)

                        Image(systemName: "die.face.5.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Text("Dice")
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

                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showControls.toggle()
                    }
                }) {
                    Image(systemName: showControls ? "chevron.up" : "slider.horizontal.3")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                        )
                }
            }
        }
    }

    // MARK: - Dice Count Selector

    private var diceCountSelector: some View {
        GlassmorphicCard {
            HStack(spacing: 12) {
                ForEach(1...3, id: \.self) { count in
                    Button(action: {
                        guard !isRolling else { return }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            numberOfDice = count
                            diceResults = Array(repeating: 1, count: count)
                        }
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }) {
                        HStack(spacing: 4) {
                            ForEach(0..<count, id: \.self) { _ in
                                Image(systemName: "die.face.1.fill")
                                    .font(.system(size: count == 1 ? 28 : (count == 2 ? 22 : 18)))
                                    .foregroundColor(numberOfDice == count ? .white : .white.opacity(0.4))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            numberOfDice == count
                                ? LinearGradient(colors: themeManager.backgroundColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color.white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .cornerRadius(12)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(12)
        }
    }

    // MARK: - Dice Display Area

    private var diceDisplayArea: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 40) {
                // Result Summary - only show for multiple dice
                if numberOfDice > 1 && diceResults.reduce(0, +) > 0 {
                    VStack(spacing: 8) {
                        Text("Total: \(diceResults.reduce(0, +))")
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)

                        Text(diceResults.map { String($0) }.joined(separator: " + "))
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                // Dice Display
                if numberOfDice == 1 {
                    singleDiceView(number: diceResults[0])
                } else {
                    HStack(spacing: 20) {
                        ForEach(Array(diceResults.enumerated()), id: \.offset) { index, number in
                            multipleDiceView(number: number, index: index)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            if !showControls {
                rollDice()
            }
        }
    }

    // MARK: - Single Dice View

    private func singleDiceView(number: Int) -> some View {
        Image(systemName: "die.face.\(number)")
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(width: 250, height: 250)
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 15)
            .rotation3DEffect(
                .degrees(rotationX),
                axis: (x: 1, y: 0, z: 0)
            )
            .rotation3DEffect(
                .degrees(rotationY),
                axis: (x: 0, y: 1, z: 0)
            )
            .rotation3DEffect(
                .degrees(rotationZ),
                axis: (x: 0, y: 0, z: 1)
            )
            .scaleEffect(scale)
            .offset(y: bounceOffset)
    }

    // MARK: - Multiple Dice View

    private func multipleDiceView(number: Int, index: Int) -> some View {
        Image(systemName: "die.face.\(number)")
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(width: numberOfDice == 2 ? 160 : 120, height: numberOfDice == 2 ? 160 : 120)
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            .rotation3DEffect(
                .degrees(isRolling ? rotationX + Double(index * 120) : 0),
                axis: (x: 1, y: 0, z: 0)
            )
            .rotation3DEffect(
                .degrees(isRolling ? rotationY + Double(index * 180) : 0),
                axis: (x: 0, y: 1, z: 0)
            )
            .scaleEffect(scale)
    }

    // MARK: - Roll Dice Function

    private func rollDice() {
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        isRolling = true

        // Start animations
        withAnimation(.easeInOut(duration: 0.1).repeatCount(8, autoreverses: true)) {
            scale = 1.1
        }

        withAnimation(.linear(duration: 0.8)) {
            rotationX = 720
            rotationY = 1080
            rotationZ = 360
        }

        // Simulate multiple random changes during roll
        var rollCount = 0
        let rollInterval = 0.1

        Timer.scheduledTimer(withTimeInterval: rollInterval, repeats: true) { timer in
            rollCount += 1

            // Change dice numbers randomly during animation
            diceResults = (0..<numberOfDice).map { _ in Int.random(in: 1...6) }

            if rollCount >= 8 {
                timer.invalidate()

                // Final result with bounce
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Final roll
                    diceResults = (0..<numberOfDice).map { _ in Int.random(in: 1...6) }

                    // Add to history
                    let result = RollResult(
                        values: diceResults,
                        total: diceResults.reduce(0, +),
                        timestamp: Date()
                    )
                    rollHistory.append(result)
                    if rollHistory.count > 20 {
                        rollHistory.removeFirst()
                    }

                    // Bounce effect
                    withAnimation(.interpolatingSpring(stiffness: 200, damping: 10)) {
                        bounceOffset = -30
                    }

                    withAnimation(.interpolatingSpring(stiffness: 200, damping: 10).delay(0.2)) {
                        bounceOffset = 0
                    }

                    // Reset animations
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        rotationX = 0
                        rotationY = 0
                        rotationZ = 0
                        scale = 1.0
                        isRolling = false
                    }

                    // Final haptic
                    let finalGenerator = UINotificationFeedbackGenerator()
                    finalGenerator.notificationOccurred(.success)
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func timeAgo(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 {
            return "now"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes)m ago"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return "\(hours)h ago"
        } else {
            let days = seconds / 86400
            return "\(days)d ago"
        }
    }
}

// MARK: - Roll Result Model

struct RollResult: Identifiable {
    let id = UUID()
    let values: [Int]
    let total: Int
    let timestamp: Date
}

#Preview {
    DiceView(isMenuShowing: .constant(false))
        .environmentObject(ThemeManager())
}
