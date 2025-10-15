//
//  YouTubePlayerController.swift
//  YRepeat
//
//  Created by Dino Pelic on 15. 10. 2025..
//

import Foundation
import WebKit
import Combine
import SwiftUI

struct RepeatConfig {
    var enabled: Bool = true
    var startTime: Double
    var endTime: Double
    var repeatCount: Int
    var currentCount: Int
}

class YouTubePlayerController: NSObject, ObservableObject {
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isReady: Bool = false
    @Published var statusMessage: String = "Ready to start"
    @Published var statusType: StatusType = .info
    @Published var isRepeating: Bool = false
    @Published var repeatCurrentCount: Int = 0
    @Published var repeatTotalCount: Int = 0
    @Published var showConfetti: Bool = false

    var webView: WKWebView?
    private var repeatConfig: RepeatConfig?
    private var timer: Timer?
    private var hasLooped: Bool = false

    enum StatusType {
        case success, error, info, warning
    }

    override init() {
        super.init()
        setupWebView()
    }

    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        webView = WKWebView(frame: .zero, configuration: configuration)
        webView?.navigationDelegate = self

        // Set up message handler for JavaScript communication
        configuration.userContentController.add(self, name: "iosListener")
    }

    // Load a YouTube video by video ID
    func loadVideo(videoId: String) {
        guard let webView = webView else { return }

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                * { margin: 0; padding: 0; }
                body { background: #000; }
                #player { width: 100%; height: 100%; }
            </style>
        </head>
        <body>
            <div id="player"></div>
            <script>
                var tag = document.createElement('script');
                tag.src = "https://www.youtube.com/iframe_api";
                var firstScriptTag = document.getElementsByTagName('script')[0];
                firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

                var player;
                function onYouTubeIframeAPIReady() {
                    player = new YT.Player('player', {
                        height: '100%',
                        width: '100%',
                        videoId: '\(videoId)',
                        playerVars: {
                            'playsinline': 1,
                            'controls': 1,
                            'rel': 0,
                            'modestbranding': 1
                        },
                        events: {
                            'onReady': onPlayerReady,
                            'onStateChange': onPlayerStateChange
                        }
                    });
                }

                function onPlayerReady(event) {
                    window.webkit.messageHandlers.iosListener.postMessage({
                        type: 'ready',
                        duration: player.getDuration()
                    });

                    // Start sending time updates
                    setInterval(function() {
                        if (player && player.getCurrentTime) {
                            window.webkit.messageHandlers.iosListener.postMessage({
                                type: 'timeUpdate',
                                currentTime: player.getCurrentTime(),
                                duration: player.getDuration()
                            });
                        }
                    }, 500);
                }

                function onPlayerStateChange(event) {
                    window.webkit.messageHandlers.iosListener.postMessage({
                        type: 'stateChange',
                        state: event.data
                    });
                }

                function getCurrentTime() {
                    return player.getCurrentTime();
                }

                function getDuration() {
                    return player.getDuration();
                }

                function seekTo(seconds) {
                    player.seekTo(seconds, true);
                }

                function playVideo() {
                    player.playVideo();
                }

                function pauseVideo() {
                    player.pauseVideo();
                }
            </script>
        </body>
        </html>
        """

        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com"))
    }

    // Extract video ID from YouTube URL
    func extractVideoId(from url: String) -> String? {
        // Handle youtu.be format
        if url.contains("youtu.be/") {
            let components = url.components(separatedBy: "youtu.be/")
            if components.count > 1 {
                let videoId = components[1].components(separatedBy: "?")[0]
                return videoId
            }
        }

        // Handle youtube.com/watch?v= format
        if url.contains("youtube.com/watch") {
            let components = URLComponents(string: url)
            return components?.queryItems?.first(where: { $0.name == "v" })?.value
        }

        // If it's just a video ID (11 characters)
        if url.count == 11 && !url.contains("/") {
            return url
        }

        return nil
    }

    // Start repeat functionality (similar to content.js:422)
    func startRepeat(startTime: Double, endTime: Double, repeatCount: Int) {
        // Validate
        guard endTime > startTime else {
            showStatus("End time must be greater than start time", type: .error)
            return
        }

        guard endTime > 0 else {
            showStatus("Please set an end time", type: .error)
            return
        }

        repeatConfig = RepeatConfig(
            enabled: true,
            startTime: startTime,
            endTime: endTime,
            repeatCount: repeatCount,
            currentCount: 0
        )

        hasLooped = false

        // Show overlay
        isRepeating = true
        repeatCurrentCount = 0
        repeatTotalCount = repeatCount
        showConfetti = false

        // Seek to start time and play
        seekTo(startTime)
        evaluateJavaScript("playVideo()")

        // Set up timer to check for repeat loop (similar to content.js:392)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.checkRepeatLoop()
        }

        let countText = repeatCount == 0 ? "infinite" : "\(repeatCount) times"
        showStatus("Repeat started (\(countText))", type: .success)
    }

    // Stop repeat functionality (similar to content.js:439)
    func stopRepeat() {
        timer?.invalidate()
        timer = nil
        repeatConfig?.enabled = false
        repeatConfig?.currentCount = 0

        // Pause the video
        evaluateJavaScript("pauseVideo()")

        // Hide overlay with animation
        withAnimation(.easeOut(duration: 0.3)) {
            isRepeating = false
        }

        showStatus("Repeat stopped", type: .info)
    }

    // Check if we need to loop back (similar to content.js:392)
    private func checkRepeatLoop() {
        guard let config = repeatConfig, config.enabled else { return }

        let currentTime = self.currentTime

        // Check if we've reached the end time
        if currentTime >= config.endTime {
            // Prevent multiple increments during the same loop
            if hasLooped {
                return
            }
            hasLooped = true

            repeatConfig?.currentCount += 1

            // Update overlay count
            DispatchQueue.main.async {
                self.repeatCurrentCount = self.repeatConfig?.currentCount ?? 0
            }

            // Check if we've completed all repeats
            if config.repeatCount > 0 && (repeatConfig?.currentCount ?? 0) >= config.repeatCount {
                // Show confetti
                DispatchQueue.main.async {
                    self.showConfetti = true
                }

                // Wait a bit for confetti, then stop
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.stopRepeat()
                    self.evaluateJavaScript("pauseVideo()")
                    self.showStatus("Repeat completed - video paused", type: .success)
                }
            } else {
                // Loop back to start time
                seekTo(config.startTime)
                let countText = config.repeatCount > 0 ? "/\(config.repeatCount)" : ""
                showStatus("Repeat \(repeatConfig?.currentCount ?? 0)\(countText)", type: .success)
            }
        } else if currentTime < config.endTime - 1.0 {
            // Reset the flag when we're back in the safe zone (at least 1 second before end)
            hasLooped = false
        }
    }

    // Seek to a specific time
    func seekTo(_ seconds: Double) {
        evaluateJavaScript("seekTo(\(seconds))")
    }

    // Show status message
    func showStatus(_ message: String, type: StatusType) {
        DispatchQueue.main.async {
            self.statusMessage = message
            self.statusType = type
        }
    }

    // Helper to evaluate JavaScript
    private func evaluateJavaScript(_ script: String) {
        webView?.evaluateJavaScript(script, completionHandler: nil)
    }
}

// MARK: - WKNavigationDelegate
extension YouTubePlayerController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("WebView loaded")
    }
}

// MARK: - WKScriptMessageHandler
extension YouTubePlayerController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let dict = message.body as? [String: Any],
              let type = dict["type"] as? String else { return }

        switch type {
        case "ready":
            if let duration = dict["duration"] as? Double {
                DispatchQueue.main.async {
                    self.duration = duration
                    self.isReady = true
                }
            }

        case "timeUpdate":
            if let currentTime = dict["currentTime"] as? Double {
                DispatchQueue.main.async {
                    self.currentTime = currentTime
                }
            }
            if let duration = dict["duration"] as? Double {
                DispatchQueue.main.async {
                    self.duration = duration
                }
            }

        case "stateChange":
            // Handle player state changes if needed
            break

        default:
            break
        }
    }
}
