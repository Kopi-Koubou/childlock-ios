#!/bin/bash
# childlock Build Validation Script
# Last updated: 2026-06-24
# Purpose: iOS build + Screen Time extension validation

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCHEME="Childlock"
DERIVED_DATA_PATH="$PROJECT_DIR/.build/xcode-preflight"

read_config_value() {
    local file="$1"
    local key="$2"

    awk -F '=' -v wanted_key="$key" '
        /^[[:space:]]*$/ { next }
        /^[[:space:]]*#/ { next }
        /^[[:space:]]*\/\// { next }
        {
            name = $1
            gsub(/^[ \t]+|[ \t]+$/, "", name)
            if (name == wanted_key) {
                value = $0
                sub(/^[^=]*=/, "", value)
                gsub(/^[ \t]+|[ \t]+$/, "", value)
                print value
                exit
            }
        }
    ' "$file"
}

is_missing_value() {
    local value="$1"
    [[ -z "$value" || "$value" == *"YOUR_"* || "$value" == *"_YOUR_"* || "$value" == \$\(* ]]
}

require_config_value() {
    local file="$1"
    local key="$2"
    local value
    value="$(read_config_value "$file" "$key")"

    if is_missing_value "$value"; then
        echo "❌ Missing required value: $key in $file"
        return 1
    fi

    echo "✅ $key present in $file"
}

require_missing_or_blank() {
    local file="$1"
    local key="$2"
    local value
    value="$(read_config_value "$file" "$key")"

    if ! is_missing_value "$value"; then
        echo "❌ Server-only value must not be in $file: $key"
        return 1
    fi
}

echo "=== childlock Build Validation ==="
echo ""

cd "$PROJECT_DIR"

# Check for Xcode project
if [ ! -d "Childlock.xcodeproj" ]; then
    echo "❌ Xcode project not found: Childlock.xcodeproj"
    exit 1
fi

echo "✅ Project found: Childlock.xcodeproj"
echo ""

# ============================================
# Step 1: Production configuration readiness
# ============================================
echo "Step 1: Checking production configuration without printing secret values..."
echo ""

if [[ "${SKIP_SECRET_CHECK:-0}" == "1" ]]; then
    echo "⚠️  Skipping secret presence checks because SKIP_SECRET_CHECK=1"
else
    if [[ ! -f "Config/AppSecrets.local.xcconfig" ]]; then
        echo "❌ Missing Config/AppSecrets.local.xcconfig"
        exit 1
    fi

    if [[ ! -f "Config/production.env" ]]; then
        echo "❌ Missing Config/production.env"
        exit 1
    fi

    require_config_value "Config/AppSecrets.local.xcconfig" "SUPABASE_URL"
    require_config_value "Config/AppSecrets.local.xcconfig" "SUPABASE_PUBLISHABLE_KEY"
    require_config_value "Config/AppSecrets.local.xcconfig" "GOOGLE_IOS_CLIENT_ID"
    require_config_value "Config/AppSecrets.local.xcconfig" "GOOGLE_REVERSED_CLIENT_ID"
    require_config_value "Config/AppSecrets.local.xcconfig" "REVENUECAT_API_KEY"

    require_missing_or_blank "Config/AppSecrets.local.xcconfig" "SUPABASE_ACCESS_TOKEN"
    require_missing_or_blank "Config/AppSecrets.local.xcconfig" "SUPABASE_SERVICE_ROLE_KEY"
    require_missing_or_blank "Config/AppSecrets.local.xcconfig" "REVENUECAT_WEBHOOK_SECRET"
    require_missing_or_blank "Config/AppSecrets.local.xcconfig" "GOOGLE_CLIENT_SECRET"

    require_config_value "Config/production.env" "SUPABASE_PROJECT_REF"
    require_config_value "Config/production.env" "SUPABASE_ACCESS_TOKEN"
    require_config_value "Config/production.env" "SUPABASE_SERVICE_ROLE_KEY"
    require_config_value "Config/production.env" "REVENUECAT_WEBHOOK_SECRET"

    echo "ℹ️  POSTHOG_API_KEY is optional for launch validation."
fi

echo ""
echo "✅ Production configuration check complete"
echo ""

# ============================================
# Step 2: Swift package tests
# ============================================
echo "Step 2: Running Swift package tests..."
echo ""

swift test

echo ""
echo "✅ Swift tests complete"
echo ""

# ============================================
# Step 3: Diff hygiene
# ============================================
echo "Step 3: Checking whitespace in tracked changes..."
echo ""

git diff --check -- ':!.build'

echo ""
echo "✅ Diff hygiene check complete"
echo ""

# ============================================
# Step 4: Simulator Build (compile check)
# ============================================
echo "Step 4: Building Release for iOS Simulator..."
echo ""

xcodebuild \
    -project Childlock.xcodeproj \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    CODE_SIGNING_ALLOWED=NO \
    clean build

echo ""
echo "✅ Simulator Release build complete"
echo ""

# ============================================
# Step 5: Generic Device Build (archive-shape compile check)
# ============================================
echo "Step 5: Building Release for generic iOS device without signing..."
echo ""

xcodebuild \
    -project Childlock.xcodeproj \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    CODE_SIGNING_ALLOWED=NO \
    clean build

echo ""
echo "✅ Generic iOS Release build complete"
echo ""

# ============================================
# Step 6: Manual Validation Checklist
# ============================================
echo "=== Manual Validation Required ==="
echo ""
echo "Screen Time extension requires physical device testing:"
echo ""
echo "1. Install the TestFlight build on the child-used device."
echo "2. Sign in with Apple and Google in separate passes."
echo "3. Grant Screen Time access to Childlock."
echo "4. Select a real app/category/web domain and the shortest interval."
echo "5. Verify: selected app shields only after the threshold."
echo "6. Verify: Start Brain Break closes the shielded app and Childlock opens the pending challenge from Home/notification."
echo "7. Verify: challenge completion clears shields and re-arms monitoring."
echo "8. Verify: hand-back keeps the parent dashboard behind the PIN."
echo ""
echo "Use docs/QA_TESTFLIGHT_CHECKLIST.md for the full same-phone and child-iPad matrix."
echo ""
echo "=== Build validation script complete ==="
