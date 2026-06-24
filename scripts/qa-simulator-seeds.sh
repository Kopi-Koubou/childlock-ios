#!/bin/zsh
set -euo pipefail

# Build a Debug simulator app once, launch every Childlock QA seed, and capture
# screenshots for visual review. Artifacts stay under ignored .build output.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="Childlock"
BUNDLE_ID="com.kopikoubou.childlock"
DERIVED_DATA_PATH="$ROOT_DIR/.build/qa-simulator-seeds/DerivedData"
RUN_ID="$(date +%Y%m%d-%H%M%S)"
OUTPUT_DIR="$ROOT_DIR/.build/qa-simulator-seeds/$RUN_ID"

DEFAULT_SIMULATORS=("iPhone 17" "iPad (A16)")
SIMULATORS=("$@")
if (( ${#SIMULATORS[@]} == 0 )); then
    SIMULATORS=("${DEFAULT_SIMULATORS[@]}")
fi

SEEDS=(
    "--childlock-qa-reset"
    "--childlock-qa-seed-onboarding-devices"
    "--childlock-qa-seed-onboarding-setup"
    "--childlock-qa-seed-dashboard"
    "--childlock-qa-seed-locked-dashboard"
    "--childlock-qa-seed-pending-challenge"
    "--childlock-qa-seed-pending-math-challenge"
    "--childlock-qa-seed-pending-memory-challenge"
    "--childlock-qa-seed-more-time-request"
    "--childlock-qa-seed-children-tab"
    "--childlock-qa-seed-add-child-sheet"
    "--childlock-qa-seed-apps-tab"
    "--childlock-qa-seed-settings-tab"
    "--childlock-qa-seed-paywall"
)

slugify() {
    echo "$1" \
        | tr '[:upper:]' '[:lower:]' \
        | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

simulator_id_for_name() {
    local simulator_name="$1"
    xcrun simctl list devices available \
        | grep -F "$simulator_name (" \
        | head -n 1 \
        | sed -E 's/.*\(([0-9A-Fa-f-]{36})\).*/\1/'
}

mkdir -p "$OUTPUT_DIR"

cd "$ROOT_DIR"

echo "=== Childlock simulator QA seeds ==="
echo "Output: $OUTPUT_DIR"
echo ""

echo "Building Debug simulator app..."
xcodebuild \
    -project "$ROOT_DIR/Childlock.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    clean build >/dev/null

APP_PATH="$DERIVED_DATA_PATH/Build/Products/Debug-iphonesimulator/Childlock.app"
if [[ ! -d "$APP_PATH" ]]; then
    echo "Missing simulator app at $APP_PATH"
    exit 1
fi

{
    echo "# Childlock Simulator QA Seeds"
    echo ""
    echo "Run: $RUN_ID"
    echo ""
    echo "| Simulator | Seed | Screenshot |"
    echo "| --- | --- | --- |"
} > "$OUTPUT_DIR/summary.md"

for simulator_name in "${SIMULATORS[@]}"; do
    simulator_id="$(simulator_id_for_name "$simulator_name")"
    if [[ -z "$simulator_id" ]]; then
        echo "Could not find available simulator named: $simulator_name"
        exit 1
    fi

    echo "Preparing $simulator_name ($simulator_id)..."
    xcrun simctl boot "$simulator_id" >/dev/null 2>&1 || true
    xcrun simctl bootstatus "$simulator_id" -b >/dev/null
    xcrun simctl install "$simulator_id" "$APP_PATH"

    simulator_slug="$(slugify "$simulator_name")"

    for seed in "${SEEDS[@]}"; do
        seed_slug="$(slugify "$seed")"
        screenshot_path="$OUTPUT_DIR/${simulator_slug}_${seed_slug}.png"

        echo "Launching $simulator_name with $seed"
        xcrun simctl launch --terminate-running-process "$simulator_id" "$BUNDLE_ID" "$seed" >/dev/null
        sleep 2
        xcrun simctl io "$simulator_id" screenshot "$screenshot_path" >/dev/null

        echo "| $simulator_name | \`$seed\` | \`$(basename "$screenshot_path")\` |" >> "$OUTPUT_DIR/summary.md"
    done
done

expected_screenshot_count=$(( ${#SIMULATORS[@]} * ${#SEEDS[@]} ))
actual_screenshot_count="$(find "$OUTPUT_DIR" -maxdepth 1 -name '*.png' | wc -l | tr -d ' ')"

if [[ "$actual_screenshot_count" != "$expected_screenshot_count" ]]; then
    echo "Expected $expected_screenshot_count screenshots, found $actual_screenshot_count"
    exit 1
fi

echo ""
echo "Captured $actual_screenshot_count screenshots."
echo "Done. Review screenshots and summary:"
echo "$OUTPUT_DIR/summary.md"
