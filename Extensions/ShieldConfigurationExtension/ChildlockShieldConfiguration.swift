import DeviceActivity
import FamilyControls
import ManagedSettings
import ManagedSettingsUI
import os
import UIKit

@available(iOS 17.0, *)
final class ChildlockShieldConfiguration: ShieldConfigurationDataSource {
    private let logger = Logger(subsystem: "com.kopikoubou.childlock.shield-config", category: "ShieldConfiguration")

    override init() {
        super.init()
        logger.info("ShieldConfiguration initialized")
    }

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        childlockConfiguration
    }

    override func configuration(
        shielding application: Application,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        childlockConfiguration
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        childlockConfiguration
    }

    override func configuration(
        shielding webDomain: WebDomain,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        childlockConfiguration
    }

    private var childlockConfiguration: ShieldConfiguration {
        logger.info("Building custom shield configuration")

        let shieldBg = UIColor(red: 0.106, green: 0.141, blue: 0.125, alpha: 1.0) // #1B2420
        let shieldInk = UIColor(red: 0.949, green: 0.945, blue: 0.925, alpha: 1.0) // #F2F1EC
        let forestSage = UIColor(red: 0.247, green: 0.420, blue: 0.345, alpha: 1.0) // #3F6B58

        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: shieldBg,
            icon: UIImage(systemName: "brain.head.profile"),
            title: ShieldConfiguration.Label(
                text: "Brain Break!",
                color: shieldInk
            ),
            subtitle: ShieldConfiguration.Label(
                text: "One quick puzzle, then back to your show.",
                color: shieldInk.withAlphaComponent(0.7)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Start Challenge",
                color: .white
            ),
            primaryButtonBackgroundColor: forestSage,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Ask Parent",
                color: shieldInk
            )
        )
    }
}
