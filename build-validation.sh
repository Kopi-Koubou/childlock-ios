#!/bin/bash
# childlock Build Validation Script
# Generated: 2026-04-03
# Purpose: iOS build + Screen Time extension validation

set -e  # Exit on error

PROJECT_DIR="/Users/devl/clawd/projects/childlock"
SCHEME="Childlock"

echo "=== childlock Build Validation ==="
echo ""

# Check if in project directory
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ Project directory not found: $PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR"

# Check for Xcode project
if [ ! -f "Childlock.xcodeproj" ]; then
    echo "❌ Xcode project not found: Childlock.xcodeproj"
    exit 1
fi

echo "✅ Project found: Childlock.xcodeproj"
echo ""

# ============================================
# Step 1: Simulator Build (compile check)
# ============================================
echo "Step 1: Building for iOS Simulator..."
echo ""

xcodebuild \
    -scheme "$SCHEME" \
    -sdk iphonesimulator \
    -destination 'platform=iOS Simulator,name=iPhone 15' \
    clean build

echo ""
echo "✅ Simulator build complete"
echo ""

# ============================================
# Step 2: Physical Device Build (requires signing)
# ============================================
echo "Step 2: Building for physical device..."
echo "Note: This requires signing certificates + provisioning profiles"
echo ""

xcodebuild \
    -scheme "$SCHEME" \
    -sdk iphoneos \
    -destination 'generic/platform=iOS' \
    clean build

echo ""
echo "✅ Device build complete"
echo ""

# ============================================
# Step 3: Archive for TestFlight (optional)
# ============================================
echo "Step 3: Creating TestFlight archive..."
echo ""

mkdir -p ./build

xcodebuild \
    -scheme "$SCHEME" \
    -sdk iphoneos \
    -destination 'generic/platform=iOS' \
    -archivePath ./build/Childlock.xcarchive \
    archive

echo ""
echo "✅ Archive created: ./build/Childlock.xcarchive"
echo ""

# ============================================
# Step 4: Manual Validation Checklist
# ============================================
echo "=== Manual Validation Required ==="
echo ""
echo "Screen Time extension requires physical device testing:"
echo ""
echo "1. Install build on physical iPhone"
echo "2. Enable Screen Time in iOS Settings"
echo "3. Grant Family Controls permission to Childlock app"
echo "4. Configure test interval (e.g., 5 minutes)"
echo "5. Verify: Challenge popup appears after 5 min passive screen time"
echo "6. Verify: Screen unlocks after challenge completion"
echo "7. Verify: Math/memory/pattern challenges render correctly"
echo "8. Verify: Parent dashboard shows session reports"
echo ""
echo "=== Build validation script complete ==="