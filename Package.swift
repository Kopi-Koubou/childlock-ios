// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Childlock",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "Childlock",
            targets: ["Childlock"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/RevenueCat/purchases-ios.git", from: "5.0.0"),
        .package(url: "https://github.com/PostHog/posthog-ios.git", from: "3.0.0"),
    ],
    targets: [
        .target(
            name: "Childlock",
            dependencies: [
                .product(name: "RevenueCat", package: "purchases-ios"),
                .product(name: "PostHog", package: "posthog-ios"),
            ]
        ),
        .testTarget(
            name: "ChildlockTests",
            dependencies: ["Childlock"]
        ),
    ]
)
