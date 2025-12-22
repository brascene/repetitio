//
//  FastHistoryRowView.swift
//  YRepeat
//
//  Created for Fasting feature
//

import SwiftUI

struct FastHistoryRowView: View {
    let fast: Fast
    let onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: fast.isCompleted 
                                ? [.green.opacity(0.2), .mint.opacity(0.1)]
                                : [.orange.opacity(0.2), .red.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: fast.isCompleted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(fast.isCompleted ? .green : .orange)
            }
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(fast.fastType.displayName)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(formatTime(fast.durationHours))
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                
                HStack {
                    Text(formatDate(fast.startTime))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                    
                    if let endTime = fast.endTime {
                        Text("Ended \(formatShortTime(endTime))")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 4)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: fast.isCompleted ? [.green, .mint] : [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * fast.progress, height: 4)
                    }
                }
                .frame(height: 4)
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete Fast", systemImage: "trash")
            }
        }
    }
    
    private func formatTime(_ hours: Double) -> String {
        let totalMinutes = Int(hours * 60)
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        return String(format: "%dh %02dm", h, m)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatShortTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

