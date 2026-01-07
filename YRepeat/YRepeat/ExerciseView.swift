//
//  ExerciseView.swift
//  YRepeat
//
//  Created for Health feature
//

import SwiftUI

struct ExerciseView: View {
    @EnvironmentObject var manager: ExerciseManager
    @State private var animateContent = false

    var body: some View {
        ZStack {
            VStack(spacing: 32) {
            // Circular Progress
            ExerciseCircularProgressView(
                currentMinutes: manager.ellipticalMinutesThisWeek,
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

                if manager.ellipticalMinutesThisWeek == 0 {
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

            // Motivational Popup Overlay
            if manager.motivationalManager.shouldShowMotivationalPopup {
                motivationalPopupView
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(1000)
            }
        }
    }

    // MARK: - Motivational Popup

    private var motivationalPopupView: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        manager.motivationalManager.dismissMotivation()
                    }
                }

            // Popup Card
            VStack(spacing: 24) {
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
                        .frame(width: 80, height: 80)
                        .shadow(color: .orange.opacity(0.4), radius: 20, x: 0, y: 10)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }

                // Message
                Text(manager.motivationalManager.currentMotivationalMessage)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            manager.motivationalManager.dismissMotivation()
                        }

                        // Try to open Fitness app first, then Health app, then Settings
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            // Try Fitness app (iOS 16+)
                            if let fitnessURL = URL(string: "fitness://") {
                                UIApplication.shared.open(fitnessURL) { success in
                                    if !success {
                                        // Fallback to Health app
                                        if let healthURL = URL(string: "x-apple-health://") {
                                            UIApplication.shared.open(healthURL) { healthSuccess in
                                                if !healthSuccess {
                                                    // Final fallback to Settings > Health
                                                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                                                        UIApplication.shared.open(settingsURL)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }) {
                        Text("Let's Go! 🔥")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.green, .green.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                    }

                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            manager.motivationalManager.dismissMotivation()
                        }
                    }) {
                        Text("Maybe Later")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(white: 0.15))
                    .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 15)
            )
            .padding(.horizontal, 40)
        }
    }
}

