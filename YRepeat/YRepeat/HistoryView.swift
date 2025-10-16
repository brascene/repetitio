//
//  HistoryView.swift
//  YRepeat
//
//  Created by Dino Pelic on 15. 10. 2025..
//

import SwiftUI
import Lottie

enum HistorySegment: String, CaseIterable {
    case videos = "Videos"
    case tasks = "Tasks"
}

struct HistoryView: View {
    @ObservedObject var historyManager: HistoryManager
    @ObservedObject var playerController: YouTubePlayerController
    @EnvironmentObject var dailyRepeatManager: DailyRepeatManager

    @Binding var selectedTab: Int
    @Binding var youtubeURL: String
    @Binding var startTime: String
    @Binding var endTime: String
    @Binding var repeatCount: String

    @State private var showClearAlert = false
    @State private var selectedHistorySegment: HistorySegment = .videos

    var body: some View {
        ZStack {
            // Premium gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.15, blue: 0.3),
                    Color(red: 0.05, green: 0.1, blue: 0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("History")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    Spacer()

                    if (selectedHistorySegment == .videos && !historyManager.items.isEmpty) || 
                       (selectedHistorySegment == .tasks && !dailyRepeatManager.taskHistory.isEmpty) {
                        Button {
                            showClearAlert = true
                        } label: {
                            Image(systemName: "trash.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Segmented Control
                HStack(spacing: 0) {
                    ForEach(HistorySegment.allCases, id: \.self) { segment in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedHistorySegment = segment
                            }
                        }) {
                            VStack(spacing: 8) {
                                Text(segment.rawValue)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(selectedHistorySegment == segment ? .white : .white.opacity(0.6))
                                
                                // Active indicator
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(height: 3)
                                    .cornerRadius(1.5)
                                    .opacity(selectedHistorySegment == segment ? 1.0 : 0.0)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                // Content
                Group {
                    switch selectedHistorySegment {
                    case .videos:
                        VideosHistoryContent(
                            historyManager: historyManager,
                            onLoadHistoryItem: loadHistoryItem
                        )
                    case .tasks:
                        TasksHistoryContent(
                            dailyRepeatManager: dailyRepeatManager,
                            onRestartTask: restartTaskFromHistory
                        )
                    }
                }
            }
        }
        .alert("Clear All History", isPresented: $showClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                withAnimation {
                    switch selectedHistorySegment {
                    case .videos:
                        historyManager.clearAll()
                    case .tasks:
                        dailyRepeatManager.clearTaskHistory()
                    }
                }
            }
        } message: {
            switch selectedHistorySegment {
            case .videos:
                Text("Are you sure you want to delete all \(historyManager.items.count) saved videos?")
            case .tasks:
                Text("Are you sure you want to delete all \(dailyRepeatManager.taskHistory.count) completed tasks?")
            }
        }
    }

    private func loadHistoryItem(_ item: HistoryItem) {
        // Set the URL and time fields
        youtubeURL = item.videoURL
        startTime = item.startTimeFormatted
        endTime = item.endTimeFormatted
        repeatCount = "\(item.repeatCount)"

        // Switch to player tab
        selectedTab = 0

        // Load the video
        playerController.isReady = false
        playerController.loadVideo(videoId: item.videoId)
        playerController.showStatus("Loading video from history...", type: .info)
    }
    
    private func restartTaskFromHistory(_ historyItem: TaskHistoryItem) {
        // Restart the task from history
        dailyRepeatManager.restartTaskFromHistory(historyItem)
        
        // Switch to Daily tab
        selectedTab = 1
        
        // Show success message
        playerController.showStatus("Task restarted for today!", type: .success)
    }
}

struct PremiumHistoryCard: View {
    let item: HistoryItem
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            onTap()
        } label: {
            GlassmorphicCard {
                HStack(spacing: 16) {
                    // Play icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)

                        Image(systemName: "play.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        // Video URL
                        Text(item.videoURL)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        // Time and repeat info
                        HStack(spacing: 16) {
                            HStack(spacing: 6) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.blue)
                                Text("\(item.startTimeFormatted) → \(item.endTimeFormatted)")
                                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.7))
                            }

                            HStack(spacing: 6) {
                                Image(systemName: "repeat.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.purple)
                                Text(item.repeatCountFormatted)
                                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }

                        // Saved date
                        Text(formatDate(item.savedAt))
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Spacer()

                    // Delete button
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.red.opacity(0.8))
                            .frame(width: 40, height: 40)
                            .background(Color.red.opacity(0.15))
                            .cornerRadius(10)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Content Views

struct VideosHistoryContent: View {
    @ObservedObject var historyManager: HistoryManager
    let onLoadHistoryItem: (HistoryItem) -> Void
    
    var body: some View {
        if historyManager.items.isEmpty {
            Spacer()
            VStack(spacing: 24) {
                Image(systemName: "clock.badge.questionmark")
                    .font(.system(size: 70))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                VStack(spacing: 8) {
                    Text("No Saved Videos")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Text("Save videos from the Player tab\nto see them here")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
            }
            Spacer()
        } else {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(historyManager.items) { item in
                        PremiumHistoryCard(item: item) {
                            onLoadHistoryItem(item)
                        } onDelete: {
                            withAnimation {
                                historyManager.deleteItem(item)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
}

struct TasksHistoryContent: View {
    @ObservedObject var dailyRepeatManager: DailyRepeatManager
    let onRestartTask: (TaskHistoryItem) -> Void
    
    var body: some View {
        if dailyRepeatManager.taskHistory.isEmpty {
            Spacer()
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.badge.questionmark")
                    .font(.system(size: 70))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green.opacity(0.6), .mint.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                VStack(spacing: 8) {
                    Text("No Completed Tasks")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Text("Complete tasks from the Daily tab\nto see them here")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
            }
            Spacer()
        } else {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(dailyRepeatManager.taskHistory) { historyItem in
                        TaskHistoryCard(historyItem: historyItem) {
                            onRestartTask(historyItem)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
}

struct TaskHistoryCard: View {
    let historyItem: TaskHistoryItem
    let onRestart: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button {
            onRestart()
        } label: {
            GlassmorphicCard {
                HStack(spacing: 16) {
                    // Task icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [colorFromString(historyItem.color), colorFromString(historyItem.color).opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: historyItem.iconName)
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        // Task name
                        Text(historyItem.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        // Completion info
                        HStack(spacing: 16) {
                            HStack(spacing: 6) {
                                Image(systemName: "target")
                                    .font(.system(size: 12))
                                    .foregroundColor(.green)
                                Text("\(historyItem.targetValue)")
                                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.green)
                                Text(historyItem.displayText)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        
                        // Completion date
                        Text(historyItem.relativeDate)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    // Restart button
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                        
                        Text("Restart")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
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
    HistoryView(
        historyManager: HistoryManager(),
        playerController: YouTubePlayerController(),
        selectedTab: .constant(1),
        youtubeURL: .constant(""),
        startTime: .constant(""),
        endTime: .constant(""),
        repeatCount: .constant("0")
    )
    .environmentObject(DailyRepeatManager())
}
