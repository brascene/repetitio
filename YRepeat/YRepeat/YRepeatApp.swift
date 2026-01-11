//
//  YRepeatApp.swift
//  YRepeat
//
//  Created by Dino Pelic on 15. 10. 2025..
//

import SwiftUI
internal import CoreData
import FirebaseCore
import FirebaseCrashlytics

@main
struct YRepeatApp: App {
    @StateObject private var dataController = PersistenceController()
    @StateObject private var themeManager = ThemeManager()
    #if DEBUG
    @StateObject private var appBlockingManager = AppBlockingManager()
    #endif

    init() {
        // Configure Firebase
        FirebaseApp.configure()

        // Enable Crashlytics collection (even in debug builds for testing)
        #if DEBUG
        // For testing Crashlytics during development
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        #endif

        // Migrate data from UserDefaults to Core Data on app launch
        DataMigrationManager.shared.migrateDataIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(themeManager)
                .environmentObject(appBlockingManager)
            #else
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(themeManager)
            #endif
        }
    }
}
