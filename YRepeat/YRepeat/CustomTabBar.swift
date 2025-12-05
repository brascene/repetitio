//
//  CustomTabBar.swift
//  YRepeat
//
//  Created by Dino Pelic on 15. 10. 2025..
//

import SwiftUI
import UIKit

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        GeometryReader { geometry in
            let containerWidth = geometry.size.width - 32 // Account for padding
            let tabCount: CGFloat = 4
            let tabWidth = containerWidth / tabCount
            
            ZStack(alignment: .leading) {
                // Native iOS 26 Liquid Glass Container Background
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.clear)
                    .background(LiquidGlassContainerBackground(spacing: 0))
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                
                // Floating capsule indicator (slides under selected tab)
                Capsule()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: tabWidth - 24, height: 32)
                    .offset(x: CGFloat(selectedTab) * tabWidth + (tabWidth / 2) - ((tabWidth - 24) / 2), y: 0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)
                
                // Tab items
                HStack(spacing: 0) {
                    TabBarItem(
                        icon: "play.rectangle.fill",
                        title: "Player",
                        isSelected: selectedTab == 0,
                        action: { selectedTab = 0 }
                    )
                    .frame(width: tabWidth)
                    
                    TabBarItem(
                        icon: "repeat.circle.fill",
                        title: "Daily",
                        isSelected: selectedTab == 1,
                        action: { selectedTab = 1 }
                    )
                    .frame(width: tabWidth)
                    
                    TabBarItem(
                        icon: "calendar",
                        title: "Calendar",
                        isSelected: selectedTab == 2,
                        action: { selectedTab = 2 }
                    )
                    .frame(width: tabWidth)
                    
                    TabBarItem(
                        icon: "heart.fill",
                        title: "Habits",
                        isSelected: selectedTab == 3,
                        action: { selectedTab = 3 }
                    )
                    .frame(width: tabWidth)
                }
            }
        }
        .frame(height: 70)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

struct TabBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .symbolVariant(isSelected ? .fill : .none)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Liquid Glass Views

struct LiquidGlassContainerBackground: UIViewRepresentable {
    var spacing: CGFloat
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let glassView = UIVisualEffectView()
        
        if #available(iOS 26.0, *) {
            let effect = UIGlassContainerEffect()
            effect.spacing = spacing
            glassView.effect = effect
        } else {
            // Fallback for older iOS versions
            glassView.effect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        }
        
        return glassView
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        if #available(iOS 26.0, *) {
            if let effect = uiView.effect as? UIGlassContainerEffect {
                effect.spacing = spacing
            } else {
                let effect = UIGlassContainerEffect()
                effect.spacing = spacing
                uiView.effect = effect
            }
        }
    }
}

struct LiquidGlassView<Content: View>: UIViewRepresentable {
    var style: LiquidGlassEffectStyle = .regular
    var interactive: Bool = false
    var tintColor: UIColor?
    let content: Content
    
    init(style: LiquidGlassEffectStyle = .regular, interactive: Bool = false, tintColor: UIColor? = nil, @ViewBuilder content: () -> Content) {
        self.style = style
        self.interactive = interactive
        self.tintColor = tintColor
        self.content = content()
    }
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        
        if #available(iOS 26.0, *) {
            let glassView = UIVisualEffectView()
            
            switch style {
            case .regular:
                let effect = UIGlassEffect(style: .regular)
                effect.isInteractive = interactive
                effect.tintColor = tintColor
                glassView.effect = effect
            case .clear:
                let effect = UIGlassEffect(style: .clear)
                effect.isInteractive = interactive
                effect.tintColor = tintColor
                glassView.effect = effect
            case .none:
                break
            }
            
            glassView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(glassView)
            
            NSLayoutConstraint.activate([
                glassView.topAnchor.constraint(equalTo: containerView.topAnchor),
                glassView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                glassView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                glassView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
        }
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if #available(iOS 26.0, *) {
            if let glassView = uiView.subviews.first as? UIVisualEffectView {
                switch style {
                case .regular:
                    let effect = UIGlassEffect(style: .regular)
                    effect.isInteractive = interactive
                    effect.tintColor = tintColor
                    UIView.animate(withDuration: 0.3) {
                        glassView.effect = effect
                    }
                case .clear:
                    let effect = UIGlassEffect(style: .clear)
                    effect.isInteractive = interactive
                    effect.tintColor = tintColor
                    UIView.animate(withDuration: 0.3) {
                        glassView.effect = effect
                    }
                case .none:
                    UIView.animate(withDuration: 0.3) {
                        glassView.effect = nil
                    }
                }
            }
        }
    }
}

enum LiquidGlassEffectStyle {
    case regular
    case clear
    case none
}


#Preview {
    ZStack {
        // Background similar to your app
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.05, green: 0.05, blue: 0.15),
                Color(red: 0.1, green: 0.15, blue: 0.3)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VStack {
            Spacer()
            
            CustomTabBar(selectedTab: .constant(1))
        }
    }
}
