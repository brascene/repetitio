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
                        manager.refreshData()
                    }) {
                        Text("Refresh Health Data")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.green)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text("Check Permissions in Settings")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.3))
                            .underline()
                    }
                    .padding(.top, 4)
                    
                    // Secret/Debug Re-auth button if things are really broken
                    Button(action: {
                        manager.forceAuthorization()
                    }) {
                        Text("Force Authorization Request")
                            .font(.system(size: 10))
                            .foregroundColor(.red.opacity(0.5))
                            .padding(.top, 8)
                    }
                }
            }
            .padding(.top, 8)
            .opacity(animateContent ? 1 : 0)
        }
        .onAppear {
            manager.refreshData()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateContent = true
            }
        }
    }
}

