//
//  ContentView.swift
//  YRepeat
//
//  Created by Dino Pelic on 15. 10. 2025..
//

import SwiftUI
internal import CoreData

enum Tab: Int, Hashable {
    case player = 0
    case daily = 1
    case calendar = 2
    case habits = 3
    case fast = 4
    case check = 5
    case dice = 6
    case settings = 7
}

struct ContentView: View {
    @StateObject private var playerController = YouTubePlayerController()
    @StateObject private var historyManager = HistoryManager()
    @StateObject private var dailyRepeatManager = DailyRepeatManager()
    @StateObject private var calendarManager = CalendarManager()
    @StateObject private var habitManager = HabitManager()
    @StateObject private var exerciseManager = ExerciseManager()
    @StateObject private var authenticationManager = AuthenticationManager()
    @StateObject private var themeManager = ThemeManager()

    @Environment(\.managedObjectContext) private var viewContext

    @State private var youtubeURL: String = ""
    @SceneStorage("selectedTab") private var selectedTab: Tab = .player
    @AppStorage("showPlayerTab") private var showPlayerTab = true
    @AppStorage("showFastTab") private var showFastTab = true
    @AppStorage("showHabitsTab") private var showHabitsTab = true
    @AppStorage("showCheckTab") private var showCheckTab = true
    @AppStorage("showDiceTab") private var showDiceTab = true
    @AppStorage("use3DDice") private var use3DDice = false
    @State private var startTime: String = ""
    @State private var endTime: String = ""
    @State private var repeatCount: String = "0"

    // FirebaseSyncManager initialized with context
    @StateObject private var firebaseSyncManager = FirebaseSyncManager(context: PersistenceController.shared.container.viewContext)

    var body: some View {
        let _ = setupDailyRepeatFirebaseSync()

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

                if showHabitsTab {
                    HabitView()
                        .environmentObject(habitManager)
                        .tabItem {
                            Label("Habits", systemImage: "heart.fill")
                        }
                        .tag(Tab.habits)
                }

                if showFastTab {
                    HealthView()
                        .environmentObject(exerciseManager)
                        .tabItem {
                            Label("Health", systemImage: "waveform.path.ecg")
                        }
                        .tag(Tab.fast)
                }

                if showCheckTab {
                    CheckView()
                        .environmentObject(themeManager)
                        .tabItem {
                            Label("Check", systemImage: "checkmark.square.fill")
                        }
                        .tag(Tab.check)
                }

                if showDiceTab {
                    if use3DDice {
                        Enhanced3DDiceView()
                            .environmentObject(themeManager)
                            .tabItem {
                                Label("Dice", systemImage: "cube.fill")
                            }
                            .tag(Tab.dice)
                    } else {
                        DiceView()
                            .environmentObject(themeManager)
                            .tabItem {
                                Label("Dice", systemImage: "die.face.5.fill")
                            }
                            .tag(Tab.dice)
                    }
                }

                SettingsView()
                    .environmentObject(authenticationManager)
                    .environmentObject(firebaseSyncManager)
                    .environmentObject(themeManager)
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
                // If Habits tab is hidden and Habits is selected, switch to Daily tab
                if !showHabitsTab && selectedTab == .habits {
                    selectedTab = .daily
                }
                // If Check tab is hidden and Check is selected, switch to Daily tab
                if !showCheckTab && selectedTab == .check {
                    selectedTab = .daily
                }
                // If Dice tab is hidden and Dice is selected, switch to Daily tab
                if !showDiceTab && selectedTab == .dice {
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
            .onChange(of: showHabitsTab) { oldValue, newValue in
                // If Habits tab is hidden and it was selected, switch to Daily tab
                if !newValue && selectedTab == .habits {
                    selectedTab = .daily
                }
            }
            .onChange(of: showCheckTab) { oldValue, newValue in
                // If Check tab is hidden and it was selected, switch to Daily tab
                if !newValue && selectedTab == .check {
                    selectedTab = .daily
                }
            }
            .onChange(of: showDiceTab) { oldValue, newValue in
                // If Dice tab is hidden and it was selected, switch to Daily tab
                if !newValue && selectedTab == .dice {
                    selectedTab = .daily
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }

    // MARK: - Helper Functions

    private func setupDailyRepeatFirebaseSync() {
        // Wire up FirebaseSyncManager to DailyRepeatManager for daily reset sync
        dailyRepeatManager.firebaseSyncManager = firebaseSyncManager
    }
}

#Preview {
    ContentView()
}
