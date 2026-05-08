import DeviceActivity
import FamilyControls
import ManagedSettings
import os

@available(iOS 17.0, *)
final class ChildlockShieldConfiguration: ShieldConfigurationDataSource {
    private let logger = Logger(subsystem: "com.kopikoubou.childlock.shield-config", category: "ShieldConfiguration")

    override init() {
        super.init()
        logger.info("ShieldConfiguration initialized")
    }

    override func configuration() -> ShieldConfiguration {
        logger.info("Building custom shield configuration")

        // Soft Sage palette
        let shieldBg = UIColor(red: 0.106, green: 0.141, blue: 0.125, alpha: 1.0) // #1B2420
        let shieldInk = UIColor(red: 0.949, green: 0.945, blue: 0.925, alpha: 1.0) // #F2F1EC
        let forestSage = UIColor(red: 0.247, green: 0.420, blue: 0.345, alpha: 1.0) // #3F6B58
        let forestDeep = UIColor(red: 0.165, green: 0.302, blue: 0.247, alpha: 1.0) // #2A4D3F

        return ShieldConfiguration(
            backgroundColor: shieldBg,
            title: ShieldConfiguration.Title(
                text: "Brain Break!",
                color: shieldInk
            ),
            subtitle: ShieldConfiguration.Subtitle(
                text: "One quick puzzle, then back to your show.",
                color: shieldInk.withAlphaComponent(0.7)
            ),
            unlockButton: ShieldConfiguration.Button(
                text: "Start Challenge",
                color: .white,
                backgroundColor: forestSage
            ),
            requestMoreTimeButton: ShieldConfiguration.Button(
                text: "Ask Parent",
                color: shieldInk,
                backgroundColor: forestDeep
            ),
            lockedAppIcon: .init(systemName: "brain.head.profile"),
            lockedAppIconColor: forestSage
        )
    }
}
