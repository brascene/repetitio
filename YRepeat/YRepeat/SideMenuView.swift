//
//  SideMenuView.swift
//  YRepeat
//
//  Created for Side Menu Navigation
//

import SwiftUI

struct SideMenuView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var isShowing: Bool
    @Binding var selectedTab: Tab
    @Binding var dragProgress: CGFloat
    @AppStorage("showPlayerTab") private var showPlayerTab = true
    @AppStorage("showHabitsTab") private var showHabitsTab = true
    @AppStorage("showDiceTab") private var showDiceTab = true
    @AppStorage("showXOTab") private var showXOTab = false
    @AppStorage("use3DDice") private var use3DDice = false

    @State private var animateItems = false

    var body: some View {
        ZStack(alignment: .leading) {
            // Dimmed background with blur - interactive opacity
            if dragProgress > 0 {
                Color.black.opacity(0.4 * dragProgress)
                    .background(.ultraThinMaterial.opacity(0.3 * dragProgress))
                    .ignoresSafeArea()
                    .onTapGesture {
                        closeMenu()
                    }
            }

            // Menu Panel - follows dragProgress
            if dragProgress > 0 {
                menuPanel
                    .offset(x: -280 + (dragProgress * 280)) // Start at -280 (off-screen), slide to 0
                    .opacity(dragProgress)
            }
        }
        .onChange(of: isShowing) { oldValue, newValue in
            if newValue {
                // Stagger menu item animations
                animateItems = false
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.1)) {
                    animateItems = true
                }
            } else {
                animateItems = false
            }
        }
    }

    private func closeMenu() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
            isShowing = false
            dragProgress = 0
        }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private var menuPanel: some View {
        VStack(spacing: 0) {
            // Header
            menuHeader

            // Menu Items
            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    // Main Tabs - Always visible for easy navigation back
                    menuSection(title: "Main", icon: "square.grid.2x2.fill") {
                        menuItem(
                            title: "Daily",
                            icon: "repeat.circle.fill",
                            color: .blue,
                            tab: .daily
                        )

                        menuItem(
                            title: "Calendar",
                            icon: "calendar",
                            color: .green,
                            tab: .calendar
                        )

                        menuItem(
                            title: "Health",
                            icon: "waveform.path.ecg",
                            color: .red,
                            tab: .fast
                        )

                        menuItem(
                            title: "Check",
                            icon: "checkmark.square.fill",
                            color: .teal,
                            tab: .check
                        )
                    }

                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.vertical, 8)

                    // Games Section
                    menuSection(title: "Games", icon: "gamecontroller.fill") {
                        menuItem(
                            title: use3DDice ? "Dice (3D)" : "Dice",
                            icon: use3DDice ? "cube.fill" : "die.face.5.fill",
                            color: .yellow,
                            tab: .dice
                        )

                        menuItem(
                            title: "XO Game",
                            icon: "xmark.circle.fill",
                            color: .purple,
                            tab: .xo
                        )
                    }

                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.vertical, 8)

                    // Apps Section
                    menuSection(title: "Apps", icon: "square.stack.3d.up.fill") {
                        menuItem(
                            title: "Player",
                            icon: "play.rectangle.fill",
                            color: .pink,
                            tab: .player
                        )

                        menuItem(
                            title: "Habits",
                            icon: "heart.fill",
                            color: .orange,
                            tab: .habits
                        )
                    }

                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.vertical, 8)

                    // Settings
                    menuItem(
                        title: "Settings",
                        icon: "gearshape.fill",
                        color: Color.white.opacity(0.6),
                        tab: .settings
                    )
                }
                .padding(.vertical, 16)
            }

            Spacer()
        }
        .frame(width: 280)
        .background(
            LinearGradient(
                colors: themeManager.backgroundColors.map { $0.opacity(0.95) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(Material.ultraThinMaterial.opacity(0.6))
        .overlay(
            // Right edge glow effect
            LinearGradient(
                colors: [
                    Color.white.opacity(0.3),
                    Color.white.opacity(0.1),
                    Color.white.opacity(0.0)
                ],
                startPoint: .trailing,
                endPoint: .leading
            )
            .frame(width: 2)
            .frame(maxWidth: .infinity, alignment: .trailing)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 5, y: 0)
    }

    private var menuHeader: some View {
        VStack(spacing: 12) {
            HStack {
                // App Icon/Logo
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)

                    Image(systemName: "repeat.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("YRepeat")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Menu")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 20)

            Divider()
                .background(Color.white.opacity(0.2))
        }
    }

    private func menuSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))

                Text(title.uppercased())
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            content()
        }
    }

    private func menuItem(title: String, icon: String, color: Color, tab: Tab) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedTab = tab
                isShowing = false
            }

            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(color)
                }

                Text(title)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                if selectedTab == tab {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .contentShape(Rectangle()) // Make entire area tappable
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedTab == tab ? Color.white.opacity(0.15) : Color.clear)
                    .shadow(color: selectedTab == tab ? Color.white.opacity(0.1) : Color.clear, radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, 12)
    }
}

#Preview {
    SideMenuView(isShowing: .constant(true), selectedTab: .constant(.daily), dragProgress: .constant(1.0))
        .environmentObject(ThemeManager())
}
