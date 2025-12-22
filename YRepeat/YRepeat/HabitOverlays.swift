//
//  HabitOverlays.swift
//  YRepeat
//
//  Created for Habits feature
//

import SwiftUI

struct HabitCelebrationOverlay: View {
    @Binding var isShowing: Bool
    let message: String
    let streak: Int
    
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        isShowing = false
                    }
                }
            
            VStack(spacing: 24) {
                // Celebration Icon with Animation
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.pink.opacity(0.3), .purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .blur(radius: 30)
                    
                    Image(systemName: streak >= 7 ? "trophy.fill" : streak >= 3 ? "flame.fill" : "star.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(animate ? 1.1 : 0.9)
                        .rotationEffect(.degrees(animate ? 5 : -5))
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animate)
                }
                
                VStack(spacing: 12) {
                    Text("🎉 Amazing!")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(message)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    if streak > 1 {
                        Text("🔥 \(streak) day streak!")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .yellow],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .padding(.top, 8)
                    }
                }
            }
            .padding(40)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(.ultraThinMaterial)
                    
                    LinearGradient(
                        colors: [.pink.opacity(0.1), .purple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .mask(RoundedRectangle(cornerRadius: 30))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.5), .white.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(40)
            .scaleEffect(animate ? 1.0 : 0.8)
            .opacity(animate ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    animate = true
                }
            }
        }
    }
}

struct QuoteOverlay: View {
    @Binding var isShowing: Bool
    let quote: MotivationalQuote
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        isShowing = false
                    }
                }
            
            VStack(spacing: 20) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(quote.text)
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 20)
                
                if let author = quote.author {
                    Text("— \(author)")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .italic()
                }
                
                Button {
                    withAnimation {
                        isShowing = false
                    }
                } label: {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pink)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .padding(.top, 10)
            }
            .padding(32)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(.ultraThinMaterial)
                    
                    LinearGradient(
                        colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .mask(RoundedRectangle(cornerRadius: 30))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(32)
        }
        .transition(.opacity.combined(with: .scale))
    }
}

