//
//  DeviceActivityMonitorExtension.swift
//  YRepeatDeviceActivityMonitor
//
//  Created by Dino Pelic on 24. 12. 2025..
//

#if DEBUG
import DeviceActivity
import ManagedSettings
import FamilyControls

// Optionally override any of the functions below.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    let store = ManagedSettingsStore()

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        // Load the whitelisted apps from shared storage
        let selectedApps = AppBlockingSharedStorage.loadSelectedApps()

        let whitelistedApps = selectedApps.applicationTokens
        let whitelistedCategories = selectedApps.categoryTokens

        // Family Controls approach for whitelisting:
        // We shield all categories, but make exceptions for whitelisted apps

        if whitelistedApps.isEmpty {
            // No apps whitelisted - shield all categories completely
            store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.all()
            store.shield.applications = nil
        } else {
            // Shield all categories but allow whitelisted apps as exceptions
            store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.all(except: whitelistedApps)

            // Don't shield individual apps - exceptions handled above
            store.shield.applications = nil
        }

        // Note: This blocks all apps by category, except the specific apps the user whitelisted
        // System apps and apps in whitelisted categories won't be fully blocked
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        // Remove all restrictions when the blocking period ends
        store.clearAllSettings()
    }
}
#endif
