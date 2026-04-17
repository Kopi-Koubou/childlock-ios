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
    targets: [
        .target(
            name: "Childlock"
        ),
        .testTarget(
            name: "ChildlockTests",
            dependencies: ["Childlock"]
        ),
    ]
)
