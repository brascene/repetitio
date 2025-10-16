//
//  YRepeatApp.swift
//  YRepeat
//
//  Created by Dino Pelic on 15. 10. 2025..
//

import SwiftUI
internal import CoreData

@main
struct YRepeatApp: App {
    @StateObject private var dataController = PersistenceController()
    
    init() {
        // Migrate data from UserDefaults to Core Data on app launch
        DataMigrationManager.shared.migrateDataIfNeeded()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
        }
    }
}
