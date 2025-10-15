//
//  AddDailyRepeatView.swift
//  YRepeat
//
//  Created by Dino Pelic on 15. 10. 2025..
//

import SwiftUI

struct AddDailyRepeatView: View {
    @ObservedObject var manager: DailyRepeatManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var targetValue: String = "1"
    @State private var incrementAmount: String = "1"
    @State private var selectedIcon: String = "circle.fill"
    @State private var selectedColor: String = "blue"
    
    @FocusState private var isNameFocused: Bool
    
    let availableIcons = [
        "drop.fill", "figure.walk", "book.fill", "dumbbell.fill", "leaf.fill",
        "globe", "graduationcap.fill", "pencil", "figure.strengthtraining.traditional",
        "music.note", "heart.fill", "brain.head.profile", "eye.fill", "ear.fill",
        "hand.raised.fill", "car.fill", "bicycle", "house.fill", "bed.double.fill"
    ]
    
    let availableColors = [
        ("blue", "Blue"), ("green", "Green"), ("purple", "Purple"), ("orange", "Orange"),
        ("red", "Red"), ("pink", "Pink"), ("yellow", "Yellow"), ("mint", "Mint"),
        ("cyan", "Cyan"), ("indigo", "Indigo")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.15),
                        Color(red: 0.1, green: 0.15, blue: 0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("Create Daily Goal")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 20)
                        
                        // Form
                        VStack(spacing: 20) {
                            // Name Input
                            GlassmorphicCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "text.cursor")
                                            .foregroundColor(.blue)
                                        Text("Goal Name")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    
                                    TextField("e.g., Drink Water", text: $name)
                                        .foregroundColor(.white)
                                        .textFieldStyle(.plain)
                                        .focused($isNameFocused)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                }
                            }
                            
                            // Target Value and Increment Amount
                            HStack(spacing: 16) {
                                GlassmorphicCard {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: "target")
                                                .foregroundColor(.blue)
                                            Text("Goal")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white)
                                        }
                                        
                                        TextField("1", text: $targetValue)
                                            .foregroundColor(.white)
                                            .keyboardType(.numberPad)
                                            .textFieldStyle(.plain)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(Color.white.opacity(0.05))
                                            .cornerRadius(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                    }
                                }
                                
                                GlassmorphicCard {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: "plus.circle")
                                                .foregroundColor(.blue)
                                            Text("Per Tap")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white)
                                        }
                                        
                                        TextField("1", text: $incrementAmount)
                                            .foregroundColor(.white)
                                            .keyboardType(.numberPad)
                                            .textFieldStyle(.plain)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(Color.white.opacity(0.05))
                                            .cornerRadius(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                            
                            // Icon Selection
                            GlassmorphicCard {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Image(systemName: "photo")
                                            .foregroundColor(.blue)
                                        Text("Icon")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                                        ForEach(availableIcons, id: \.self) { icon in
                                            Button {
                                                selectedIcon = icon
                                            } label: {
                                                Image(systemName: icon)
                                                    .font(.system(size: 20))
                                                    .foregroundColor(selectedIcon == icon ? .white : .white.opacity(0.6))
                                                    .frame(width: 40, height: 40)
                                                    .background(
                                                        Circle()
                                                            .fill(selectedIcon == icon ? Color.blue : Color.white.opacity(0.1))
                                                    )
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Color Selection
                            GlassmorphicCard {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Image(systemName: "paintpalette")
                                            .foregroundColor(.blue)
                                        Text("Color")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(availableColors, id: \.0) { colorName, displayName in
                                                Button {
                                                    selectedColor = colorName
                                                } label: {
                                                    Text(displayName)
                                                        .font(.system(size: 12, weight: .medium))
                                                        .foregroundColor(selectedColor == colorName ? .white : .white.opacity(0.6))
                                                        .padding(.horizontal, 12)
                                                        .padding(.vertical, 8)
                                                        .background(
                                                            Capsule()
                                                                .fill(selectedColor == colorName ? colorFromString(colorName) : Color.white.opacity(0.1))
                                                        )
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 4)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Create Button
                        Button {
                            createGoal()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                Text("Create Goal")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PremiumButton(color: .blue, isProminent: true))
                        .padding(.horizontal, 20)
                        .disabled(name.isEmpty || targetValue.isEmpty || incrementAmount.isEmpty)
                        .opacity(name.isEmpty || targetValue.isEmpty || incrementAmount.isEmpty ? 0.6 : 1.0)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            isNameFocused = true
        }
    }
    
    private func createGoal() {
        guard let target = Int(targetValue), target > 0,
              let increment = Int(incrementAmount), increment > 0 else { return }
        
        manager.addItem(
            name: name,
            targetValue: target,
            incrementAmount: increment,
            iconName: selectedIcon,
            color: selectedColor
        )
        
        dismiss()
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
    AddDailyRepeatView(manager: DailyRepeatManager())
}
