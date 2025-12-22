//
//  FastStatsView.swift
//  YRepeat
//
//  Created for Fasting feature
//

import SwiftUI

struct FastStatsView: View {
    let fast: Fast
    
    var body: some View {
        HStack(spacing: 12) {
            statCard(
                title: "Goal",
                value: "\(fast.goalHours)h",
                icon: "target",
                color: .blue
            )
            
            statCard(
                title: "Started",
                value: formatStartTime(fast.startTime),
                icon: "play.circle.fill",
                color: .purple
            )
            
            statCard(
                title: "Ends",
                value: formatEndTime(start: fast.startTime, hours: fast.goalHours),
                icon: "stop.circle.fill",
                color: .orange
            )
        }
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func formatStartTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatEndTime(start: Date, hours: Int) -> String {
        let end = start.addingTimeInterval(TimeInterval(hours * 3600))
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: end)
    }
}

