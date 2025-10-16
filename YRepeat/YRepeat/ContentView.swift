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
        ZStack {
            // Content Views
            Group {
                if selectedTab == 0 {
                    PlayerView(
                        playerController: playerController,
                        historyManager: historyManager,
                        youtubeURL: $youtubeURL,
                        startTime: $startTime,
                        endTime: $endTime,
                        repeatCount: $repeatCount
                    )
                } else if selectedTab == 1 {
                    DailyRepeatView()
                        .environmentObject(dailyRepeatManager)
                } else {
                    HistoryView(
                        historyManager: historyManager,
                        playerController: playerController,
                        selectedTab: $selectedTab,
                        youtubeURL: $youtubeURL,
                        startTime: $startTime,
                        endTime: $endTime,
                        repeatCount: $repeatCount
                    )
                    .environmentObject(dailyRepeatManager)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: selectedTab)
            
            VStack {
                Spacer()
                
                // Custom Tab Bar
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
    }
}

#Preview {
    ContentView()
}
