//
//  ExerciseView.swift
//  YRepeat
//
//  Created for Health feature
//

import SwiftUI

struct ExerciseView: View {
    @EnvironmentObject var manager: ExerciseManager
    @StateObject private var weightliftingManager: WeightliftingManager
    @State private var animateContent = false
    @State private var editingSession: WeightliftingSession?
    @State private var showBodyPartsEditor = false
    @State private var showWeightEditor = false
    @State private var weightInput: String = ""

    init() {
        _weightliftingManager = StateObject(wrappedValue: WeightliftingManager())
    }

    var body: some View {
        ZStack {
            VStack(spacing: 32) {
            // Circular Progress
            ExerciseCircularProgressView(
                currentMinutes: manager.totalCardioMinutesThisWeek,
                goalMinutes: manager.weeklyGoalMinutes
            )
            .scaleEffect(animateContent ? 1 : 0.9)
            .opacity(animateContent ? 1 : 0)
            
            // Goal Input
            GlassmorphicCard {
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(.green)
                            .font(.system(size: 20))

                        Text("Weekly Goal")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)

                        Spacer()

                        // Always-visible refresh button
                        Button(action: {
                            manager.refreshData()
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.green)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Color.green.opacity(0.15)))
                        }
                    }

                    HStack(spacing: 12) {
                        Text("\(Int(manager.weeklyGoalMinutes)) min")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Spacer()

                        Button(action: {
                            if manager.weeklyGoalMinutes > 10 {
                                manager.weeklyGoalMinutes -= 10
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.3))
                        }

                        Button(action: {
                            manager.weeklyGoalMinutes += 10
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(4)
            }
            .padding(.horizontal, 20)
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 20)
            
            // Notification Settings
            GlassmorphicCard {
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 18))

                    Text("Motivational Reminders")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { manager.motivationalManager.notificationsEnabled },
                        set: { newValue in
                            manager.motivationalManager.notificationsEnabled = newValue
                            if newValue {
                                manager.motivationalManager.requestNotificationPermissions()
                            }
                        }
                    ))
                    .labelsHidden()
                    .tint(.orange)
                }
                .padding(16)
            }
            .padding(.horizontal, 20)
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 20)

            // Weightlifting Section
            weightliftingSection

            // Body Weight Section
            bodyWeightSection

            // Info Text
            VStack(spacing: 8) {
                Text("Data synchronized with Health app")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))

                // Debug Status (Detailed)
                Text(manager.statusMessage)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .fixedSize(horizontal: false, vertical: true)

                if manager.totalCardioMinutesThisWeek == 0 {
                    Button(action: {
                        // Try to open Settings > Health
                        // Note: This may not work on all iOS versions as Apple restricts deep linking to Settings
                        if let url = URL(string: "App-Prefs:Privacy&path=HEALTH") {
                            UIApplication.shared.open(url) { success in
                                if !success {
                                    // Fallback: Open general Settings if the Health URL doesn't work
                                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(settingsUrl)
                                    }
                                }
                            }
                        }
                    }) {
                        VStack(spacing: 4) {
                            Text("Open Health Permissions")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.3))
                                .underline()
                            Text("Settings > Health > Data Access & Devices > YRepeat")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.2))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 40)
            .opacity(animateContent ? 1 : 0)
            }
            .onAppear {
                manager.refreshData()
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animateContent = true
                }
            }

        }
        .sheet(isPresented: Binding(
            get: { manager.motivationalManager.shouldShowMotivationalPopup },
            set: { manager.motivationalManager.shouldShowMotivationalPopup = $0 }
        )) {
            motivationalSheet
        }
    }

    // MARK: - Motivational Sheet

    private var motivationalSheet: some View {
        ZStack {
            // Background
            LiquidBackgroundView()

            VStack(spacing: 32) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: .orange.opacity(0.4), radius: 20, x: 0, y: 10)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }

                // Message
                Text(manager.motivationalManager.currentMotivationalMessage)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                // Action Button
                Button(action: {
                    manager.motivationalManager.dismissMotivation()
                }) {
                    Text("Let's Crush It! 💪")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [.green, .green.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Weightlifting Section

    private var weightliftingSection: some View {
        GlassmorphicCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "dumbbell.fill")
                        .foregroundColor(.purple)
                        .font(.system(size: 18))

                    Text("Weightlifting This Week")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    if weightliftingManager.totalMinutesThisWeek > 0 {
                        Text("\(Int(weightliftingManager.totalMinutesThisWeek)) min")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.purple)
                    }
                }

                if weightliftingManager.sessionsThisWeek.isEmpty {
                    Text("No weightlifting sessions this week")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 12) {
                        ForEach(weightliftingManager.sessionsThisWeek) { session in
                            weightliftingRow(session: session)
                        }
                    }
                }
            }
            .padding(16)
        }
        .padding(.horizontal, 20)
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .sheet(isPresented: $showBodyPartsEditor) {
            if let session = editingSession {
                bodyPartsEditorSheet(session: session)
            }
        }
    }

    // MARK: - Body Weight Section

    private var bodyWeightSection: some View {
        GlassmorphicCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "scalemass.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 18))

                    Text("Body Weight")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    if manager.currentWeight > 0 {
                        Text("\(String(format: "%.1f", manager.currentWeight)) kg")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                    }
                }

                if manager.currentWeight == 0 {
                    Text("No weight logged yet")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                }

                Button(action: {
                    weightInput = manager.currentWeight > 0 ? String(format: "%.1f", manager.currentWeight) : ""
                    showWeightEditor = true
                }) {
                    HStack {
                        Image(systemName: manager.todayWeightLogged ? "checkmark.circle.fill" : "plus.circle.fill")
                            .foregroundColor(manager.todayWeightLogged ? .green : .blue)

                        Text(manager.todayWeightLogged ? "Update Today's Weight" : "Log Today's Weight")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.2))
                    )
                }
            }
            .padding(16)
        }
        .padding(.horizontal, 20)
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .sheet(isPresented: $showWeightEditor) {
            weightEditorSheet
        }
        .onAppear {
            manager.loadTodayWeight()
        }
    }

    private var weightEditorSheet: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.1, green: 0.05, blue: 0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("Log Your Weight")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 20)

                    VStack(spacing: 12) {
                        HStack {
                            TextField("Weight", text: $weightInput)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.1))
                                )

                            Text("kg")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal)

                        Text("Enter your current weight in kilograms")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Button(action: {
                        if let weight = Double(weightInput), weight > 0 {
                            manager.saveWeight(weight)
                            showWeightEditor = false

                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        }
                    }) {
                        Text("Save Weight")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    .disabled(weightInput.isEmpty || Double(weightInput) == nil || Double(weightInput)! <= 0)
                    .opacity((weightInput.isEmpty || Double(weightInput) == nil || Double(weightInput)! <= 0) ? 0.5 : 1.0)

                    Spacer()
                }
            }
            .navigationBarItems(trailing: Button("Cancel") {
                showWeightEditor = false
            })
        }
    }

    private func weightliftingRow(session: WeightliftingSession) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.sessionDate, style: .date)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white)

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                    Text("\(Int(session.durationMinutes)) min")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }

                if !session.bodyPartsWorked.isEmpty {
                    Text(session.bodyPartsWorked.joined(separator: ", "))
                        .font(.system(size: 12))
                        .foregroundColor(.purple.opacity(0.8))
                }
            }

            Spacer()

            Button(action: {
                editingSession = session
                // Small delay to ensure state is set before sheet opens
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    showBodyPartsEditor = true
                }
            }) {
                Text("Edit")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.purple)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.15))
                    .cornerRadius(8)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private func bodyPartsEditorSheet(session: WeightliftingSession) -> some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.1, green: 0.05, blue: 0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("Select Body Parts Worked")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(availableBodyParts, id: \.self) { bodyPart in
                            BodyPartButton(
                                bodyPart: bodyPart,
                                isSelected: session.bodyPartsWorked.contains(bodyPart),
                                onTap: {
                                    var updatedParts = session.bodyPartsWorked
                                    if let index = updatedParts.firstIndex(of: bodyPart) {
                                        updatedParts.remove(at: index)
                                    } else {
                                        updatedParts.append(bodyPart)
                                    }
                                    weightliftingManager.updateBodyParts(sessionId: session.id, bodyParts: updatedParts)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationBarItems(trailing: Button("Done") {
                showBodyPartsEditor = false
                editingSession = nil
            })
        }
    }
}

struct BodyPartButton: View {
    let bodyPart: String
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    private var emoji: String {
        switch bodyPart {
        case "Chest": return "💪"
        case "Back": return "🏋️"
        case "Shoulders": return "👐"
        case "Arms": return "💪"
        case "Legs": return "🦵"
        case "Core": return "🔥"
        case "Full Body": return "🏆"
        default: return "⭐️"
        }
    }

    var body: some View {
        Button(action: {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

            // Visual feedback
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }

            onTap()
        }) {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: isPressed ? 40 : 36))

                Text(bodyPart)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.purple.opacity(0.4) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.purple : Color.white.opacity(0.2), lineWidth: isSelected ? 3 : 1)
                    )
            )
            .shadow(
                color: isSelected ? Color.purple.opacity(0.5) : Color.clear,
                radius: isSelected ? 8 : 0,
                x: 0,
                y: isSelected ? 4 : 0
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

