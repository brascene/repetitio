//
//  EditHabitView.swift
//  YRepeat
//
//  Created for Habits feature
//

import SwiftUI

struct EditHabitView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var manager: HabitManager
    let habit: Habit
    
    @State private var habitName: String
    @State private var selectedIcon: String
    @State private var selectedIconEmoji: String
    @State private var selectedColor: String
    @State private var customColor: Color = .blue
    @State private var showingColorPicker = false
    
    // Grid layout for icons
    private let columns = [
        GridItem(.adaptive(minimum: 50, maximum: 60), spacing: 12)
    ]
    
    let colors = ["blue", "green", "purple", "orange", "red", "pink", "yellow", "mint", "cyan", "indigo"]
    
    init(manager: HabitManager, habit: Habit) {
        self.manager = manager
        self.habit = habit
        _habitName = State(initialValue: habit.name)
        _selectedIcon = State(initialValue: habit.iconName)
        _selectedColor = State(initialValue: habit.color)
        
        let iconEmoji = HabitIcons.emojiForIcon(habit.iconName)
        _selectedIconEmoji = State(initialValue: iconEmoji)
        
        _customColor = State(initialValue: Self.initialColorFromString(habit.color))
    }
    
    // Helper to get Color from string for init (can't call instance method)
    private static func initialColorFromString(_ colorName: String) -> Color {
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
    
    var body: some View {
        NavigationView {
            ZStack {
                LiquidBackgroundView()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Name Input
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Habit Name")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            
                            TextField("Habit name", text: $habitName)
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
                        .padding(.top, 8)
                        
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
                            .frame(height: 200)
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
                        
                        // Save Button
                        Button {
                            hideKeyboard()
                            if !habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                manager.updateHabit(
                                    habit: habit,
                                    name: habitName.trimmingCharacters(in: .whitespacesAndNewlines),
                                    iconName: selectedIcon,
                                    color: selectedColor
                                )
                                dismiss()
                            }
                        } label: {
                            Text("Save Changes")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.pink)
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .shadow(color: Color.pink.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        .disabled(habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .onTapGesture {
                    hideKeyboard()
                }
            }
            .navigationTitle("Edit Habit")
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

