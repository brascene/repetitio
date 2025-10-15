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
    @StateObject private var dailyRepeatManager = DailyRepeatManager()

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

            // Daily Repeat Tab
            DailyRepeatView()
                .environmentObject(dailyRepeatManager)
            .tabItem {
                Label("Daily", systemImage: "repeat.circle.fill")
            }
            .tag(1)

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
            .tag(2)
        }
    }
}

#Preview {
    ContentView()
}
