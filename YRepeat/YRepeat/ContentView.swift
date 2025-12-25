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
    case fast = 4
    case settings = 5
}

struct ContentView: View {
    @StateObject private var playerController = YouTubePlayerController()
    @StateObject private var historyManager = HistoryManager()
    @StateObject private var dailyRepeatManager = DailyRepeatManager()
    @StateObject private var calendarManager = CalendarManager()
    @StateObject private var habitManager = HabitManager()
    @StateObject private var exerciseManager = ExerciseManager()

    @State private var youtubeURL: String = ""
    @SceneStorage("selectedTab") private var selectedTab: Tab = .player
    @AppStorage("showPlayerTab") private var showPlayerTab = true
    @AppStorage("showFastTab") private var showFastTab = true
    @State private var startTime: String = ""
    @State private var endTime: String = ""
    @State private var repeatCount: String = "0"

    var body: some View {
        if #available(iOS 26.0, *) {
            TabView(selection: $selectedTab) {
                if showPlayerTab {
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
                }
                
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
                
                if showFastTab {
                    HealthView()
                        .environmentObject(exerciseManager)
                        .tabItem {
                            Label("Health", systemImage: "waveform.path.ecg")
                        }
                        .tag(Tab.fast)
                }
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(Tab.settings)
            }
            // Enable tab bar minimization on scroll (iOS 26 feature)
            .tabBarMinimizeBehavior(.onScrollDown)
            .onAppear {
                // If Player tab is hidden and Player is selected, switch to Daily tab
                if !showPlayerTab && selectedTab == .player {
                    selectedTab = .daily
                }
                // If Fast tab is hidden and Fast is selected, switch to Daily tab
                if !showFastTab && selectedTab == .fast {
                    selectedTab = .daily
                }
            }
            .onChange(of: showPlayerTab) { oldValue, newValue in
                // If Player tab is hidden and it was selected, switch to Daily tab
                if !newValue && selectedTab == .player {
                    selectedTab = .daily
                }
            }
            .onChange(of: showFastTab) { oldValue, newValue in
                // If Fast tab is hidden and it was selected, switch to Daily tab
                if !newValue && selectedTab == .fast {
                    selectedTab = .daily
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
}

#Preview {
    ContentView()
}
