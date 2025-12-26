//
//  YRepeatApp.swift
//  YRepeat
//
//  Created by Dino Pelic on 15. 10. 2025..
//

import SwiftUI
internal import CoreData
import FirebaseCore

// AppDelegate for Firebase initialization
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct YRepeatApp: App {
    // Register AppDelegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var dataController = PersistenceController()
    @StateObject private var themeManager = ThemeManager()
    #if DEBUG
    @StateObject private var appBlockingManager = AppBlockingManager()
    #endif

    init() {
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
