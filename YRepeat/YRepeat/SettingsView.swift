//
//  SettingsView.swift
//  YRepeat
//
//  Created for Settings feature
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @AppStorage("showPlayerTab") private var showPlayerTab = true
    @AppStorage("showFastTab") private var showFastTab = true
    
    var body: some View {
        ZStack {
            // Theme-aware background
            LiquidBackgroundView()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Appearance Section
                        GlassmorphicCard {
                            VStack(alignment: .leading, spacing: 20) {
                                HStack {
                                    Image(systemName: "paintpalette.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.pink, .orange],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    
                                    Text("Appearance")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.2))
                                
                                // Gradient Mode Toggle
                                HStack {
                                    Text("Use Single Color")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $themeManager.useSingleColor)
                                        .labelsHidden()
                                        .tint(.blue)
                                }
                                
                                if themeManager.useSingleColor {
                                    // Single Color Picker
                                    HStack {
                                        Text("Background Color")
                                            .font(.system(size: 16, weight: .medium, design: .rounded))
                                            .foregroundColor(.white.opacity(0.7))
                                        
                                        Spacer()
                                        
                                        ColorPicker("", selection: Binding(
                                            get: { themeManager.singleColor },
                                            set: { themeManager.setSingleColor($0) }
                                        ))
                                        .labelsHidden()
                                    }
                                } else {
                                    // Gradient Pickers
                                    VStack(spacing: 16) {
                                        HStack {
                                            Text("Start Color")
                                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                                .foregroundColor(.white.opacity(0.7))
                                            
                                            Spacer()
                                            
                                            ColorPicker("", selection: Binding(
                                                get: { themeManager.gradientStart },
                                                set: { newColor in
                                                    themeManager.setGradientColors(
                                                        start: newColor,
                                                        end: themeManager.gradientEnd
                                                    )
                                                }
                                            ))
                                            .labelsHidden()
                                        }
                                        
                                        HStack {
                                            Text("End Color")
                                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                                .foregroundColor(.white.opacity(0.7))
                                            
                                            Spacer()
                                            
                                            ColorPicker("", selection: Binding(
                                                get: { themeManager.gradientEnd },
                                                set: { newColor in
                                                    themeManager.setGradientColors(
                                                        start: themeManager.gradientStart,
                                                        end: newColor
                                                    )
                                                }
                                            ))
                                            .labelsHidden()
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Tab Visibility Section
                        GlassmorphicCard {
                            VStack(alignment: .leading, spacing: 20) {
                                HStack {
                                    Image(systemName: "eye.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.blue, .purple],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    
                                    Text("Tab Visibility")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.2))
                                
                                // Player Tab Toggle
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "play.rectangle.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(.blue)
                                            Text("Player Tab")
                                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                                .foregroundColor(.white)
                                        }
                                        
                                        Text("Show or hide the Player tab in the tab bar")
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $showPlayerTab)
                                        .labelsHidden()
                                        .tint(.blue)
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.2))
                                
                                // Fast Tab Toggle
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "moon.stars.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(.purple)
                                            Text("Fast Tab")
                                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                                .foregroundColor(.white)
                                        }
                                        
                                        Text("Show or hide the Fast tab in the tab bar")
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $showFastTab)
                                        .labelsHidden()
                                        .tint(.purple)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
                            .frame(height: 20)
                    }
                }
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Image(systemName: "gearshape.fill")
            .font(.system(size: 32))
            .foregroundStyle(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            Text("Settings")
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

#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
}
