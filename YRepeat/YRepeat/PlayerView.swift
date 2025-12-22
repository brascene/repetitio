//
//  PlayerView.swift
//  YRepeat
//
//  Created by Dino Pelic on 15. 10. 2025..
//

import SwiftUI

enum PlayerSegment: String, CaseIterable {
    case player = "Player"
    case history = "History"
}

struct PlayerView: View {
    @ObservedObject var playerController: YouTubePlayerController
    @ObservedObject var historyManager: HistoryManager

    @Binding var youtubeURL: String
    @Binding var startTime: String
    @Binding var endTime: String
    @Binding var repeatCount: String

    @State private var currentVideoId: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @FocusState private var isURLFieldFocused: Bool
    @State private var selectedSegment: PlayerSegment = .player
    @State private var showClearAlert = false

    var body: some View {
        ZStack {
            // Premium gradient background
            LiquidBackgroundView()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Segmented Control
                segmentedControlView
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                
                // Content based on selected segment
                if selectedSegment == .player {
                    playerContentView
                } else {
                    historyContentView
                }
            }
        }
        .overlay {
            // Repeat overlay
            if playerController.isRepeating {
                RepeatOverlayView(
                    currentCount: playerController.repeatCurrentCount,
                    totalCount: playerController.repeatTotalCount,
                    onStop: {
                        playerController.stopRepeat()
                    }
                )
                .transition(.opacity.combined(with: .scale))
            }
        }
        .overlay {
            // Confetti overlay
            if playerController.showConfetti {
                ConfettiView(isShowing: $playerController.showConfetti)
                    .allowsHitTesting(false)
            }
        }
        .alert("Invalid URL", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
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
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Image(systemName: "repeat.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text("Repetitio")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            Spacer()
            
            if selectedSegment == .history && !historyManager.items.isEmpty {
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
    }
    
    // MARK: - Segmented Control
    
    private var segmentedControlView: some View {
        Picker("Segment", selection: $selectedSegment) {
            ForEach(PlayerSegment.allCases, id: \.self) { segment in
                Text(segment.rawValue).tag(segment)
            }
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - Player Content
    
    private var playerContentView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // URL Input Card
                VStack(spacing: 16) {
                    GlassmorphicCard {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "link.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 20))

                                TextField("", text: $youtubeURL, prompt: Text("Enter YouTube URL").foregroundColor(.white.opacity(0.5)))
                                    .foregroundColor(.white)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled(true)
                                    .textFieldStyle(.plain)
                                    .focused($isURLFieldFocused)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )

                            Button(action: loadVideo) {
                                HStack(spacing: 8) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 20))
                                    Text("Load Video")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PremiumButton(color: .blue, isProminent: true))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // YouTube Video Player
                if playerController.isReady {
                    YouTubePlayerView(controller: playerController)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                        .padding(.horizontal, 20)
                } else {
                    Button {
                        isURLFieldFocused = true
                    } label: {
                        GlassmorphicCard {
                            VStack(spacing: 16) {
                                if youtubeURL.isEmpty {
                                    Image(systemName: "video.badge.plus")
                                        .font(.system(size: 50))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    Text("Enter a YouTube URL")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                } else {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                        .tint(.white)
                                    Text("Loading video...")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(!youtubeURL.isEmpty)
                    .padding(.horizontal, 20)
                }

                // Repeat Controls
                RepeatControlsView(
                    controller: playerController,
                    historyManager: historyManager,
                    currentVideoURL: youtubeURL,
                    currentVideoId: currentVideoId,
                    startTime: $startTime,
                    endTime: $endTime,
                    repeatCount: $repeatCount
                )
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    // MARK: - History Content
    
    private var historyContentView: some View {
        VideosHistoryContent(
            historyManager: historyManager,
            onLoadHistoryItem: loadHistoryItem
        )
    }
    
    private func loadHistoryItem(_ item: HistoryItem) {
        // Set the URL and time fields
        youtubeURL = item.videoURL
        startTime = item.startTimeFormatted
        endTime = item.endTimeFormatted
        repeatCount = "\(item.repeatCount)"

        // Switch to player segment
        selectedSegment = .player

        // Load the video
        playerController.isReady = false
        playerController.loadVideo(videoId: item.videoId)
        playerController.showStatus("Loading video from history...", type: .info)
    }
    
    
    private func loadVideo() {
        hideKeyboard()

        guard !youtubeURL.isEmpty else {
            alertMessage = "Please enter a YouTube URL or video ID"
            showAlert = true
            return
        }

        if let videoId = playerController.extractVideoId(from: youtubeURL) {
            currentVideoId = videoId
            playerController.isReady = false
            playerController.loadVideo(videoId: videoId)
            playerController.showStatus("Loading video...", type: .info)
        } else {
            alertMessage = "Could not extract video ID from URL. Please use a valid YouTube URL or 11-character video ID."
            showAlert = true
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    PlayerView(
        playerController: YouTubePlayerController(),
        historyManager: HistoryManager(),
        youtubeURL: .constant(""),
        startTime: .constant(""),
        endTime: .constant(""),
        repeatCount: .constant("0")
    )
}
