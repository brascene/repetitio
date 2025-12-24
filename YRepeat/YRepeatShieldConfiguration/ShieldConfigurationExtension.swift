//
//  ShieldConfigurationExtension.swift
//  YRepeatShieldConfiguration
//
//  Created by Dino Pelic on 24. 12. 2025..
//

#if DEBUG
import ManagedSettings
import ManagedSettingsUI
import UIKit

// Override the functions below to customize the shields used in various situations.
// The system provides a default appearance for any methods that your subclass doesn't override.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    // MARK: - Helper Methods

    private func createCustomShield(for appName: String?) -> ShieldConfiguration {
        // Load blocking end time from shared storage
        let timeRange = AppBlockingSharedStorage.loadTimeRange()
        let endTime = timeRange.endTime

        // Format the end time
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let endTimeString = formatter.string(from: endTime)

        // Create custom shield configuration
        return ShieldConfiguration(
            backgroundBlurStyle: .systemThickMaterial,
            backgroundColor: UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 0.95),
            icon: UIImage(systemName: "lock.shield.fill"),
            title: ShieldConfiguration.Label(
                text: "App Blocked by YRepeat",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "This app will be available again at \(endTimeString)",
                color: UIColor(white: 0.9, alpha: 0.8)
            ),
            primaryButtonLabel: nil,
            primaryButtonBackgroundColor: nil,
            secondaryButtonLabel: nil
        )
    }

    // MARK: - Shield Configuration Methods

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        // Customize the shield for applications
        return createCustomShield(for: application.localizedDisplayName)
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        // Customize the shield for applications shielded because of their category
        return createCustomShield(for: application.localizedDisplayName)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        // Customize the shield for web domains
        return createCustomShield(for: webDomain.domain)
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        // Customize the shield for web domains shielded because of their category
        return createCustomShield(for: webDomain.domain)
    }
}
#endif
