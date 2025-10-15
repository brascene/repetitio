//
//  RepeatControlsView.swift
//  YRepeat
//
//  Created by Dino Pelic on 15. 10. 2025..
//

import SwiftUI

// UI matching the extension's popup.html
struct RepeatControlsView: View {
    @ObservedObject var controller: YouTubePlayerController
    @ObservedObject var historyManager: HistoryManager
    var currentVideoURL: String
    var currentVideoId: String

    @Binding var startTime: String
    @Binding var endTime: String
    @Binding var repeatCount: String

    var body: some View {
        VStack(spacing: 20) {
            // Time Controls Card
            GlassmorphicCard {
                VStack(alignment: .leading, spacing: 20) {
                    // Section Header
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                        Text("Time Range")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    // Start Time
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Start Time")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))

                        HStack(spacing: 12) {
                            TextField("", text: $startTime, prompt: Text("0:00").foregroundColor(.white.opacity(0.5)))
                                .foregroundColor(.white)
                                .keyboardType(.numbersAndPunctuation)
                                .textFieldStyle(.plain)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )

                            Button(action: useCurrentTime) {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 20))
                            }
                            .buttonStyle(PremiumButton(color: .purple, isProminent: false))
                            .padding(.horizontal, 4)
                        }

                        Text("MM:SS or seconds (e.g., 1:30 or 90)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }

                    // End Time
                    VStack(alignment: .leading, spacing: 10) {
                        Text("End Time")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))

                        TextField("", text: $endTime, prompt: Text("0:10").foregroundColor(.white.opacity(0.5)))
                            .foregroundColor(.white)
                            .keyboardType(.numbersAndPunctuation)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )

                        Text("Scrub video to find end time")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }

                    // Repeat Count
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Repeat Count")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))

                        TextField("", text: $repeatCount, prompt: Text("0 (infinite)").foregroundColor(.white.opacity(0.5)))
                            .foregroundColor(.white)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )

                        Text("Set to 0 for infinite loop")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }

            // Video Info Card
            GlassmorphicCard {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Video Info")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                    }

                    HStack {
                        Text("Current")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                        Text(TimeHelpers.secondsToTime(controller.currentTime))
                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(10)

                    HStack {
                        Text("Duration")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                        Text(TimeHelpers.secondsToTime(controller.duration))
                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                            .foregroundColor(.purple)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(10)
                }
            }

            // Status
            if !controller.statusMessage.isEmpty && controller.statusMessage != "Ready to start" {
                PremiumStatusView(message: controller.statusMessage, type: controller.statusType)
            }

            // Action Buttons Card
            GlassmorphicCard {
                VStack(spacing: 12) {
                    // Start/Stop Buttons
                    HStack(spacing: 12) {
                        Button(action: startRepeat) {
                            HStack(spacing: 8) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 20))
                                Text("Start Repeat")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PremiumButton(color: .blue, isProminent: true))

                        Button(action: stopRepeat) {
                            HStack(spacing: 8) {
                                Image(systemName: "stop.circle.fill")
                                    .font(.system(size: 20))
                                Text("Stop")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PremiumButton(color: .red, isProminent: false))
                    }

                    // Save Button
                    Button(action: saveToHistory) {
                        HStack(spacing: 8) {
                            Image(systemName: "bookmark.fill")
                                .font(.system(size: 18))
                            Text("Save to History")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PremiumButton(color: .green, isProminent: false))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    // Use current video time as start time
    private func useCurrentTime() {
        startTime = TimeHelpers.secondsToTime(controller.currentTime)
        controller.showStatus("Start time set to \(startTime)", type: .success)
    }

    // Start repeat functionality (similar to popup.js:99)
    private func startRepeat() {
        let start = TimeHelpers.timeToSeconds(startTime)
        let end = TimeHelpers.timeToSeconds(endTime)
        let count = Int(repeatCount) ?? 0

        controller.startRepeat(startTime: start, endTime: end, repeatCount: count)
    }

    // Stop repeat functionality
    private func stopRepeat() {
        controller.stopRepeat()
    }

    // Save to history
    private func saveToHistory() {
        let start = TimeHelpers.timeToSeconds(startTime)
        let end = TimeHelpers.timeToSeconds(endTime)
        let count = Int(repeatCount) ?? 0

        guard !currentVideoURL.isEmpty && !currentVideoId.isEmpty else {
            controller.showStatus("No video loaded", type: .error)
            return
        }

        guard end > start else {
            controller.showStatus("Invalid time range", type: .error)
            return
        }

        historyManager.saveItem(
            videoURL: currentVideoURL,
            videoId: currentVideoId,
            startTime: start,
            endTime: end,
            repeatCount: count
        )

        controller.showStatus("Saved to history!", type: .success)
    }
}

// Premium status view
struct PremiumStatusView: View {
    let message: String
    let type: YouTubePlayerController.StatusType

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 20))
                .foregroundColor(iconColor)

            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            ZStack {
                VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)

                LinearGradient(
                    gradient: Gradient(colors: [
                        backgroundColor.opacity(0.3),
                        backgroundColor.opacity(0.1)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        )
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(backgroundColor.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: backgroundColor.opacity(0.2), radius: 8, x: 0, y: 4)
    }

    private var iconName: String {
        switch type {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        case .info:
            return "info.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        }
    }

    private var iconColor: Color {
        switch type {
        case .success:
            return .green
        case .error:
            return .red
        case .info:
            return .blue
        case .warning:
            return .orange
        }
    }

    private var backgroundColor: Color {
        switch type {
        case .success:
            return .green
        case .error:
            return .red
        case .info:
            return .blue
        case .warning:
            return .orange
        }
    }
}

#Preview {
    RepeatControlsView(
        controller: YouTubePlayerController(),
        historyManager: HistoryManager(),
        currentVideoURL: "",
        currentVideoId: "",
        startTime: .constant(""),
        endTime: .constant(""),
        repeatCount: .constant("0")
    )
}
