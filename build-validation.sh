#!/bin/bash
# childlock Build Validation Script
# Last updated: 2026-06-24
# Purpose: iOS build + Screen Time extension validation

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCHEME="Childlock"
DERIVED_DATA_PATH="$PROJECT_DIR/.build/xcode-preflight"
VALIDATION_LOG_DIR="$PROJECT_DIR/.build/validation-logs"

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

expected_google_reversed_client_id() {
    local ios_client_id="$1"
    local suffix=".apps.googleusercontent.com"

    if [[ "$ios_client_id" != *"$suffix" ]]; then
        return 1
    fi

    local client_prefix="${ios_client_id%"$suffix"}"
    printf "com.googleusercontent.apps.%s" "$client_prefix"
}

require_google_reversed_client_id_matches() {
    local file="$1"
    local ios_client_id
    local reversed_client_id
    local expected_reversed_client_id

    ios_client_id="$(read_config_value "$file" "GOOGLE_IOS_CLIENT_ID")"
    reversed_client_id="$(read_config_value "$file" "GOOGLE_REVERSED_CLIENT_ID")"

    if is_missing_value "$ios_client_id" || is_missing_value "$reversed_client_id"; then
        return 1
    fi

    if ! expected_reversed_client_id="$(expected_google_reversed_client_id "$ios_client_id")"; then
        echo "❌ GOOGLE_IOS_CLIENT_ID must end with .apps.googleusercontent.com"
        return 1
    fi

    if [[ "$reversed_client_id" != "$expected_reversed_client_id" ]]; then
        echo "❌ GOOGLE_REVERSED_CLIENT_ID does not match GOOGLE_IOS_CLIENT_ID in $file"
        return 1
    fi

    echo "✅ GOOGLE_REVERSED_CLIENT_ID matches GOOGLE_IOS_CLIENT_ID"
}

require_google_client_id_format() {
    local file="$1"
    local key="$2"
    local client_id
    client_id="$(read_config_value "$file" "$key")"

    if is_missing_value "$client_id"; then
        return 1
    fi

    if [[ "$client_id" != *".apps.googleusercontent.com" ]]; then
        echo "❌ $key must end with .apps.googleusercontent.com"
        return 1
    fi

    echo "✅ $key has Google client ID format"
}

check_google_oauth_config() {
    local file="$1"
    local ios_client_id
    local web_client_id
    local reversed_client_id
    local configured_count=0
    local google_failed=0

    ios_client_id="$(read_config_value "$file" "GOOGLE_IOS_CLIENT_ID")"
    web_client_id="$(read_config_value "$file" "GOOGLE_WEB_CLIENT_ID")"
    reversed_client_id="$(read_config_value "$file" "GOOGLE_REVERSED_CLIENT_ID")"

    is_missing_value "$ios_client_id" || configured_count=$((configured_count + 1))
    is_missing_value "$web_client_id" || configured_count=$((configured_count + 1))
    is_missing_value "$reversed_client_id" || configured_count=$((configured_count + 1))

    if [[ "$configured_count" == "0" ]]; then
        if [[ "${REQUIRE_GOOGLE_OAUTH:-0}" == "1" ]]; then
            echo "❌ Google OAuth is required for this validation but is not configured."
            return 1
        fi

        echo "⚠️  Google OAuth not configured; Continue with Google should stay hidden."
        echo "ℹ️  Set REQUIRE_GOOGLE_OAUTH=1 ./build-validation.sh to require Google sign-in for this release."
        return 0
    fi

    require_config_value "$file" "GOOGLE_IOS_CLIENT_ID" || google_failed=1
    require_google_client_id_format "$file" "GOOGLE_IOS_CLIENT_ID" || google_failed=1
    require_config_value "$file" "GOOGLE_WEB_CLIENT_ID" || google_failed=1
    require_google_client_id_format "$file" "GOOGLE_WEB_CLIENT_ID" || google_failed=1
    require_config_value "$file" "GOOGLE_REVERSED_CLIENT_ID" || google_failed=1
    require_google_reversed_client_id_matches "$file" || google_failed=1

    if [[ "$google_failed" == "1" ]]; then
        echo "❌ Google OAuth is partially configured or invalid. Fill all Google values or leave all three blank so Google stays hidden."
        return 1
    fi

    echo "✅ Google OAuth configured for this build"
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

run_logged_command() {
    local label="$1"
    local log_name="$2"
    shift 2

    mkdir -p "$VALIDATION_LOG_DIR"
    local log_file="$VALIDATION_LOG_DIR/$log_name"

    echo "Full output: $log_file"

    if "$@" > "$log_file" 2>&1; then
        echo "✅ $label complete"
        return 0
    fi

    local status=$?
    echo "❌ $label failed. Last 120 log lines:"
    echo ""
    tail -n 120 "$log_file"
    echo ""
    echo "Full output: $log_file"
    return "$status"
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

    config_failed=0

    require_config_value "Config/AppSecrets.local.xcconfig" "SUPABASE_URL" || config_failed=1
    require_config_value "Config/AppSecrets.local.xcconfig" "SUPABASE_PUBLISHABLE_KEY" || config_failed=1
    check_google_oauth_config "Config/AppSecrets.local.xcconfig" || config_failed=1
    require_config_value "Config/AppSecrets.local.xcconfig" "REVENUECAT_API_KEY" || config_failed=1

    require_missing_or_blank "Config/AppSecrets.local.xcconfig" "SUPABASE_ACCESS_TOKEN" || config_failed=1
    require_missing_or_blank "Config/AppSecrets.local.xcconfig" "SUPABASE_SERVICE_ROLE_KEY" || config_failed=1
    require_missing_or_blank "Config/AppSecrets.local.xcconfig" "REVENUECAT_WEBHOOK_SECRET" || config_failed=1
    require_missing_or_blank "Config/AppSecrets.local.xcconfig" "GOOGLE_CLIENT_SECRET" || config_failed=1
    require_missing_or_blank "Config/AppSecrets.local.xcconfig" "GOOGLE_WEB_CLIENT_SECRET" || config_failed=1

    require_config_value "Config/production.env" "SUPABASE_PROJECT_REF" || config_failed=1
    require_config_value "Config/production.env" "SUPABASE_ACCESS_TOKEN" || config_failed=1
    require_config_value "Config/production.env" "SUPABASE_SERVICE_ROLE_KEY" || config_failed=1
    require_config_value "Config/production.env" "REVENUECAT_WEBHOOK_SECRET" || config_failed=1

    if [[ "$config_failed" == "1" ]]; then
        echo ""
        echo "❌ Production configuration check failed. Fill every missing value above, then rerun ./build-validation.sh"
        exit 1
    fi

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

run_logged_command "Simulator Release build" "xcodebuild-simulator-release.log" \
    xcodebuild \
    -project Childlock.xcodeproj \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    CODE_SIGNING_ALLOWED=NO \
    clean build

echo ""
echo ""

# ============================================
# Step 5: Generic Device Build (archive-shape compile check)
# ============================================
echo "Step 5: Building Release for generic iOS device without signing..."
echo ""

run_logged_command "Generic iOS Release build" "xcodebuild-generic-ios-release.log" \
    xcodebuild \
    -project Childlock.xcodeproj \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    CODE_SIGNING_ALLOWED=NO \
    clean build

echo ""
echo ""

# ============================================
# Step 6: Manual Validation Checklist
# ============================================
echo "=== Manual Validation Required ==="
echo ""
echo "Screen Time extension requires physical device testing:"
echo ""
echo "1. Install the TestFlight build on the child-used device."
echo "2. Sign in with Apple. If Google OAuth build settings are configured, sign in with Google in a separate pass."
echo "3. Grant Screen Time access to Childlock."
echo "4. Select a real app/category/web domain and the shortest interval."
echo "5. Start real child-like content in the selected app/site and record the start time."
echo "6. Verify: selected content shields only after the threshold; record the shield timestamp."
echo "7. Verify: Start closes the shielded app and Childlock opens the pending challenge from the alert or Home."
echo "8. Verify: challenge completion clears shields and re-arms monitoring."
echo "9. Verify: hand-back shows Done plus the back-arrow cue and keeps the parent dashboard behind the PIN."
echo ""
echo "Use docs/TESTFLIGHT_RUN_SHEET.md while testing on device."
echo "Use docs/QA_TESTFLIGHT_CHECKLIST.md for the full same-phone and child-iPad matrix."
echo ""
echo "=== Build validation script complete ==="
