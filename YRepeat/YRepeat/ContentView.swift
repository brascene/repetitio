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
    case calendar = 2
    case habits = 3
}

struct ContentView: View {
    @StateObject private var playerController = YouTubePlayerController()
    @StateObject private var historyManager = HistoryManager()
    @StateObject private var dailyRepeatManager = DailyRepeatManager()
    @StateObject private var calendarManager = CalendarManager()
    @StateObject private var habitManager = HabitManager()

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
                
                CalendarView()
                    .environmentObject(calendarManager)
                    .tabItem {
                        Label("Calendar", systemImage: "calendar")
                    }
                    .tag(Tab.calendar)
                
                HabitView()
                    .environmentObject(habitManager)
                    .tabItem {
                        Label("Habits", systemImage: "heart.fill")
                    }
                    .tag(Tab.habits)
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
