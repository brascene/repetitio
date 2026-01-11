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
    case xo = 7
    case settings = 8
}

struct ContentView: View {
    @StateObject private var playerController = YouTubePlayerController()
    @StateObject private var historyManager = HistoryManager()
    @StateObject private var dailyRepeatManager = DailyRepeatManager()
    @StateObject private var calendarManager = CalendarManager()
    @StateObject private var habitManager = HabitManager()
    @StateObject private var authenticationManager = AuthenticationManager()
    @StateObject private var themeManager = ThemeManager()

    @Environment(\.managedObjectContext) private var viewContext

    // Initialize ExerciseManager with context - done in init
    @StateObject private var exerciseManager: ExerciseManager

    init() {
        // Initialize ExerciseManager with context
        let context = PersistenceController.shared.container.viewContext
        _exerciseManager = StateObject(wrappedValue: ExerciseManager(context: context))
    }

    @State private var youtubeURL: String = ""
    @SceneStorage("selectedTab") private var selectedTab: Tab = .daily
    @State private var isMenuShowing = false
    @AppStorage("showPlayerTab") private var showPlayerTab = true
    @AppStorage("showFastTab") private var showFastTab = true
    @AppStorage("showHabitsTab") private var showHabitsTab = true
    @AppStorage("showCheckTab") private var showCheckTab = true
    @AppStorage("showDiceTab") private var showDiceTab = true
    @AppStorage("showXOTab") private var showXOTab = false
    @AppStorage("use3DDice") private var use3DDice = false
    @State private var startTime: String = ""
    @State private var endTime: String = ""
    @State private var repeatCount: String = "0"
    @State private var dragProgress: CGFloat = 0 // 0 = closed, 1 = fully open

    // FirebaseSyncManager initialized with context
    @StateObject private var firebaseSyncManager = FirebaseSyncManager(context: PersistenceController.shared.container.viewContext)

    var body: some View {
        let _ = setupDailyRepeatFirebaseSync()

        if #available(iOS 26.0, *) {
            ZStack {
                // Main content - stays static
                ZStack {
                    // Main TabView with core tabs only
                    TabView(selection: $selectedTab) {
                        DailyRepeatView(isMenuShowing: $isMenuShowing)
                            .environmentObject(dailyRepeatManager)
                            .environmentObject(themeManager)
                            .tabItem {
                                Label("Daily", systemImage: "repeat.circle.fill")
                            }
                            .tag(Tab.daily)

                        CalendarView(isMenuShowing: $isMenuShowing)
                            .environmentObject(calendarManager)
                            .environmentObject(themeManager)
                            .tabItem {
                                Label("Calendar", systemImage: "calendar")
                            }
                            .tag(Tab.calendar)

                        HealthView(isMenuShowing: $isMenuShowing)
                            .environmentObject(exerciseManager)
                            .environmentObject(themeManager)
                            .tabItem {
                                Label("Health", systemImage: "waveform.path.ecg")
                            }
                            .tag(Tab.fast)

                        CheckView(isMenuShowing: $isMenuShowing)
                            .environmentObject(themeManager)
                            .tabItem {
                                Label("Check", systemImage: "checkmark.square.fill")
                            }
                            .tag(Tab.check)
                    }
                    // Enable tab bar minimization on scroll (iOS 26 feature)
                    .tabBarMinimizeBehavior(.onScrollDown)

                    // Content for menu-only screens
                    Group {
                        if selectedTab == .player {
                            PlayerView(
                                playerController: playerController,
                                historyManager: historyManager,
                                youtubeURL: $youtubeURL,
                                startTime: $startTime,
                                endTime: $endTime,
                                repeatCount: $repeatCount,
                                isMenuShowing: $isMenuShowing
                            )
                            .environmentObject(themeManager)
                        } else if selectedTab == .habits {
                            HabitView(isMenuShowing: $isMenuShowing)
                                .environmentObject(habitManager)
                                .environmentObject(themeManager)
                        } else if selectedTab == .dice {
                            if use3DDice {
                                Enhanced3DDiceView(isMenuShowing: $isMenuShowing)
                                    .environmentObject(themeManager)
                            } else {
                                DiceView(isMenuShowing: $isMenuShowing)
                                    .environmentObject(themeManager)
                            }
                        } else if selectedTab == .xo {
                            XOView(isMenuShowing: $isMenuShowing)
                                .environmentObject(themeManager)
                        } else if selectedTab == .settings {
                            SettingsView(isMenuShowing: $isMenuShowing)
                                .environmentObject(authenticationManager)
                                .environmentObject(firebaseSyncManager)
                                .environmentObject(themeManager)
                        }
                    }
                }

                // Left edge swipe detector (transparent area)
                if !isMenuShowing {
                    Rectangle()
                        .fill(Color.white.opacity(0.001))
                        .frame(width: 30)
                        .frame(maxHeight: .infinity)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .gesture(
                            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                                .onChanged { value in
                                    let translation = max(0, value.translation.width)
                                    let menuWidth: CGFloat = 280
                                    dragProgress = min(1, translation / menuWidth)
                                }
                                .onEnded { value in
                                    let velocity = value.predictedEndTranslation.width - value.translation.width

                                    if dragProgress > 0.3 || velocity > 200 {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            isMenuShowing = true
                                            dragProgress = 1
                                        }
                                    } else {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                            dragProgress = 0
                                        }
                                    }
                                }
                        )
                        .zIndex(999)
                }

                // Side Menu Overlay - slides over content
                SideMenuView(isShowing: $isMenuShowing, selectedTab: $selectedTab, dragProgress: $dragProgress)
                    .environmentObject(themeManager)
                    .zIndex(1000)
                    .onChange(of: isMenuShowing) { oldValue, newValue in
                        // Sync dragProgress with menu state
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            dragProgress = newValue ? 1 : 0
                        }
                    }
                    .simultaneousGesture(
                        // Drag to close gesture on menu
                        DragGesture(minimumDistance: 0, coordinateSpace: .global)
                            .onChanged { value in
                                if isMenuShowing {
                                    let translation = value.translation.width
                                    let menuWidth: CGFloat = 280
                                    let progress = max(0, min(1, 1 + (translation / menuWidth)))
                                    dragProgress = progress
                                }
                            }
                            .onEnded { value in
                                if isMenuShowing {
                                    let velocity = value.predictedEndTranslation.width - value.translation.width

                                    if dragProgress < 0.5 || velocity < -50 {
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                            isMenuShowing = false
                                            dragProgress = 0
                                        }
                                    } else {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            dragProgress = 1
                                        }
                                    }
                                }
                            }
                    )
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
