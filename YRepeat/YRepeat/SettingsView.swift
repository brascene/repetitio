//
//  SettingsView.swift
//  YRepeat
//
//  Created for Settings feature
//

import SwiftUI
import FamilyControls

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var appBlockingManager: AppBlockingManager
    @AppStorage("showPlayerTab") private var showPlayerTab = true
    @AppStorage("showFastTab") private var showFastTab = true

    @State private var showAppPicker = false
    @State private var showTimePicker = false
    
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

                        // App Blocking Section
                        GlassmorphicCard {
                            VStack(alignment: .leading, spacing: 20) {
                                // Header
                                HStack {
                                    Image(systemName: "lock.shield.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.red, .orange],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    Text("App Blocking")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Spacer()
                                }

                                Divider()
                                    .background(Color.white.opacity(0.2))

                                if !appBlockingManager.isAuthorized {
                                    // Not authorized - show enable button
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Focus mode helps you stay productive by blocking distracting apps during your chosen time windows.")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.7))

                                        Button(action: {
                                            Task {
                                                await appBlockingManager.requestAuthorization()
                                            }
                                        }) {
                                            Text("Enable App Blocking")
                                        }
                                        .buttonStyle(PremiumButton(color: .red, isProminent: true))
                                    }
                                } else {
                                    // Authorized - show configuration options
                                    VStack(spacing: 16) {
                                        // Enable/Disable Toggle
                                        HStack {
                                            Text("Enable Blocking")
                                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                                .foregroundColor(.white)
                                            Spacer()
                                            Toggle("", isOn: Binding(
                                                get: { appBlockingManager.isBlockingEnabled },
                                                set: { newValue in
                                                    if newValue {
                                                        appBlockingManager.applySchedule()
                                                    } else {
                                                        appBlockingManager.removeSchedule()
                                                    }
                                                }
                                            ))
                                            .labelsHidden()
                                            .tint(.red)
                                        }

                                        Divider()
                                            .background(Color.white.opacity(0.2))

                                        // Select Apps Button
                                        Button(action: {
                                            showAppPicker = true
                                        }) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text("Select Apps")
                                                        .font(.system(size: 16, weight: .semibold))
                                                    Text("\(appBlockingManager.selectedApps.applicationTokens.count) apps whitelisted")
                                                        .font(.system(size: 13))
                                                        .opacity(0.7)
                                                }
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .opacity(0.5)
                                            }
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(Color.white.opacity(0.1))
                                            .cornerRadius(12)
                                        }

                                        // Set Time Range Button
                                        Button(action: {
                                            showTimePicker = true
                                        }) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text("Set Time Range")
                                                        .font(.system(size: 16, weight: .semibold))
                                                    Text(timeRangeText)
                                                        .font(.system(size: 13))
                                                        .opacity(0.7)
                                                }
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .opacity(0.5)
                                            }
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(Color.white.opacity(0.1))
                                            .cornerRadius(12)
                                        }
                                    }
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
        .sheet(isPresented: $showAppPicker) {
            AppBlockingPickerView(manager: appBlockingManager)
        }
        .sheet(isPresented: $showTimePicker) {
            AppBlockingTimePickerView(manager: appBlockingManager)
        }
    }

    private var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let start = formatter.string(from: appBlockingManager.startTime)
        let end = formatter.string(from: appBlockingManager.endTime)
        return "\(start) - \(end)"
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
