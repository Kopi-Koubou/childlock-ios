#!/bin/zsh
set -euo pipefail

# Build a Debug simulator app once, launch every Childlock QA seed, and capture
# screenshots plus a visual gallery. Artifacts stay under ignored .build output.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="Childlock"
BUNDLE_ID="com.kopikoubou.childlock"
DERIVED_DATA_PATH="$ROOT_DIR/.build/qa-simulator-seeds/DerivedData"
RUN_ID="$(date +%Y%m%d-%H%M%S)"
OUTPUT_DIR="$ROOT_DIR/.build/qa-simulator-seeds/$RUN_ID"
SUMMARY_PATH="$OUTPUT_DIR/summary.md"
GALLERY_PATH="$OUTPUT_DIR/gallery.html"

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
} > "$SUMMARY_PATH"

{
    echo "<!doctype html>"
    echo "<html lang=\"en\">"
    echo "<head>"
    echo "  <meta charset=\"utf-8\">"
    echo "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">"
    echo "  <title>Childlock Simulator QA Seeds $RUN_ID</title>"
    echo "  <style>"
    echo "    body { margin: 0; padding: 24px; font-family: -apple-system, BlinkMacSystemFont, sans-serif; background: #f7f5ef; color: #1f2723; }"
    echo "    h1 { margin: 0 0 4px; font-size: 28px; }"
    echo "    p { margin: 0 0 20px; color: #68716b; }"
    echo "    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 20px; align-items: start; }"
    echo "    article { background: white; border: 1px solid #e5e0d8; border-radius: 8px; padding: 12px; box-shadow: 0 6px 20px rgba(31, 39, 35, 0.08); }"
    echo "    img { width: 100%; height: auto; border-radius: 6px; background: #eeeae1; }"
    echo "    h2 { margin: 10px 0 4px; font-size: 16px; }"
    echo "    code { color: #3f765f; font-size: 12px; overflow-wrap: anywhere; }"
    echo "  </style>"
    echo "</head>"
    echo "<body>"
    echo "  <h1>Childlock Simulator QA Seeds</h1>"
    echo "  <p>Run $RUN_ID. Review phone and iPad launch states before TestFlight hardware QA.</p>"
    echo "  <main class=\"grid\">"
} > "$GALLERY_PATH"

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

        screenshot_file="$(basename "$screenshot_path")"
        echo "| $simulator_name | \`$seed\` | \`$screenshot_file\` |" >> "$SUMMARY_PATH"

        {
            echo "    <article>"
            echo "      <a href=\"$screenshot_file\"><img src=\"$screenshot_file\" alt=\"$simulator_name $seed\"></a>"
            echo "      <h2>$simulator_name</h2>"
            echo "      <code>$seed</code>"
            echo "    </article>"
        } >> "$GALLERY_PATH"
    done
done

{
    echo "  </main>"
    echo "</body>"
    echo "</html>"
} >> "$GALLERY_PATH"

expected_screenshot_count=$(( ${#SIMULATORS[@]} * ${#SEEDS[@]} ))
actual_screenshot_count="$(find "$OUTPUT_DIR" -maxdepth 1 -name '*.png' | wc -l | tr -d ' ')"

if [[ "$actual_screenshot_count" != "$expected_screenshot_count" ]]; then
    echo "Expected $expected_screenshot_count screenshots, found $actual_screenshot_count"
    exit 1
fi

echo ""
echo "Captured $actual_screenshot_count screenshots."
echo "Done. Review screenshots, summary, and gallery:"
echo "$SUMMARY_PATH"
echo "$GALLERY_PATH"
