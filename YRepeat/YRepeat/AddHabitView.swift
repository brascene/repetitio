//
//  AddHabitView.swift
//  YRepeat
//
//  Created for Habits feature
//

import SwiftUI

struct AddHabitView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var manager: HabitManager
    
    @State private var habitName = ""
    @State private var isGoodHabit = true
    @State private var selectedIcon = "star.fill"
    @State private var selectedIconEmoji = "⭐"
    @State private var selectedColor = "blue"
    @State private var customColor: Color = .blue
    @State private var showingColorPicker = false
    
    // Grid layout for icons
    private let columns = [
        GridItem(.adaptive(minimum: 50, maximum: 60), spacing: 12)
    ]
    
    let colors = ["blue", "green", "purple", "orange", "red", "pink", "yellow", "mint", "cyan", "indigo"]
    
    var body: some View {
        NavigationView {
            ZStack {
                LiquidBackgroundView()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Habit Type Selector
                        VStack(spacing: 16) {
                            Text("What kind of habit?")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 16) {
                                habitTypeButton(
                                    title: "Build",
                                    subtitle: "Good Habit",
                                    icon: "arrow.up.circle.fill",
                                    color: .green,
                                    isSelected: isGoodHabit
                                ) {
                                    withAnimation {
                                        isGoodHabit = true
                                        hideKeyboard()
                                    }
                                }
                                
                                habitTypeButton(
                                    title: "Break",
                                    subtitle: "Bad Habit",
                                    icon: "arrow.down.circle.fill",
                                    color: .red,
                                    isSelected: !isGoodHabit
                                ) {
                                    withAnimation {
                                        isGoodHabit = false
                                        hideKeyboard()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // Name Input
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Habit Name")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            
                            TextField("e.g., Exercise daily", text: $habitName)
                                .textFieldStyle(.plain)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                )
                                .foregroundColor(.white)
                                .submitLabel(.done)
                                .onSubmit {
                                    hideKeyboard()
                                }
                        }
                        .padding(.horizontal, 20)
                        
                        // Icon Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Choose an Icon")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            
                            ScrollView(.vertical, showsIndicators: false) {
                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(HabitIcons.all, id: \.sfSymbol) { iconData in
                                        iconButton(iconData: iconData)
                                    }
                                }
                                .padding(.horizontal, 4)
                                .padding(.vertical, 4)
                            }
                            .frame(height: 200) // Limit height for grid
                        }
                        .padding(.horizontal, 20)
                        
                        // Color Selection
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Choose a Color")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button {
                                    withAnimation {
                                        showingColorPicker.toggle()
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "eyedropper.full")
                                            .font(.system(size: 14))
                                        Text("Custom")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.15))
                                    )
                                }
                            }
                            
                            if showingColorPicker {
                                ColorPicker("Custom Color", selection: $customColor, supportsOpacity: false)
                                    .labelsHidden()
                                    .frame(height: 50)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.1))
                                    )
                                    .onChange(of: customColor) { _, newColor in
                                        selectedColor = colorToHexString(newColor)
                                        hideKeyboard()
                                    }
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(colors, id: \.self) { color in
                                        colorButton(color: color)
                                    }
                                }
                                .padding(.horizontal, 4)
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Create Button
                        Button {
                            hideKeyboard()
                            if !habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                manager.addHabit(
                                    name: habitName.trimmingCharacters(in: .whitespacesAndNewlines),
                                    isGoodHabit: isGoodHabit,
                                    iconName: selectedIcon,
                                    color: selectedColor
                                )
                                dismiss()
                            }
                        } label: {
                            Text("Create Habit")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: isGoodHabit ? [.green, .mint] : [.red, .orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .shadow(color: (isGoodHabit ? Color.green : Color.red).opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        .disabled(habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1)
                    }
                }
                .onTapGesture {
                    hideKeyboard()
                }
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        hideKeyboard()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func habitTypeButton(title: String, subtitle: String, icon: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(isSelected ? .white : color.opacity(0.6))
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        isSelected
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [color, color.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                              )
                            : AnyShapeStyle(.ultraThinMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? Color.white.opacity(0.4) : Color.white.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(color: isSelected ? color.opacity(0.4) : .clear, radius: 10, y: 5)
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    private func iconButton(iconData: (sfSymbol: String, emoji: String)) -> some View {
        Button {
            selectedIcon = iconData.sfSymbol
            selectedIconEmoji = iconData.emoji
            hideKeyboard()
        } label: {
            Group {
                if UIImage(systemName: iconData.sfSymbol) != nil {
                    Image(systemName: iconData.sfSymbol)
                        .font(.system(size: 24))
                } else {
                    Text(iconData.emoji)
                        .font(.system(size: 24))
                }
            }
            .foregroundColor(selectedIcon == iconData.sfSymbol ? .white : .white.opacity(0.7))
            .frame(width: 50, height: 50)
            .background(
                Circle()
                    .fill(selectedIcon == iconData.sfSymbol ? Color.pink.opacity(0.4) : Color.white.opacity(0.1))
            )
            .overlay(
                Circle()
                    .stroke(selectedIcon == iconData.sfSymbol ? Color.pink : Color.white.opacity(0.2), lineWidth: selectedIcon == iconData.sfSymbol ? 2 : 1)
            )
        }
    }
    
    private func colorButton(color: String) -> some View {
        Button {
            selectedColor = color
            showingColorPicker = false
            hideKeyboard()
        } label: {
            Circle()
                .fill(colorFromString(color))
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                )
                .shadow(color: selectedColor == color ? colorFromString(color).opacity(0.6) : .clear, radius: 8)
                .scaleEffect(selectedColor == color ? 1.1 : 1.0)
                .animation(.spring(response: 0.3), value: selectedColor)
        }
    }
    
    private func colorFromString(_ colorName: String) -> Color {
        // Shared logic with HabitCardView - ideally move to utility
         if colorName.hasPrefix("#") {
            return Color(hex: colorName) ?? .blue
        }
        
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
    
    private func colorToHexString(_ color: Color) -> String {
        return color.toHex() ?? "#0000FF"
    }
}

