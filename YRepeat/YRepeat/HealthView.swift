//
//  HealthView.swift
//  YRepeat
//
//  Created for Health feature
//

import SwiftUI

enum HealthTab: String, CaseIterable {
    case fast = "Fasting"
    case exercise = "Exercise"
}

struct HealthView: View {
    @State private var selectedTab: HealthTab = .fast
    
    var body: some View {
        ZStack {
            // Background is handled by child views usually, but FastView puts it inside ZStack.
            // ExerciseView doesn't have a background wrapper yet.
            // Let's put the background here to be consistent.
            LiquidBackgroundView()
            
            VStack(spacing: 0) {
                // Header (We might want a common header or keep FastView's header)
                // FastView has its own header. ExerciseView doesn't.
                // Let's hide FastView's header if we are wrapping it, OR let HealthView handle the main header
                // and push content down.
                // FastView implementation includes LiquidBackground and ScrollView.
                // If I embed FastView, it will double the background.
                // I should probably modify FastView to optionally hide its background/header, or just simple overlay.
                
                // Better approach: HealthView manages the top segmented control and switches the whole view content.
                // But FastView is complex.
                
                // Let's try to overlay the segmented control on top of FastView's header? No, that's messy.
                // Let's create a custom header for HealthView that includes the segmented control.
                
                // Header
                HStack {
                    Image(systemName: selectedTab == .fast ? "moon.stars.fill" : "figure.run")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            LinearGradient(
                                colors: selectedTab == .fast ? [.purple, .blue] : [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .animation(.spring(), value: selectedTab)
                    
                    Text("Health")
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
                .padding(.bottom, 10)
                
                // Segmented Control
                HStack(spacing: 0) {
                    ForEach(HealthTab.allCases, id: \.self) { tab in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = tab
                            }
                        }) {
                            Text(tab.rawValue)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    ZStack {
                                        if selectedTab == tab {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(
                                                    LinearGradient(
                                                        colors: selectedTab == .fast ? [.purple, .blue] : [.green, .mint],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .matchedGeometryEffect(id: "healthTab", in: namespace)
                                        }
                                    }
                                )
                        }
                    }
                }
                .padding(4)
                .background(Color.black.opacity(0.2))
                .cornerRadius(16)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                // Content
                Group {
                    if selectedTab == .fast {
                        // We need FastView content but WITHOUT its header and background if possible.
                        // However, FastView is built with ZStack background.
                        // Let's modify FastView slightly or just use it as is.
                        // If we use it as is, we get double background.
                        // Let's just assume FastView handles itself and we put it here.
                        // BUT wait, if we put FastView here, our Segmented Control will be pushed down or covered?
                        // FastView takes full screen.
                        
                        // Refactor idea:
                        // Make FastView take a parameter `embedInNavigation: Bool` or `showBackground: Bool`.
                        // For now, I'll cheat: I'll recreate the FastView body content here if I can, OR
                        // I'll make a `FastContentView` that `FastView` uses.
                        // Actually, I'll just use FastView but obscure the top part? No.
                        
                        // Let's look at FastView again. It has FastHeaderView().
                        // I will edit FastView to accept a Binding or Environment to hide header/background.
                        // OR simpler: Just let FastView be the view for .fast tab, but OVERLAY the Health segmented control?
                        // No, the user wants "Health" tab, which contains Fast and Exercise.
                        // So the "Health" header should stay.
                        // So FastView shouldn't have "Fasting" header.
                        
                        FastView(embedded: true)
                    } else {
                        ScrollView(showsIndicators: false) {
                            ExerciseView()
                                .padding(.top, 20)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    @Namespace private var namespace
}

