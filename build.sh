#!/bin/zsh
set -euo pipefail

# Childlock iOS Build Script
# Usage: ./build.sh [Debug|Release] [simulator|device]

CONFIGURATION="${1:-Debug}"
DESTINATION="${2:-simulator}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$SCRIPT_DIR"

echo "=== Childlock Build ==="
echo "Configuration: $CONFIGURATION"
echo "Destination: $DESTINATION"
echo ""

if [[ "$DESTINATION" == "simulator" ]]; then
    DEST="generic/platform=iOS Simulator"
else
    DEST="generic/platform=iOS"
fi

echo "Building Childlock app + extensions..."
xcodebuild -project Childlock.xcodeproj \
    -scheme Childlock \
    -configuration "$CONFIGURATION" \
    -destination "$DEST" \
    -derivedDataPath .build \
    CODE_SIGNING_ALLOWED=NO \
    clean build

echo ""
echo "=== Build Complete ==="
echo "Output: .build/Build/Products/"
