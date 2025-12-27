//
//  SettingsView.swift
//  YRepeat
//
//  Created for Settings feature
//

import SwiftUI
import AuthenticationServices
internal import CoreData
#if DEBUG
import FamilyControls
#endif

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authenticationManager: AuthenticationManager
    @EnvironmentObject var firebaseSyncManager: FirebaseSyncManager
    #if DEBUG
    @EnvironmentObject var appBlockingManager: AppBlockingManager
    @State private var showAppPicker = false
    @State private var showTimePicker = false
    #endif
    @AppStorage("showPlayerTab") private var showPlayerTab = true
    @AppStorage("showFastTab") private var showFastTab = true
    @AppStorage("showHabitsTab") private var showHabitsTab = true
    @AppStorage("showCheckTab") private var showCheckTab = true
    @AppStorage("showDiceTab") private var showDiceTab = true
    @AppStorage("use3DDice") private var use3DDice = false

    // Expandable sections state
    @State private var appearanceExpanded = false
    @State private var tabVisibilityExpanded = false
    @State private var accountExpanded = false
    #if DEBUG
    @State private var appBlockingExpanded = false
    #endif

    // Confirmation alerts
    @State private var showWipeCloudDataAlert = false
    
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
                        // User Profile Card (when signed in)
                        if authenticationManager.isSignedIn {
                            GlassmorphicCard {
                                HStack(spacing: 16) {
                                    // Avatar
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.green, .cyan],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 64, height: 64)

                                        if let photoURL = authenticationManager.userPhotoURL {
                                            AsyncImage(url: photoURL) { image in
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                            } placeholder: {
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 28))
                                                    .foregroundColor(.white)
                                            }
                                            .frame(width: 64, height: 64)
                                            .clipShape(Circle())
                                        } else {
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 28))
                                                .foregroundColor(.white)
                                        }
                                    }

                                    // User Info
                                    VStack(alignment: .leading, spacing: 6) {
                                        if let name = authenticationManager.userName, !name.isEmpty {
                                            Text(name)
                                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                        } else {
                                            Text("Apple User")
                                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                        }

                                        if let email = authenticationManager.userEmail {
                                            Text(email)
                                                .font(.system(size: 14))
                                                .foregroundColor(.white.opacity(0.7))
                                        } else {
                                            Text("Signed in with Apple")
                                                .font(.system(size: 14))
                                                .foregroundColor(.white.opacity(0.7))
                                        }

                                        // Status badge
                                        HStack(spacing: 6) {
                                            Circle()
                                                .fill(Color.green)
                                                .frame(width: 8, height: 8)
                                            Text("Signed In")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.green)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.2))
                                        .cornerRadius(12)
                                    }

                                    Spacer()
                                }
                                .padding(20)
                            }
                            .padding(.horizontal, 20)
                        }

                        // Account & Sync Section
                        GlassmorphicCard {
                            VStack(alignment: .leading, spacing: 20) {
                                // Tappable Header
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        accountExpanded.toggle()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: authenticationManager.isSignedIn ? "icloud.fill" : "person.crop.circle.fill")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [.green, .cyan],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )

                                        Text(authenticationManager.isSignedIn ? "Cloud Sync" : "Account & Sync")
                                            .font(.system(size: 20, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.6))
                                            .rotationEffect(.degrees(accountExpanded ? 90 : 0))
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())

                                if accountExpanded {
                                    Divider()
                                        .background(Color.white.opacity(0.2))

                                    if !authenticationManager.isSignedIn {
                                        // Not signed in - show sign in option
                                        VStack(alignment: .leading, spacing: 16) {
                                            Text("Sign in to sync your data across devices and keep it backed up in the cloud.")
                                                .font(.system(size: 14))
                                                .foregroundColor(.white.opacity(0.7))
                                                .fixedSize(horizontal: false, vertical: true)

                                            Button(action: {
                                                authenticationManager.signInWithApple()
                                            }) {
                                                HStack {
                                                    Image(systemName: "applelogo")
                                                        .font(.system(size: 18, weight: .semibold))
                                                    Text("Sign in with Apple")
                                                        .font(.system(size: 16, weight: .semibold))
                                                }
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 50)
                                                .background(Color.black)
                                                .cornerRadius(12)
                                            }
                                        }
                                    } else {
                                        // Signed in - show sync controls
                                        VStack(spacing: 16) {
                                            // Sync Status
                                            VStack(alignment: .leading, spacing: 8) {
                                                HStack {
                                                    Image(systemName: firebaseSyncManager.isSyncing ? "arrow.triangle.2.circlepath" : "checkmark.circle.fill")
                                                        .font(.system(size: 16))
                                                        .foregroundColor(firebaseSyncManager.isSyncing ? .cyan : .green)
                                                        .symbolEffect(.rotate, isActive: firebaseSyncManager.isSyncing)

                                                    Text(firebaseSyncManager.syncStatus)
                                                        .font(.system(size: 14))
                                                        .foregroundColor(firebaseSyncManager.syncError != nil ? .red : .white.opacity(0.7))

                                                    Spacer()

                                                    if firebaseSyncManager.isSyncing {
                                                        ProgressView()
                                                            .scaleEffect(0.8)
                                                            .tint(.cyan)
                                                    }
                                                }

                                                if let lastSync = firebaseSyncManager.lastSyncDate {
                                                    Text("Last synced: \(lastSync, style: .relative) ago")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.white.opacity(0.5))
                                                }
                                            }
                                            .padding()
                                            .background(Color.white.opacity(0.05))
                                            .cornerRadius(12)

                                            // Sync Buttons
                                            HStack(spacing: 12) {
                                                Button(action: {
                                                    Task {
                                                        try? await firebaseSyncManager.uploadAllData()
                                                    }
                                                }) {
                                                    HStack {
                                                        Image(systemName: "icloud.and.arrow.up")
                                                        Text("Upload")
                                                    }
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.white)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 10)
                                                    .background(Color.blue.opacity(0.3))
                                                    .cornerRadius(8)
                                                }
                                                .disabled(firebaseSyncManager.isSyncing)

                                                Button(action: {
                                                    Task {
                                                        try? await firebaseSyncManager.downloadAllData()
                                                    }
                                                }) {
                                                    HStack {
                                                        Image(systemName: "icloud.and.arrow.down")
                                                        Text("Download")
                                                    }
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.white)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 10)
                                                    .background(Color.green.opacity(0.3))
                                                    .cornerRadius(8)
                                                }
                                                .disabled(firebaseSyncManager.isSyncing)
                                            }

                                            // Wipe Cloud Data Button
                                            Button(action: {
                                                showWipeCloudDataAlert = true
                                            }) {
                                                HStack {
                                                    Image(systemName: "trash.fill")
                                                    Text("Wipe Cloud Data")
                                                }
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 10)
                                                .background(Color.red.opacity(0.3))
                                                .cornerRadius(8)
                                            }
                                            .disabled(firebaseSyncManager.isSyncing)

                                            Divider()
                                                .background(Color.white.opacity(0.2))

                                            // Sign Out Button
                                            Button(action: {
                                                authenticationManager.signOut()
                                            }) {
                                                HStack {
                                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                                    Text("Sign Out")
                                                        .font(.system(size: 16, weight: .medium))
                                                }
                                                .foregroundColor(.red)
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(Color.red.opacity(0.1))
                                                .cornerRadius(12)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Appearance Section
                        GlassmorphicCard {
                            VStack(alignment: .leading, spacing: 20) {
                                // Tappable Header
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        appearanceExpanded.toggle()
                                    }
                                }) {
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

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.6))
                                            .rotationEffect(.degrees(appearanceExpanded ? 90 : 0))
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())

                                if appearanceExpanded {
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
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        // Tab Visibility Section
                        GlassmorphicCard {
                            VStack(alignment: .leading, spacing: 20) {
                                // Tappable Header
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        tabVisibilityExpanded.toggle()
                                    }
                                }) {
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

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.6))
                                            .rotationEffect(.degrees(tabVisibilityExpanded ? 90 : 0))
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())

                                if tabVisibilityExpanded {
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
                                            Image(systemName: "waveform.path.ecg")
                                                .font(.system(size: 18))
                                                .foregroundColor(.purple)
                                            Text("Health Tab")
                                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                                .foregroundColor(.white)
                                        }

                                        Text("Show or hide the Health tab in the tab bar")
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundColor(.white.opacity(0.7))
                                    }

                                    Spacer()

                                    Toggle("", isOn: $showFastTab)
                                        .labelsHidden()
                                        .tint(.purple)
                                }

                                Divider()
                                    .background(Color.white.opacity(0.2))

                                // Habits Tab Toggle
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "heart.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(.pink)
                                            Text("Habits Tab")
                                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                                .foregroundColor(.white)
                                        }

                                        Text("Show or hide the Habits tab in the tab bar")
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundColor(.white.opacity(0.7))
                                    }

                                    Spacer()

                                    Toggle("", isOn: $showHabitsTab)
                                        .labelsHidden()
                                        .tint(.pink)
                                }

                                Divider()
                                    .background(Color.white.opacity(0.2))

                                // Check Tab Toggle
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "checkmark.square.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(.green)
                                            Text("Check Tab")
                                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                                .foregroundColor(.white)
                                        }

                                        Text("Show or hide the Check tab in the tab bar")
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundColor(.white.opacity(0.7))
                                    }

                                    Spacer()

                                    Toggle("", isOn: $showCheckTab)
                                        .labelsHidden()
                                        .tint(.green)
                                }

                                Divider()
                                    .background(Color.white.opacity(0.2))

                                // Dice Tab Toggle
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "die.face.5.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(.orange)
                                            Text("Dice Tab")
                                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                                .foregroundColor(.white)
                                        }

                                        Text("Show or hide the Dice tab in the tab bar")
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundColor(.white.opacity(0.7))
                                    }

                                    Spacer()

                                    Toggle("", isOn: $showDiceTab)
                                        .labelsHidden()
                                        .tint(.orange)
                                }

                                if showDiceTab {
                                    Divider()
                                        .background(Color.white.opacity(0.2))

                                    // 3D Dice Mode Toggle
                                    HStack {
                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "cube.fill")
                                                    .font(.system(size: 18))
                                                    .foregroundColor(.orange)
                                                Text("3D Dice")
                                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                                    .foregroundColor(.white)
                                            }

                                            Text("Use realistic 3D dice with physics simulation")
                                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                                .foregroundColor(.white.opacity(0.7))
                                        }

                                        Spacer()

                                        Toggle("", isOn: $use3DDice)
                                            .labelsHidden()
                                            .tint(.orange)
                                    }
                                }
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        #if DEBUG
                        // App Blocking Section (Development Only)
                        GlassmorphicCard {
                            VStack(alignment: .leading, spacing: 20) {
                                // Tappable Header
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        appBlockingExpanded.toggle()
                                    }
                                }) {
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

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.6))
                                            .rotationEffect(.degrees(appBlockingExpanded ? 90 : 0))
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())

                                if appBlockingExpanded {
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
                        }
                        .padding(.horizontal, 20)
                        #endif

                        Spacer()
                            .frame(height: 20)
                    }
                }
            }
        }
        #if DEBUG
        .sheet(isPresented: $showAppPicker) {
            AppBlockingPickerView(manager: appBlockingManager)
        }
        .sheet(isPresented: $showTimePicker) {
            AppBlockingTimePickerView(manager: appBlockingManager)
        }
        #endif
        .alert("Wipe Cloud Data?", isPresented: $showWipeCloudDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Wipe", role: .destructive) {
                Task {
                    do {
                        try await firebaseSyncManager.clearAllCloudData()
                    } catch {
                        print("Failed to wipe cloud data: \(error)")
                    }
                }
            }
        } message: {
            Text("This will permanently delete all your cloud data (fasts, daily repeats, habits, calendar events). Your local data will remain untouched. This action cannot be undone.")
        }
    }

    #if DEBUG
    private var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let start = formatter.string(from: appBlockingManager.startTime)
        let end = formatter.string(from: appBlockingManager.endTime)
        return "\(start) - \(end)"
    }
    #endif

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
        .environmentObject(AuthenticationManager())
        .environmentObject(FirebaseSyncManager(context: PersistenceController.shared.container.viewContext))
}
