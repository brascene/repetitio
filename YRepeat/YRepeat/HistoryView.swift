//
//  HistoryView.swift
//  YRepeat
//
//  Created by Dino Pelic on 15. 10. 2025..
//

import SwiftUI
import Lottie

struct HistoryView: View {
    @ObservedObject var historyManager: HistoryManager
    @ObservedObject var playerController: YouTubePlayerController

    @Binding var selectedTab: Int
    @Binding var youtubeURL: String
    @Binding var startTime: String
    @Binding var endTime: String
    @Binding var repeatCount: String

    @State private var showClearAlert = false

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

                    if !historyManager.items.isEmpty {
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
                
                // Content
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
                                    loadHistoryItem(item)
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
        .alert("Clear All History", isPresented: $showClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                withAnimation {
                    historyManager.clearAll()
                }
            }
        } message: {
            Text("Are you sure you want to delete all \(historyManager.items.count) saved videos?")
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
}
