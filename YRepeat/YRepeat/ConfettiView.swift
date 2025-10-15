//
//  ConfettiView.swift
//  YRepeat
//
//  Created by Dino Pelic on 15. 10. 2025..
//

import SwiftUI

struct ConfettiView: View {
    @State private var animate = false
    @Binding var isShowing: Bool

    let confettiCount = 50

    var body: some View {
        ZStack {
            ForEach(0..<confettiCount, id: \.self) { index in
                ConfettiPiece(index: index, animate: animate)
            }
        }
        .onAppear {
            animate = true

            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                isShowing = false
            }
        }
    }
}

struct ConfettiPiece: View {
    let index: Int
    @State private var yOffset: CGFloat = -100
    @State private var xOffset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1

    let animate: Bool

    private let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .pink, .purple]

    var body: some View {
        let randomColor = colors[index % colors.count]
        let randomSize = CGFloat.random(in: 8...15)
        let randomStartX = CGFloat.random(in: -UIScreen.main.bounds.width/2...UIScreen.main.bounds.width/2)
        let randomEndX = randomStartX + CGFloat.random(in: -100...100)
        let randomDuration = Double.random(in: 2...4)
        let randomDelay = Double.random(in: 0...0.5)

        RoundedRectangle(cornerRadius: 3)
            .fill(randomColor)
            .frame(width: randomSize, height: randomSize)
            .offset(x: xOffset, y: yOffset)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .onAppear {
                xOffset = randomStartX

                withAnimation(
                    Animation.easeIn(duration: randomDuration)
                        .delay(randomDelay)
                ) {
                    yOffset = UIScreen.main.bounds.height + 100
                    xOffset = randomEndX
                    rotation = Double.random(in: 360...720)
                    opacity = 0
                }
            }
    }
}

#Preview {
    ConfettiView(isShowing: .constant(true))
}
