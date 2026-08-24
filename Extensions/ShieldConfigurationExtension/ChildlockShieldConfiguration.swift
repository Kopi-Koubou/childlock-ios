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

        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        let symbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: isIPad ? 72 : 48,
            weight: .semibold
        )

        guard let brainBreak = SharedDefaults.shieldBrainBreak() else {
            return ShieldConfiguration(
                backgroundBlurStyle: .systemMaterial,
                backgroundColor: shieldBg,
                icon: UIImage(
                    systemName: "brain.head.profile",
                    withConfiguration: symbolConfiguration
                ),
                title: ShieldConfiguration.Label(text: "Brain Break", color: shieldInk),
                subtitle: ShieldConfiguration.Label(text: "One moment…", color: shieldInk.withAlphaComponent(0.7))
            )
        }

        if brainBreak.phase == .success {
            return ShieldConfiguration(
                backgroundBlurStyle: .systemMaterial,
                backgroundColor: shieldBg,
                icon: UIImage(
                    systemName: "checkmark.circle.fill",
                    withConfiguration: symbolConfiguration
                ),
                title: ShieldConfiguration.Label(text: "Great job!", color: shieldInk),
                subtitle: ShieldConfiguration.Label(
                    text: "Going back to your app…",
                    color: shieldInk.withAlphaComponent(0.7)
                )
            )
        }

        let titleText = isIPad ? brainBreak.prompt : brainBreak.guidanceText
        let subtitleText = isIPad ? brainBreak.guidanceText : brainBreak.prompt

        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: shieldBg,
            icon: UIImage(
                systemName: "brain.head.profile",
                withConfiguration: symbolConfiguration
            ),
            title: ShieldConfiguration.Label(
                text: titleText,
                color: shieldInk
            ),
            subtitle: ShieldConfiguration.Label(
                text: subtitleText,
                color: shieldInk.withAlphaComponent(0.7)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: brainBreak.primaryAnswer,
                color: .white
            ),
            primaryButtonBackgroundColor: forestSage,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: brainBreak.secondaryAnswer,
                color: shieldInk
            )
        )
    }
}
