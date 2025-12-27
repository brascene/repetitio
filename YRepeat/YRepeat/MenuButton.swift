//
//  MenuButton.swift
//  YRepeat
//
//  Created for Menu Button Component
//

import SwiftUI

struct MenuButton: View {
    @Binding var isMenuShowing: Bool

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isMenuShowing.toggle()
            }

            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.white.opacity(0.1)))
        }
    }
}
