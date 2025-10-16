//
//  CelebrationOverlay.swift
//  YRepeat
//
//  Created by Dino Pelic on 15. 10. 2025..
//

import SwiftUI
import Lottie

struct CelebrationOverlay: View {
    @Binding var isShowing: Bool
    let goalName: String
    
    @State private var selectedMessage: String = ""
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    private let congratulationsMessages = [
        "🎉 Congratulations! Goal completed!",
        "🏆 Amazing work! You did it!",
        "✨ Fantastic! Goal achieved!",
        "🎊 Well done! You're unstoppable!",
        "🌟 Incredible! You nailed it!",
        "🔥 Outstanding! Goal conquered!",
        "💪 Excellent! You're on fire!",
        "🎯 Perfect! Mission accomplished!",
        "🚀 Brilliant! You're crushing it!",
        "⭐ Superb! Goal mastered!",
        "🎈 Awesome! You're a champion!",
        "💎 Magnificent! Goal completed!",
        "🌈 Wonderful! You're amazing!",
        "🎪 Spectacular! Well executed!",
        "🎭 Bravo! Goal achieved with style!"
    ]
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissCelebration()
                }
            
            // Celebration content
            VStack(spacing: 24) {
                // Lottie Trophy Animation
                LottieView(animation: .named("Trophy.json"))
                    .looping()
                    .frame(width: 200, height: 200)
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                // Congratulatory message
                VStack(spacing: 12) {
                    Text(selectedMessage)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .opacity(opacity)
                    
                    Text("\(goalName) completed!")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .opacity(opacity)
                }
                
                // Continue button
                Button {
                    dismissCelebration()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 18))
                        Text("Continue")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        ZStack {
                            VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)
                            
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.8),
                                    Color.purple.opacity(0.6)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    )
                    .cornerRadius(25)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: Color.blue.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .opacity(opacity)
                .scaleEffect(opacity > 0 ? 1.0 : 0.8)
            }
            .padding(40)
            .background(
                ZStack {
                    VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)
                    
                    RoundedRectangle(cornerRadius: 30)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                }
            )
            .scaleEffect(scale)
            .opacity(opacity)
            .shadow(color: Color.black.opacity(0.3), radius: 30, x: 0, y: 15)
        }
        .onAppear {
            showCelebration()
        }
    }
    
    private func showCelebration() {
        // Pick a random congratulatory message
        selectedMessage = congratulationsMessages.randomElement() ?? congratulationsMessages[0]
        
        // Animate in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0)) {
            scale = 1.0
            opacity = 1.0
        }
        
        // Auto-dismiss after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if isShowing {
                dismissCelebration()
            }
        }
    }
    
    private func dismissCelebration() {
        withAnimation(.easeOut(duration: 0.3)) {
            scale = 0.8
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isShowing = false
        }
    }
}

// Lottie View Wrapper
struct LottieView: UIViewRepresentable {
    let animation: LottieAnimation?
    
    init(animation: LottieAnimation?) {
        self.animation = animation
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let animationView = LottieAnimationView(animation: animation)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.play()
        
        view.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor),
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            animationView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No updates needed
    }
    
    func looping() -> LottieView {
        return self
    }
}

#Preview {
    CelebrationOverlay(isShowing: .constant(true), goalName: "Walk 15,000 steps")
}
