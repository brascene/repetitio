//
//  TimeHelpers.swift
//  YRepeat
//
//  Created by Dino Pelic on 15. 10. 2025..
//

import Foundation

// Time conversion functions (ported from popup.js:6-44)
struct TimeHelpers {

    // Convert seconds to HH:MM:SS or MM:SS format
    static func secondsToTime(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }

    // Convert time string (HH:MM:SS, MM:SS, or seconds) to seconds
    static func timeToSeconds(_ timeStr: String) -> Double {
        let trimmed = timeStr.trimmingCharacters(in: .whitespaces)

        if trimmed.isEmpty {
            return 0
        }

        // If it's already a number (seconds), return it
        if let asNumber = Double(trimmed), !trimmed.contains(":") {
            return asNumber
        }

        // Parse time format (HH:MM:SS or MM:SS)
        let parts = trimmed.split(separator: ":").compactMap { Double($0) }

        if parts.count == 3 {
            // HH:MM:SS
            return parts[0] * 3600 + parts[1] * 60 + parts[2]
        } else if parts.count == 2 {
            // MM:SS
            return parts[0] * 60 + parts[1]
        } else if parts.count == 1 {
            // Just seconds
            return parts[0]
        }

        return 0
    }
}
