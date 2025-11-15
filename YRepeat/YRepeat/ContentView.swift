//
//  ContentView.swift
//  YRepeat
//
//  Created by Dino Pelic on 15. 10. 2025..
//

import SwiftUI

enum Tab: Int, Hashable {
    case player = 0
    case daily = 1
    case history = 2
}

struct ContentView: View {
    @StateObject private var playerController = YouTubePlayerController()
    @StateObject private var historyManager = HistoryManager()
    @StateObject private var dailyRepeatManager = DailyRepeatManager()

    @State private var youtubeURL: String = ""
    @SceneStorage("selectedTab") private var selectedTab: Tab = .player
    @State private var startTime: String = ""
    @State private var endTime: String = ""
    @State private var repeatCount: String = "0"

    var body: some View {
        if #available(iOS 26.0, *) {
            TabView(selection: $selectedTab) {
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
                .tag(Tab.player)
                
                DailyRepeatView()
                    .environmentObject(dailyRepeatManager)
                    .tabItem {
                        Label("Daily", systemImage: "repeat.circle.fill")
                    }
                    .tag(Tab.daily)
                
                HistoryView(
                    historyManager: historyManager,
                    playerController: playerController,
                    selectedTab: Binding(
                        get: { selectedTab.rawValue },
                        set: { selectedTab = Tab(rawValue: $0) ?? .player }
                    ),
                    youtubeURL: $youtubeURL,
                    startTime: $startTime,
                    endTime: $endTime,
                    repeatCount: $repeatCount
                )
                .environmentObject(dailyRepeatManager)
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(Tab.history)
            }
            // Enable tab bar minimization on scroll (iOS 26 feature)
            .tabBarMinimizeBehavior(.onScrollDown)
        } else {
            // Fallback on earlier versions
        }
    }
}

#Preview {
    ContentView()
}
