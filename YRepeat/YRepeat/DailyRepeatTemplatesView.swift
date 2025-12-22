//
//  DailyRepeatTemplatesView.swift
//  YRepeat
//
//  Created by Dino Pelic on 15. 10. 2025..
//

import SwiftUI

struct DailyRepeatTemplatesView: View {
    @ObservedObject var manager: DailyRepeatManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddItem = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LiquidBackgroundView()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Text("Quick Templates")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Invisible spacer for balance
                        Color.clear
                            .frame(width: 28, height: 28)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    // Templates Grid
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                            // Create Custom Card
                            CustomGoalCard {
                                showingAddItem = true
                            }
                            
                            // Template Cards
                            ForEach(DailyRepeatTemplate.templates, id: \.name) { template in
                                TemplateCard(template: template) {
                                    manager.addFromTemplate(template)
                                    dismiss()
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAddItem) {
            AddDailyRepeatView(manager: manager)
        }
    }
}

// Custom Goal Card
struct CustomGoalCard: View {
    let onCreate: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button {
            onCreate()
        } label: {
            GlassmorphicCard {
                VStack(spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .purple.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    
                    // Content
                    VStack(spacing: 8) {
                        Text("Create Custom")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Your own goal")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    // Create Button
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text("Create")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.2))
                    )
                }
                .frame(height: 160) // Fixed height for consistency
                .frame(maxWidth: .infinity) // Fill available width
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct TemplateCard: View {
    let template: DailyRepeatTemplate
    let onAdd: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button {
            onAdd()
        } label: {
            GlassmorphicCard {
                VStack(spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [colorFromString(template.color), colorFromString(template.color).opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: template.iconName)
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    
                    // Content
                    VStack(spacing: 8) {
                        Text(template.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("\(template.targetValue)")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    // Add Button
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text("Add")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.2))
                    )
                }
                .frame(height: 160) // Fixed height for consistency
                .frame(maxWidth: .infinity) // Fill available width
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
    
    private func colorFromString(_ colorName: String) -> Color {
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

#Preview {
    DailyRepeatTemplatesView(manager: DailyRepeatManager())
}
