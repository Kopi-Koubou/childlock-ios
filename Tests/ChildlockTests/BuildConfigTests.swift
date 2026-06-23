import XCTest

final class BuildConfigTests: XCTestCase {
    func testCheckedInAppSecretsConfigIncludesIgnoredLocalOverride() throws {
        let appSecrets = try readRepoFile("Config/AppSecrets.xcconfig")
        let gitignore = try readRepoFile(".gitignore")
        let credentials = try readRepoFile("Config/CREDENTIALS.md")
        let production = try readRepoFile("docs/PRODUCTION.md")

        XCTAssertTrue(appSecrets.contains("#include? \"AppSecrets.local.xcconfig\""))
        XCTAssertTrue(appSecrets.contains("SUPABASE_URL = https:/$()/jkncpveupvozsmbbkvgq.supabase.co"))
        XCTAssertTrue(appSecrets.contains("SUPABASE_PUBLISHABLE_KEY ="))
        XCTAssertTrue(appSecrets.contains("GOOGLE_IOS_CLIENT_ID ="))
        XCTAssertTrue(appSecrets.contains("GOOGLE_WEB_CLIENT_ID ="))
        XCTAssertTrue(appSecrets.contains("GOOGLE_REVERSED_CLIENT_ID ="))
        XCTAssertTrue(appSecrets.contains("REVENUECAT_API_KEY ="))
        XCTAssertTrue(appSecrets.contains("POSTHOG_API_KEY ="))

        XCTAssertTrue(gitignore.contains("Config/AppSecrets.local.xcconfig"))
        XCTAssertFalse(gitignore.contains("Config/AppSecrets.xcconfig\n"))

        XCTAssertTrue(credentials.contains("Config/AppSecrets.local.xcconfig"))
        XCTAssertTrue(production.contains("Config/AppSecrets.local.xcconfig"))
        XCTAssertTrue(production.contains("For Xcode Cloud"))
    }

    func testBuildScriptsAreRepoRelativeAndSafeForUnsignedPreflight() throws {
        let buildScript = try readRepoFile("build.sh")
        let validationScript = try readRepoFile("build-validation.sh")
        let production = try readRepoFile("docs/PRODUCTION.md")

        for contents in [buildScript, validationScript] {
            XCTAssertTrue(contents.contains("$(dirname \"$0\")"))
            XCTAssertFalse(contents.contains("/Users/devl/clawd/projects/childlock"))
            XCTAssertFalse(contents.contains("/Users/xav/Projects/Kopi-Koubou/childlock-ios"))
        }

        XCTAssertTrue(buildScript.contains("CODE_SIGNING_ALLOWED=NO"))
        XCTAssertTrue(validationScript.contains("SKIP_SECRET_CHECK=1"))
        XCTAssertTrue(validationScript.contains("Config/AppSecrets.local.xcconfig"))
        XCTAssertTrue(validationScript.contains("GOOGLE_IOS_CLIENT_ID"))
        XCTAssertTrue(validationScript.contains("GOOGLE_WEB_CLIENT_ID"))
        XCTAssertTrue(validationScript.contains("require_google_client_id_format"))
        XCTAssertTrue(validationScript.contains("has Google client ID format"))
        XCTAssertTrue(validationScript.contains("GOOGLE_REVERSED_CLIENT_ID"))
        XCTAssertTrue(validationScript.contains("GOOGLE_REVERSED_CLIENT_ID matches GOOGLE_IOS_CLIENT_ID"))
        XCTAssertTrue(validationScript.contains("GOOGLE_CLIENT_SECRET"))
        XCTAssertTrue(validationScript.contains("GOOGLE_WEB_CLIENT_SECRET"))
        XCTAssertTrue(validationScript.contains("Config/production.env"))
        XCTAssertTrue(validationScript.contains("SUPABASE_SERVICE_ROLE_KEY"))
        XCTAssertTrue(validationScript.contains("REVENUECAT_WEBHOOK_SECRET"))
        XCTAssertTrue(validationScript.contains("Server-only value must not be in $file"))
        XCTAssertTrue(validationScript.contains("config_failed=0"))
        XCTAssertTrue(validationScript.contains("Fill every missing value above"))
        XCTAssertTrue(validationScript.contains("VALIDATION_LOG_DIR"))
        XCTAssertTrue(validationScript.contains("run_logged_command \"Simulator Release build\""))
        XCTAssertTrue(validationScript.contains("run_logged_command \"Generic iOS Release build\""))
        XCTAssertTrue(validationScript.contains("Last 120 log lines"))
        XCTAssertTrue(validationScript.contains("xcodebuild-simulator-release.log"))
        XCTAssertTrue(validationScript.contains("xcodebuild-generic-ios-release.log"))
        XCTAssertTrue(validationScript.contains("Use docs/QA_TESTFLIGHT_CHECKLIST.md"))
        XCTAssertTrue(production.contains(".build/validation-logs/"))
        XCTAssertTrue(production.contains("last 120 log lines"))
        XCTAssertTrue(production.contains("./build-validation.sh"))
    }

    func testLaunchRepoDoesNotKeepStaleGeneratedStatusArtifacts() throws {
        let retiredArtifacts = [
            "audit-results.json",
            "deploy-receipt.json",
            "gtm-execution-log.md",
            "implementation-report.md",
            "implementation-report-update.md",
            "iterate-report.md",
            "pipeline.json",
            "qa-results.json",
            "review.json",
        ]

        for artifact in retiredArtifacts {
            let artifactURL = repoRoot.appendingPathComponent(artifact)
            XCTAssertFalse(
                FileManager.default.fileExists(atPath: artifactURL.path),
                "\(artifact) is a stale generated status artifact; use docs/PRODUCTION.md and docs/QA_TESTFLIGHT_CHECKLIST.md instead."
            )
        }

        let gtmPlan = try readRepoFile("gtm-plan.md")
        XCTAssertTrue(gtmPlan.contains("real-device TestFlight validation"))
        XCTAssertFalse(gtmPlan.contains("childlock.vercel.app"))
        XCTAssertFalse(gtmPlan.contains("Deploy receipt confirms"))
    }

    func testPrivacyManifestIsBundledForAppAndScreenTimeExtensions() throws {
        let project = try readRepoFile("Childlock.xcodeproj/project.pbxproj")
        let production = try readRepoFile("docs/PRODUCTION.md")
        let privacyManifest = try readPropertyList("Sources/Childlock/PrivacyInfo.xcprivacy")

        XCTAssertTrue(project.contains("APP_PRIVACY_MANIFEST /* PrivacyInfo.xcprivacy in Resources */"))
        XCTAssertTrue(project.contains("MONITOR_PRIVACY_MANIFEST /* PrivacyInfo.xcprivacy in Resources */"))
        XCTAssertTrue(project.contains("SHIELD_ACTION_PRIVACY_MANIFEST /* PrivacyInfo.xcprivacy in Resources */"))
        XCTAssertTrue(project.contains("SHIELD_CONFIG_PRIVACY_MANIFEST /* PrivacyInfo.xcprivacy in Resources */"))

        XCTAssertTrue(production.contains("Childlock.app/PrivacyInfo.xcprivacy"))
        XCTAssertTrue(production.contains("Childlock.app/PlugIns/ChildlockMonitor.appex/PrivacyInfo.xcprivacy"))
        XCTAssertTrue(production.contains("Childlock.app/PlugIns/ChildlockShieldAction.appex/PrivacyInfo.xcprivacy"))
        XCTAssertTrue(production.contains("Childlock.app/PlugIns/ChildlockShieldConfiguration.appex/PrivacyInfo.xcprivacy"))

        XCTAssertEqual(privacyManifest["NSPrivacyTracking"] as? Bool, false)

        let accessedAPITypes = try XCTUnwrap(privacyManifest["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        let userDefaultsDeclaration = try XCTUnwrap(
            accessedAPITypes.first { entry in
                entry["NSPrivacyAccessedAPIType"] as? String == "NSPrivacyAccessedAPICategoryUserDefaults"
            }
        )
        let reasons = try XCTUnwrap(userDefaultsDeclaration["NSPrivacyAccessedAPITypeReasons"] as? [String])
        XCTAssertTrue(reasons.contains("CA92.1"))
        XCTAssertTrue(reasons.contains("1C8F.1"))
    }

    func testAppStoreUploadMetadataIncludesRequiredIconsAndExtensionIdentifiers() throws {
        let project = try readRepoFile("Childlock.xcodeproj/project.pbxproj")
        let infoPlist = try readPropertyList("Sources/Childlock/Info.plist")
        let appIconCatalog = try readJSONDictionary("Sources/Childlock/Assets.xcassets/AppIcon.appiconset/Contents.json")
        let images = try XCTUnwrap(appIconCatalog["images"] as? [[String: Any]])

        XCTAssertEqual(infoPlist["CFBundleIconName"] as? String, "AppIcon")
        XCTAssertTrue(project.contains("ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;"))

        try assertRequiredIcon(
            in: images,
            idiom: "iphone",
            size: "60x60",
            scale: "2x",
            pixelSize: (width: 120, height: 120)
        )
        try assertRequiredIcon(
            in: images,
            idiom: "ipad",
            size: "76x76",
            scale: "2x",
            pixelSize: (width: 152, height: 152)
        )

        try assertExtensionPoint(
            "Extensions/DeviceActivityMonitorExtension/Info.plist",
            equals: "com.apple.deviceactivity.monitor-extension"
        )
        try assertExtensionPoint(
            "Extensions/ShieldActionExtension/Info.plist",
            equals: "com.apple.family-controls.shield-action-extension"
        )
        try assertExtensionPoint(
            "Extensions/ShieldConfigurationExtension/Info.plist",
            equals: "com.apple.family-controls.shield-configuration-extension"
        )
    }

    func testReleaseEntitlementsIncludeFamilyControlsSignInAndSharedAppGroup() throws {
        let appEntitlements = try readPropertyList("childlock.entitlements")
        XCTAssertEqual(appEntitlements["com.apple.developer.applesignin"] as? [String], ["Default"])
        try assertFamilyControlsEntitlements(appEntitlements)

        try assertFamilyControlsEntitlements(readPropertyList("DeviceActivityMonitorExtension.entitlements"))
        try assertFamilyControlsEntitlements(readPropertyList("Extensions/ShieldActionExtension/ShieldActionExtension.entitlements"))
        try assertFamilyControlsEntitlements(readPropertyList("Extensions/ShieldConfigurationExtension/ShieldConfigurationExtension.entitlements"))
    }

    private func readRepoFile(_ relativePath: String) throws -> String {
        let fileURL = repoRoot.appendingPathComponent(relativePath)
        return try String(contentsOf: fileURL, encoding: .utf8)
    }

    private func readPropertyList(_ relativePath: String) throws -> [String: Any] {
        let fileURL = repoRoot.appendingPathComponent(relativePath)
        let data = try Data(contentsOf: fileURL)
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
        return try XCTUnwrap(plist as? [String: Any])
    }

    private func readJSONDictionary(_ relativePath: String) throws -> [String: Any] {
        let data = try readData(relativePath)
        let json = try JSONSerialization.jsonObject(with: data)
        return try XCTUnwrap(json as? [String: Any])
    }

    private func readData(_ relativePath: String) throws -> Data {
        let fileURL = repoRoot.appendingPathComponent(relativePath)
        return try Data(contentsOf: fileURL)
    }

    private func assertRequiredIcon(
        in images: [[String: Any]],
        idiom: String,
        size: String,
        scale: String,
        pixelSize: (width: UInt32, height: UInt32),
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let image = images.first { image in
            image["idiom"] as? String == idiom
                && image["size"] as? String == size
                && image["scale"] as? String == scale
        }

        let icon = try XCTUnwrap(image, "Missing \(idiom) \(size) \(scale) app icon slot", file: file, line: line)
        let filename = try XCTUnwrap(icon["filename"] as? String, "Missing filename for \(idiom) \(size) \(scale)", file: file, line: line)
        let pngSize = try pngPixelSize("Sources/Childlock/Assets.xcassets/AppIcon.appiconset/\(filename)")

        XCTAssertEqual(pngSize.width, pixelSize.width, file: file, line: line)
        XCTAssertEqual(pngSize.height, pixelSize.height, file: file, line: line)
    }

    private func assertExtensionPoint(
        _ plistPath: String,
        equals expectedIdentifier: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let plist = try readPropertyList(plistPath)
        let extensionDictionary = try XCTUnwrap(plist["NSExtension"] as? [String: Any], file: file, line: line)
        XCTAssertEqual(extensionDictionary["NSExtensionPointIdentifier"] as? String, expectedIdentifier, file: file, line: line)
    }

    private func assertFamilyControlsEntitlements(
        _ entitlements: [String: Any],
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        XCTAssertEqual(entitlements["com.apple.developer.family-controls"] as? Bool, true, file: file, line: line)
        let appGroups = try XCTUnwrap(entitlements["com.apple.security.application-groups"] as? [String], file: file, line: line)
        XCTAssertTrue(appGroups.contains("group.com.childlock.shared"), file: file, line: line)
    }

    private func pngPixelSize(_ relativePath: String) throws -> (width: UInt32, height: UInt32) {
        let data = try readData(relativePath)
        XCTAssertGreaterThanOrEqual(data.count, 24)

        let signature = [UInt8](data.prefix(8))
        XCTAssertEqual(signature, [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])

        let bytes = [UInt8](data)
        let width = UInt32(bytes[16]) << 24
            | UInt32(bytes[17]) << 16
            | UInt32(bytes[18]) << 8
            | UInt32(bytes[19])
        let height = UInt32(bytes[20]) << 24
            | UInt32(bytes[21]) << 16
            | UInt32(bytes[22]) << 8
            | UInt32(bytes[23])

        return (width, height)
    }

    private var repoRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
