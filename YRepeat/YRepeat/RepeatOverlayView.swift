//
//  RepeatOverlayView.swift
//  YRepeat
//
//  Created by Dino Pelic on 15. 10. 2025..
//

import SwiftUI

struct RepeatOverlayView: View {
    let currentCount: Int
    let totalCount: Int
    let onStop: () -> Void

    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            // Main overlay card
            VStack(spacing: 20) {
                // Repeat count display
                VStack(spacing: 8) {
                    Text("Repeating")
                        .font(.headline)
                        .foregroundColor(.white)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(currentCount)")
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        if totalCount > 0 {
                            Text("/ \(totalCount)")
                                .font(.system(size: 30, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                        } else {
                            Image(systemName: "infinity")
                                .font(.system(size: 30, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .padding(.top, 8)

                // Stop button
                Button {
                    onStop()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 20))
                        Text("Stop")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.red.opacity(0.9))
                    .cornerRadius(25)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(40)
            .background(
                ZStack {
                    // Blur effect
                    VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)

                    // Gradient overlay for liquid effect
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.3),
                            Color.purple.opacity(0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .cornerRadius(30)
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

// Custom button style with scale effect
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .brightness(configuration.isPressed ? -0.15 : 0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// Visual effect blur view
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}

#Preview {
    ZStack {
        Color.gray
        RepeatOverlayView(currentCount: 2, totalCount: 4, onStop: {})
    }
}
