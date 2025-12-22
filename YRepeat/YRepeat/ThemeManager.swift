//
//  ThemeManager.swift
//  YRepeat
//
//  Created for Theme Customization
//

import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    @AppStorage("theme_useSingleColor") var useSingleColor: Bool = false {
        didSet {
            objectWillChange.send()
        }
    }
    
    @AppStorage("theme_singleColor") private var storedSingleColor: String = "#0D0D26" {
        didSet {
            updateSingleColorFromStorage()
        }
    }
    
    @AppStorage("theme_gradientStart") private var storedGradientStart: String = "#0D0D26" {
        didSet {
            updateGradientStartFromStorage()
        }
    }
    
    @AppStorage("theme_gradientEnd") private var storedGradientEnd: String = "#1A264D" {
        didSet {
            updateGradientEndFromStorage()
        }
    }
    
    @Published var singleColor: Color = Color(red: 0.05, green: 0.05, blue: 0.15)
    @Published var gradientStart: Color = Color(red: 0.05, green: 0.05, blue: 0.15)
    @Published var gradientEnd: Color = Color(red: 0.1, green: 0.15, blue: 0.3)
    
    init() {
        // Load initial colors from storage
        updateSingleColorFromStorage()
        updateGradientStartFromStorage()
        updateGradientEndFromStorage()
    }
    
    private func updateSingleColorFromStorage() {
        singleColor = Color(hex: storedSingleColor) ?? Color(red: 0.05, green: 0.05, blue: 0.15)
    }
    
    private func updateGradientStartFromStorage() {
        gradientStart = Color(hex: storedGradientStart) ?? Color(red: 0.05, green: 0.05, blue: 0.15)
    }
    
    private func updateGradientEndFromStorage() {
        gradientEnd = Color(hex: storedGradientEnd) ?? Color(red: 0.1, green: 0.15, blue: 0.3)
    }
    
    var backgroundColors: [Color] {
        if useSingleColor {
            // Generate a subtle gradient from the single color
            // Create a darker and lighter variant for a smooth gradient
            let baseColor = singleColor
            let components = baseColor.components
            
            // Create a darker variant (reduce brightness by ~20%)
            let darker = Color(
                red: max(0, components.red * 0.8),
                green: max(0, components.green * 0.8),
                blue: max(0, components.blue * 0.8)
            )
            
            // Create a slightly lighter variant
            let lighter = Color(
                red: min(1, components.red * 1.1),
                green: min(1, components.green * 1.1),
                blue: min(1, components.blue * 1.1)
            )
            
            return [darker, baseColor, lighter]
        } else {
            return [gradientStart, gradientEnd]
        }
    }
    
    // Update methods to save to AppStorage
    func setSingleColor(_ color: Color) {
        singleColor = color
        storedSingleColor = color.toHex() ?? "#000000"
        objectWillChange.send()
    }
    
    func setGradientColors(start: Color, end: Color) {
        gradientStart = start
        gradientEnd = end
        storedGradientStart = start.toHex() ?? "#000000"
        storedGradientEnd = end.toHex() ?? "#000000"
        objectWillChange.send()
    }
}

// MARK: - Color Components Extension
extension Color {
    var components: (red: Double, green: Double, blue: Double, alpha: Double) {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return (Double(red), Double(green), Double(blue), Double(alpha))
    }
}

// MARK: - Color Extensions for Hex Support
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0

        let length = hexSanitized.count

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0

        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0

        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }

    func toHex() -> String? {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)

        if components.count >= 4 {
            a = Float(components[3])
        }

        if a != 1.0 {
            return String(format: "#%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}
