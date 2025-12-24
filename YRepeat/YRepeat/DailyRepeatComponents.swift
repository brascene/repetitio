//
//  DailyRepeatComponents.swift
//  YRepeat
//
//  Created by Dino Pelic on 15. 10. 2025..
//

import SwiftUI

// MARK: - Shared Visual Effect Blur
// Defining this if not already available globally, or using a distinct name to be safe
struct GlassEffect: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

// MARK: - Liquid Background
struct LiquidBackgroundView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var animate = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: themeManager.backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Orb 1
            Circle()
                .fill(Color.blue.opacity(0.4))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: animate ? -100 : 100, y: animate ? -50 : 50)
                .animation(.easeInOut(duration: 10).repeatForever(autoreverses: true), value: animate)
            
            // Orb 2
            Circle()
                .fill(Color.purple.opacity(0.4))
                .frame(width: 350, height: 350)
                .blur(radius: 60)
                .offset(x: animate ? 100 : -100, y: animate ? 100 : -100)
                .animation(.easeInOut(duration: 14).repeatForever(autoreverses: true), value: animate)
            
            // Orb 3
            Circle()
                .fill(Color.indigo.opacity(0.4))
                .frame(width: 250, height: 250)
                .blur(radius: 50)
                .offset(x: animate ? 50 : -150, y: animate ? -150 : 100)
                .animation(.easeInOut(duration: 12).repeatForever(autoreverses: true), value: animate)
            
            // Overlay pattern or noise could be added here for texture
        }
        .onAppear {
            animate = true
        }
        .ignoresSafeArea()
    }
}

// MARK: - Modern Daily Card
struct ModernDailyCard: View {
    let item: DailyRepeatItem
    let onTap: () -> Void
    let onDecrement: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isPressed = false
    @State private var showControls = false
    
    var body: some View {
        ZStack {
            // Glass Background
            RoundedRectangle(cornerRadius: 24)
                .fill(Material.ultraThin)
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            
            HStack(spacing: 16) {
                // Circular Progress
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 8)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: item.progress)
                        .stroke(
                            itemColor(item.color),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: item.progress)
                    
                    Image(systemName: item.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("\(item.currentValue) / \(item.targetValue)")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Action Button (Increment)
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        onTap()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [itemColor(item.color), itemColor(item.color).opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                            .shadow(color: itemColor(item.color).opacity(0.5), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(16)
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.2)) {
                isPressed = pressing
            }
        }) {
            // Long press now directly opens edit
            onEdit()
        }
    }
    
    private func itemColor(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        case "red": return .red
        case "pink": return .pink
        case "yellow": return .yellow
        case "mint": return .mint
        case "cyan": return .cyan
        case "indigo": return .indigo
        default: return .blue
        }
    }
}

// MARK: - Modern Task History Card
struct ModernTaskHistoryCard: View {
    let historyItem: TaskHistoryItem
    let onRestart: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Material.ultraThin)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            
            HStack(spacing: 16) {
                // Task Icon
                ZStack {
                    Circle()
                        .fill(itemColor(historyItem.color).opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: historyItem.iconName)
                        .font(.system(size: 22))
                        .foregroundColor(itemColor(historyItem.color))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(historyItem.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        Label(historyItem.relativeDate, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Label("\(historyItem.targetValue)", systemImage: "target")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                // Restart Button
                Button(action: onRestart) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(16)
        }
    }
    
    private func itemColor(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        case "red": return .red
        case "pink": return .pink
        case "yellow": return .yellow
        case "mint": return .mint
        case "cyan": return .cyan
        case "indigo": return .indigo
        default: return .blue
        }
    }
}


// MARK: - Modern Progress Card
struct ModernProgressOverviewCard: View {
    @ObservedObject var manager: DailyRepeatManager
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Material.ultraThin)
                .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            
            HStack(spacing: 20) {
                // Circular Ring Progress
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 12)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: manager.totalProgress)
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 1.0, dampingFraction: 0.8), value: manager.totalProgress)
                    
                    VStack(spacing: 0) {
                        Text("\(Int(manager.totalProgress * 100))%")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Today's Progress")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("\(manager.completedItemsCount) of \(manager.totalItemsCount) goals completed")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            .padding(20)
        }
        .frame(height: 120)
    }
}

// MARK: - Custom Segmented Control
struct ModernSegmentedControl: View {
    @Binding var selectedSegment: DailySegment
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(DailySegment.allCases, id: \.self) { segment in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedSegment = segment
                    }
                }) {
                    Text(segment.rawValue)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(selectedSegment == segment ? .white : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                if selectedSegment == segment {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.2))
                                        .matchedGeometryEffect(id: "segmentBackground", in: namespace)
                                }
                            }
                        )
                }
            }
        }
        .padding(4)
        .background(Color.black.opacity(0.2))
        .cornerRadius(16)
    }
    
    @Namespace private var namespace
}
