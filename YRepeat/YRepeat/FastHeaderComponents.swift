//
//  FastHeaderComponents.swift
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
            
            Text("Fast")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
}

struct FastSegmentedControl: View {
    @Binding var selectedSegment: FastSegment
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(FastSegment.allCases, id: \.self) { segment in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedSegment = segment
                    }
                } label: {
                    Text(segment.rawValue)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(selectedSegment == segment ? .white : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            ZStack {
                                if selectedSegment == segment {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.15))
                                        .matchedGeometryEffect(id: "fastSegmentBackground", in: namespace)
                                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                }
                            }
                        )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    @Namespace private var namespace
}

