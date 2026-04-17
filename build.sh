#!/bin/zsh
set -euo pipefail

# Childlock iOS Build Script
# Usage: ./build.sh [Debug|Release] [simulator|device]

CONFIGURATION="${1:-Debug}"
DESTINATION="${2:-simulator}"

cd /Users/devl/clawd/projects/childlock

echo "=== Childlock Build ==="
echo "Configuration: $CONFIGURATION"
echo "Destination: $DESTINATION"
echo ""

if [[ "$DESTINATION" == "simulator" ]]; then
    DEST="platform=iOS Simulator,name=iPhone 17 Pro"
else
    DEST="platform=iOS,identity='Apple Development'"
fi

echo "Building Childlock app + extensions..."
xcodebuild -project Childlock.xcodeproj \
    -scheme Childlock \
    -configuration "$CONFIGURATION" \
    -destination "$DEST" \
    -derivedDataPath .build \
    clean build

echo ""
echo "=== Build Complete ==="
echo "Output: .build/Build/Products/$CONFIGURATION-iphoneos/"
