//
//  AppBlockingManager.swift
//  YRepeat
//
//  Created for App Blocking feature
//

#if DEBUG
import Foundation
import Combine
import FamilyControls
import ManagedSettings
import DeviceActivity
internal import CoreData

class AppBlockingManager: ObservableObject {
    @Published var isAuthorized: Bool = false
    @Published var isBlockingEnabled: Bool = false
    @Published var selectedApps: FamilyActivitySelection = FamilyActivitySelection()
    @Published var startTime: Date
    @Published var endTime: Date

    private let authCenter = AuthorizationCenter.shared
    private let store = ManagedSettingsStore()
    private let persistenceController: PersistenceController
    private let context: NSManagedObjectContext

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        self.context = persistenceController.container.viewContext

        // Set default times: 9 PM - 6 AM
        let calendar = Calendar.current
        self.startTime = calendar.date(from: DateComponents(hour: 21, minute: 0))!
        self.endTime = calendar.date(from: DateComponents(hour: 6, minute: 0))!

        loadSettings()
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        do {
            try await authCenter.requestAuthorization(for: .individual)
            await MainActor.run {
                self.isAuthorized = true
                saveSettings()
            }
        } catch {
            await MainActor.run {
                print("Family Controls authorization failed: \(error)")
            }
        }
    }

    func checkAuthorizationStatus() {
        Task {
            let status = authCenter.authorizationStatus
            await MainActor.run {
                isAuthorized = (status == .approved)
            }
        }
    }

    // MARK: - Scheduling

    func applySchedule() {
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)

        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: true
        )

        let center = DeviceActivityCenter()
        do {
            try center.startMonitoring(
                DeviceActivityName("appBlocking"),
                during: schedule
            )
            isBlockingEnabled = true
            saveSettings()

            // Apply immediate restrictions if we're in the blocking window
            applyRestrictions()
        } catch {
            print("Failed to schedule device activity: \(error)")
        }
    }

    func removeSchedule() {
        let center = DeviceActivityCenter()
        center.stopMonitoring([DeviceActivityName("appBlocking")])

        // Clear all restrictions
        store.clearAllSettings()

        isBlockingEnabled = false
        saveSettings()
    }

    // MARK: - Restrictions

    func applyRestrictions() {
        // The restrictions will be applied by the DeviceActivityMonitor extension
        // This method is here for immediate application when schedule is activated
        // Note: In practice, the extension handles this automatically
    }

    // MARK: - Persistence

    func loadSettings() {
        let fetchRequest = NSFetchRequest<AppBlockingScheduleEntity>(entityName: "AppBlockingScheduleEntity")
        fetchRequest.fetchLimit = 1

        guard let entity = try? context.fetch(fetchRequest).first else {
            return
        }

        isBlockingEnabled = entity.isEnabled
        startTime = entity.startTime ?? Calendar.current.date(from: DateComponents(hour: 21, minute: 0))!
        endTime = entity.endTime ?? Calendar.current.date(from: DateComponents(hour: 6, minute: 0))!

        if let data = entity.selectedAppsData {
            do {
                let decoder = JSONDecoder()
                selectedApps = try decoder.decode(FamilyActivitySelection.self, from: data)
            } catch {
                print("Failed to decode selected apps: \(error)")
            }
        }
    }

    func saveSettings() {
        let fetchRequest = NSFetchRequest<AppBlockingScheduleEntity>(entityName: "AppBlockingScheduleEntity")
        fetchRequest.fetchLimit = 1

        let entity = (try? context.fetch(fetchRequest).first) ?? AppBlockingScheduleEntity(context: context)

        entity.id = entity.id ?? UUID()
        entity.isEnabled = isBlockingEnabled
        entity.startTime = startTime
        entity.endTime = endTime
        entity.updatedAt = Date()

        if entity.createdAt == nil {
            entity.createdAt = Date()
        }

        // Serialize FamilyActivitySelection
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(selectedApps)
            entity.selectedAppsData = data
        } catch {
            print("Failed to encode selected apps: \(error)")
        }

        do {
            try context.save()
        } catch {
            print("Failed to save app blocking settings: \(error)")
        }

        // Also save to shared storage for extension access
        AppBlockingSharedStorage.saveSelectedApps(selectedApps)
        AppBlockingSharedStorage.saveTimeRange(startTime: startTime, endTime: endTime)
    }
}

#else
// Stub implementation for Release builds
import Foundation
import Combine

class AppBlockingManager: ObservableObject {
    @Published var isAuthorized: Bool = false
    @Published var isBlockingEnabled: Bool = false

    init() {}
}
#endif
