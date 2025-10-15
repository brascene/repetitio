//
//  ContentView.swift
//  YRepeat
//
//  Created by Dino Pelic on 15. 10. 2025..
//

import SwiftUI

struct ContentView: View {
    @StateObject private var playerController = YouTubePlayerController()
    @StateObject private var historyManager = HistoryManager()

    @State private var youtubeURL: String = ""
    @State private var selectedTab: Int = 0
    @State private var startTime: String = ""
    @State private var endTime: String = ""
    @State private var repeatCount: String = "0"

    var body: some View {
        TabView(selection: $selectedTab) {
            // Player Tab
            PlayerView(
                playerController: playerController,
                historyManager: historyManager,
                youtubeURL: $youtubeURL,
                startTime: $startTime,
                endTime: $endTime,
                repeatCount: $repeatCount
            )
            .tabItem {
                Label("Player", systemImage: "play.rectangle.fill")
            }
            .tag(0)

            // History Tab
            HistoryView(
                historyManager: historyManager,
                playerController: playerController,
                selectedTab: $selectedTab,
                youtubeURL: $youtubeURL,
                startTime: $startTime,
                endTime: $endTime,
                repeatCount: $repeatCount
            )
            .tabItem {
                Label("History", systemImage: "clock.fill")
            }
            .tag(1)
        }
    }
}

#Preview {
    ContentView()
}
