//
//  ExerciseCircularProgressView.swift
//  YRepeat
//
//  Created for Health feature
//

import SwiftUI

struct ExerciseCircularProgressView: View {
    let currentMinutes: Double
    let goalMinutes: Double
    
    private var progress: Double {
        guard goalMinutes > 0 else { return 0 }
        return min(currentMinutes / goalMinutes, 1.0)
    }
    
    private var percentage: Int {
        guard goalMinutes > 0 else { return 0 }
        return Int((currentMinutes / goalMinutes) * 100)
    }
    
    // Green gradient for exercise
    private let progressColors: [Color] = [.green, .mint]
    
    var body: some View {
        ZStack {
            // Outer glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            progressColors[0].opacity(0.2),
                            progressColors[1].opacity(0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 100,
                        endRadius: 180
                    )
                )
                .frame(width: 340, height: 340)
                .blur(radius: 30)
            
            // Background circle with glass effect
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 280, height: 280)
                
                // Progress ring background
                Circle()
                    .stroke(
                        Color.white.opacity(0.1),
                        style: StrokeStyle(lineWidth: 24, lineCap: .round)
                    )
                    .frame(width: 260, height: 260)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: progressColors + [progressColors[0]],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 24, lineCap: .round)
                    )
                    .frame(width: 260, height: 260)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: progressColors[0].opacity(0.5), radius: 10, x: 0, y: 0)
                    .animation(.linear(duration: 0.5), value: progress)
                
                // Inner content
                VStack(spacing: 8) {
                    Text("\(Int(currentMinutes))")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .minimumScaleFactor(0.5)
                        .padding(.horizontal)
                        .animation(.linear(duration: 0.5), value: currentMinutes)

                    Text("MINUTES")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(2)
                    
                    Text("THIS WEEK")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.bottom, 4)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "figure.elliptical")
                            .font(.system(size: 12))
                        Text("\(percentage)%")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(progressColors[0])
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(progressColors[0].opacity(0.15))
                    )
                    .animation(.linear(duration: 0.5), value: percentage)
                }
            }
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .frame(width: 280, height: 280)
            )
        }
        .padding(.vertical, 20)
    }
}

