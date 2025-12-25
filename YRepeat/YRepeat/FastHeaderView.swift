//
//  FastHeaderView.swift
//  YRepeat
//
//  Created for Fasting feature
//

import SwiftUI

struct FastHeaderView: View {
    var body: some View {
        HStack {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 32))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Fasting")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
}

