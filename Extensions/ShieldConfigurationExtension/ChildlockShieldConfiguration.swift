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
        
        return ShieldConfiguration(
            backgroundColor: .systemBackground,
            title: ShieldConfiguration.Title(
                text: "Challenge Time!",
                color: .label
            ),
            subtitle: ShieldConfiguration.Subtitle(
                text: "Complete a quick challenge to earn more screen time",
                color: .secondaryLabel
            ),
            unlockButton: ShieldConfiguration.Button(
                text: "Ask Parent",
                color: .white,
                backgroundColor: .systemBlue
            ),
            requestMoreTimeButton: ShieldConfiguration.Button(
                text: "I Need More Time",
                color: .white,
                backgroundColor: .systemOrange
            ),
            lockedAppIcon: .init(systemName: "brain.head.profile"),
            lockedAppIconColor: .systemPurple
        )
    }
}
