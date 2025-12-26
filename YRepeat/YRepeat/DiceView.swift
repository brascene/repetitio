//
//  DiceView.swift
//  YRepeat
//
//  Created for Dice rolling feature
//

import SwiftUI

struct DiceView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var diceNumber = 1
    @State private var isRolling = false
    @State private var rotationX: Double = 0
    @State private var rotationY: Double = 0
    @State private var rotationZ: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var numberOfDice = 1
    @State private var diceResults: [Int] = [1]
    @State private var rollHistory: [RollResult] = []
    @State private var showHistory = false
    @State private var bounceOffset: CGFloat = 0

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

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Dice Count Selector
                        diceCountSelector

                        // Dice Display
                        diceDisplayArea

                        // Roll Button
                        rollButton

                        // History Section
                        if !rollHistory.isEmpty {
                            historySection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 44, height: 44)
                            .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)

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

                if !rollHistory.isEmpty {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showHistory.toggle()
                        }
                    }) {
                        Image(systemName: showHistory ? "clock.fill" : "clock")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
        }
    }

    // MARK: - Dice Count Selector

    private var diceCountSelector: some View {
        GlassmorphicCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Number of Dice")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                HStack(spacing: 12) {
                    ForEach(1...3, id: \.self) { count in
                        Button(action: {
                            guard !isRolling else { return }
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                numberOfDice = count
                                diceResults = Array(repeating: 1, count: count)
                            }
                            // Haptic feedback
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }) {
                            VStack(spacing: 8) {
                                HStack(spacing: 4) {
                                    ForEach(0..<count, id: \.self) { _ in
                                        Image(systemName: "die.face.1.fill")
                                            .font(.system(size: count == 1 ? 24 : (count == 2 ? 18 : 14)))
                                            .foregroundColor(numberOfDice == count ? .white : .white.opacity(0.4))
                                    }
                                }

                                Text("\(count) \(count == 1 ? "Die" : "Dice")")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(numberOfDice == count ? .white : .white.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 70)
                            .background(
                                numberOfDice == count
                                    ? LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                      )
                                    : LinearGradient(
                                        colors: [Color.white.opacity(0.1), Color.white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                      )
                            )
                            .cornerRadius(16)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
            }
            .padding(20)
        }
    }

    // MARK: - Dice Display Area

    private var diceDisplayArea: some View {
        GlassmorphicCard {
            VStack(spacing: 24) {
                // Result Summary
                if diceResults.reduce(0, +) > 0 {
                    VStack(spacing: 8) {
                        Text("Total: \(diceResults.reduce(0, +))")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        if numberOfDice > 1 {
                            Text(diceResults.map { String($0) }.joined(separator: " + "))
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.top, 20)
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
            .padding(20)
            .frame(minHeight: 300)
        }
    }

    // MARK: - Single Dice View

    private func singleDiceView(number: Int) -> some View {
        Image(systemName: "die.face.\(number).fill")
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(width: 180, height: 180)
            .foregroundStyle(
                LinearGradient(
                    colors: [.orange, .red],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: .orange.opacity(0.5), radius: 20, x: 0, y: 10)
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
        Image(systemName: "die.face.\(number).fill")
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(width: numberOfDice == 2 ? 120 : 90, height: numberOfDice == 2 ? 120 : 90)
            .foregroundStyle(
                LinearGradient(
                    colors: [.orange, .red],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: .orange.opacity(0.4), radius: 15, x: 0, y: 8)
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

    // MARK: - Roll Button

    private var rollButton: some View {
        Button(action: rollDice) {
            HStack(spacing: 12) {
                Image(systemName: isRolling ? "arrow.triangle.2.circlepath" : "play.fill")
                    .font(.system(size: 20, weight: .bold))

                Text(isRolling ? "Rolling..." : "Roll \(numberOfDice == 1 ? "Dice" : "All Dice")!")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(
                LinearGradient(
                    colors: isRolling ? [.gray, .gray.opacity(0.8)] : [.orange, .red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
            .shadow(color: isRolling ? .clear : .orange.opacity(0.5), radius: 20, x: 0, y: 10)
        }
        .disabled(isRolling)
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - History Section

    private var historySection: some View {
        GlassmorphicCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.orange)

                    Text("Recent Rolls")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            rollHistory.removeAll()
                        }
                    }) {
                        Text("Clear")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                    }
                }

                if showHistory {
                    Divider()
                        .background(Color.white.opacity(0.2))

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 8) {
                            ForEach(rollHistory.reversed()) { result in
                                HStack {
                                    HStack(spacing: 4) {
                                        ForEach(result.values, id: \.self) { value in
                                            Image(systemName: "die.face.\(value).fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(.orange)
                                        }
                                    }

                                    if result.values.count > 1 {
                                        Text(result.values.map { String($0) }.joined(separator: " + "))
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.6))
                                    }

                                    Spacer()

                                    Text("\(result.total)")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)

                                    Text(timeAgo(from: result.timestamp))
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                }
            }
            .padding(20)
        }
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
    DiceView()
        .environmentObject(ThemeManager())
}
