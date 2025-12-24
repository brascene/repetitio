//
//  FastCircularProgressView.swift
//  YRepeat
//
//  Created for Fasting feature
//

import SwiftUI

struct FastCircularProgressView: View {
    let fast: Fast
    
    private var progressColor: [Color] {
        switch fast.currentPhase {
        case .fed, .earlyFasting:
            return [.blue, .cyan]
        case .ketosisBegins, .fullKetosis:
            return [.orange, .red]
        case .autophagyBegins, .deepAutophagy:
            return [.purple, .pink]
        case .growthHormonePeak:
            return [.yellow, .orange]
        }
    }
    
    var body: some View {
        ZStack {
            // Outer glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            progressColor[0].opacity(0.2),
                            progressColor[1].opacity(0.05),
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
                    .trim(from: 0, to: fast.progress)
                    .stroke(
                        AngularGradient(
                            colors: progressColor + [progressColor[0]],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 24, lineCap: .round)
                    )
                    .frame(width: 260, height: 260)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: progressColor[0].opacity(0.5), radius: 10, x: 0, y: 0)
                    .animation(.linear(duration: 0.5), value: fast.progress)
                
                // Inner content
                VStack(spacing: 8) {
                    Text(formatTime(fast.elapsedHours))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .minimumScaleFactor(0.5)
                        .padding(.horizontal)
                        .animation(.linear(duration: 0.5), value: fast.elapsedHours)

                    Text("ELAPSED")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(2)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 12))
                        Text("\(Int(fast.progress * 100))%")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .animation(.linear(duration: 0.5), value: fast.progress)
                    }
                    .foregroundColor(progressColor[0])
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(progressColor[0].opacity(0.15))
                    )
                    .padding(.top, 4)
                    .animation(.linear(duration: 0.5), value: fast.progress)
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
    
    private func formatTime(_ hours: Double) -> String {
        let totalMinutes = Int(hours * 60)
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        return String(format: "%02d:%02d", h, m)
    }
}

