#!/bin/zsh
set -euo pipefail

# Create a timestamped, fillable physical TestFlight QA record. The output is
# ignored by git so tester/device details do not accidentally land in the repo.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE="$ROOT_DIR/docs/HARDWARE_QA_RECORD_TEMPLATE.md"
OUTPUT_ROOT="$ROOT_DIR/.build/hardware-qa-records"

scenario="${1:-manual}"
build_number="${2:-unknown-build}"
timestamp="$(date +%Y%m%d-%H%M%S)"
record_date="$(date +%Y-%m-%d)"
safe_scenario="$(echo "$scenario" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
safe_build="$(echo "$build_number" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9._-]+/-/g; s/^-+//; s/-+$//')"
output_dir="$OUTPUT_ROOT/$timestamp"
output_file="$output_dir/${safe_scenario:-manual}_${safe_build:-unknown-build}.md"
git_commit="$(git -C "$ROOT_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")"
tester_name="$(git -C "$ROOT_DIR" config user.name 2>/dev/null || true)"
tester_name="${tester_name:-${USER:-}}"
latest_simulator_summary="$(find "$ROOT_DIR/.build/qa-simulator-seeds" -path "*/summary.md" -type f -print 2>/dev/null | sort | tail -n 1)"
if [[ -n "$latest_simulator_summary" ]]; then
    latest_simulator_summary="${latest_simulator_summary#$ROOT_DIR/}"
else
    latest_simulator_summary="not generated yet"
fi

latest_simulator_gallery="$(find "$ROOT_DIR/.build/qa-simulator-seeds" -path "*/gallery.html" -type f -print 2>/dev/null | sort | tail -n 1)"
if [[ -n "$latest_simulator_gallery" ]]; then
    latest_simulator_gallery="${latest_simulator_gallery#$ROOT_DIR/}"
else
    latest_simulator_gallery="not generated yet"
fi

latest_simulator_contact_sheet="$(find "$ROOT_DIR/.build/qa-simulator-seeds" -path "*/contact-sheet.png" -type f -print 2>/dev/null | sort | tail -n 1)"
if [[ -n "$latest_simulator_contact_sheet" ]]; then
    latest_simulator_contact_sheet="${latest_simulator_contact_sheet#$ROOT_DIR/}"
else
    latest_simulator_contact_sheet="not generated yet"
fi

read_config_value() {
    local file="$1"
    local key="$2"

    [[ -f "$file" ]] || return 0

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

is_missing_config_value() {
    local value="$1"
    [[ -z "$value" || "$value" == *"YOUR_"* || "$value" == *"_YOUR_"* || "$value" == \$\(* ]]
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

google_oauth_build_status() {
    local file="$ROOT_DIR/Config/AppSecrets.local.xcconfig"
    local ios_client_id
    local web_client_id
    local reversed_client_id
    local expected_reversed_client_id

    ios_client_id="$(read_config_value "$file" "GOOGLE_IOS_CLIENT_ID")"
    web_client_id="$(read_config_value "$file" "GOOGLE_WEB_CLIENT_ID")"
    reversed_client_id="$(read_config_value "$file" "GOOGLE_REVERSED_CLIENT_ID")"

    if is_missing_config_value "$ios_client_id" \
        || is_missing_config_value "$web_client_id" \
        || is_missing_config_value "$reversed_client_id"; then
        echo "Missing or placeholder"
        return
    fi

    if ! expected_reversed_client_id="$(expected_google_reversed_client_id "$ios_client_id")"; then
        echo "Invalid iOS client ID"
        return
    fi

    if [[ "$reversed_client_id" != "$expected_reversed_client_id" ]]; then
        echo "Reversed client ID mismatch"
        return
    fi

    echo "Configured"
}

google_oauth_status="$(google_oauth_build_status)"

case "$safe_scenario" in
    same-phone)
        scenario_label="Same phone"
        child_used_device="Same iPhone"
        parent_iphone_role="Same device"
        ;;
    child-ipad)
        scenario_label="Child iPad"
        child_used_device="Child iPad"
        parent_iphone_role="Login smoke only"
        ;;
    child-iphone)
        scenario_label="Child iPhone"
        child_used_device="Child iPhone"
        parent_iphone_role="Login smoke only"
        ;;
    *)
        scenario_label="$scenario"
        child_used_device=""
        parent_iphone_role=""
        ;;
esac

if [[ ! -f "$TEMPLATE" ]]; then
    echo "Missing template: $TEMPLATE"
    exit 1
fi

mkdir -p "$output_dir"
cp "$TEMPLATE" "$output_file"

replace_row() {
    local field="$1"
    local value="$2"
    local tmp_file="$output_file.tmp"

    awk -v field="$field" -v value="$value" '
        BEGIN { FS = OFS = "|" }
        {
            label = $2
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", label)
            if (label == field && NF >= 3) {
                $3 = " " value " "
            }
            print
        }
    ' "$output_file" > "$tmp_file"
    mv "$tmp_file" "$output_file"
}

scenario_instructions() {
    case "$safe_scenario" in
        same-phone)
            cat <<'EOF'
## Scenario Instructions

Fill `Required Shield Loop` and `Same Phone Scenario`.
Mark `Child iPad Scenario` rows `N/A` unless this record also covers an iPad run.
EOF
            ;;
        child-ipad)
            cat <<'EOF'
## Scenario Instructions

Fill `Required Shield Loop` and `Child iPad Scenario`.
Mark `Same Phone Scenario` rows `N/A` unless this record also covers a shared-phone run.
EOF
            ;;
        *)
            cat <<'EOF'
## Scenario Instructions

Fill `Required Shield Loop` and the scenario section that matches this device.
Mark unrelated scenario rows `N/A`.
EOF
            ;;
    esac
}

insert_scenario_instructions() {
    local tmp_file="$output_file.tmp"
    local instructions_file="$output_file.instructions.tmp"

    scenario_instructions > "$instructions_file"

    awk -v instructions_file="$instructions_file" '
        $0 == "## Required Shield Loop" {
            while ((getline line < instructions_file) > 0) {
                print line
            }
            close(instructions_file)
            print ""
        }
        { print }
    ' "$output_file" > "$tmp_file"

    rm -f "$instructions_file"
    mv "$tmp_file" "$output_file"
}

replace_row "Build number" "$build_number"
replace_row "Git commit" "$git_commit"
replace_row "Tester" "$tester_name"
replace_row "Date" "$record_date"
replace_row "Scenario" "$scenario_label"
replace_row "Child-used device configured" "$child_used_device"
replace_row "Parent iPhone role" "$parent_iphone_role"
replace_row "Latest simulator QA summary" "$latest_simulator_summary"
replace_row "Latest simulator QA gallery" "$latest_simulator_gallery"
replace_row "Latest simulator QA contact sheet" "$latest_simulator_contact_sheet"
replace_row "Google OAuth build settings" "$google_oauth_status"
insert_scenario_instructions

cat >> "$output_file" <<EOF

---

Generated by \`scripts/new-hardware-qa-record.sh\`.

This file is ignored by git. Fill the remaining blanks while testing the
TestFlight build, and keep any screen recordings or screenshots with the same
scenario/build label.
EOF

echo "Created hardware QA record:"
echo "$output_file"
