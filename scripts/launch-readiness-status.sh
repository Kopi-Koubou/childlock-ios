#!/bin/zsh
set -euo pipefail

# Print a no-secret snapshot of launch readiness. This intentionally reports
# only set/missing/invalid status, never credential values.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_CONFIG_BASE="$ROOT_DIR/Config/AppSecrets.xcconfig"
APP_CONFIG_LOCAL="$ROOT_DIR/Config/AppSecrets.local.xcconfig"
SERVER_CONFIG="$ROOT_DIR/Config/production.env"
STRICT_MODE=0

usage() {
    cat <<EOF
Usage: scripts/launch-readiness-status.sh [--strict]

Prints a no-secret Childlock launch readiness snapshot.

Options:
  --strict  Exit nonzero when public App Review launch gates are not complete.
  -h, --help  Show this help.
EOF
}

case "${1:-}" in
    "")
        ;;
    --strict)
        STRICT_MODE=1
        ;;
    -h|--help)
        usage
        exit 0
        ;;
    *)
        usage
        exit 1
        ;;
esac

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

has_config_key() {
    local file="$1"
    local key="$2"

    [[ -f "$file" ]] || return 1

    awk -F '=' -v wanted_key="$key" '
        /^[[:space:]]*$/ { next }
        /^[[:space:]]*#/ { next }
        /^[[:space:]]*\/\// { next }
        {
            name = $1
            gsub(/^[ \t]+|[ \t]+$/, "", name)
            if (name == wanted_key) {
                found = 1
                exit
            }
        }
        END { exit found ? 0 : 1 }
    ' "$file"
}

effective_app_value() {
    local key="$1"

    if has_config_key "$APP_CONFIG_LOCAL" "$key"; then
        read_config_value "$APP_CONFIG_LOCAL" "$key"
    else
        read_config_value "$APP_CONFIG_BASE" "$key"
    fi
}

is_missing_value() {
    local value="$1"
    [[ -z "$value" || "$value" == *"YOUR_"* || "$value" == *"_YOUR_"* || "$value" == \$\(* ]]
}

status_for_app_key() {
    local key="$1"
    local value

    value="$(effective_app_value "$key")"
    if is_missing_value "$value"; then
        echo "missing-or-placeholder"
    else
        echo "set"
    fi
}

status_for_server_key() {
    local key="$1"
    local value

    value="$(read_config_value "$SERVER_CONFIG" "$key")"
    if is_missing_value "$value"; then
        echo "missing-or-placeholder"
    else
        echo "set"
    fi
}

server_secret_next_steps_needed() {
    [[ "$(status_for_server_key "SUPABASE_ACCESS_TOKEN")" == "missing-or-placeholder" ]] \
        || [[ "$(status_for_server_key "REVENUECAT_WEBHOOK_SECRET")" == "missing-or-placeholder" ]]
}

expected_google_reversed_client_id() {
    local ios_client_id="$1"
    local suffix=".apps.googleusercontent.com"

    if [[ "$ios_client_id" != *"$suffix" ]]; then
        return 1
    fi

    local client_prefix="${ios_client_id%"$suffix"}"
    [[ -n "$client_prefix" ]] || return 1
    printf "com.googleusercontent.apps.%s" "$client_prefix"
}

google_oauth_status() {
    local ios_client_id
    local web_client_id
    local reversed_client_id
    local expected_reversed_client_id
    local missing_count=0

    ios_client_id="$(effective_app_value "GOOGLE_IOS_CLIENT_ID")"
    web_client_id="$(effective_app_value "GOOGLE_WEB_CLIENT_ID")"
    reversed_client_id="$(effective_app_value "GOOGLE_REVERSED_CLIENT_ID")"

    is_missing_value "$ios_client_id" && missing_count=$((missing_count + 1))
    is_missing_value "$web_client_id" && missing_count=$((missing_count + 1))
    is_missing_value "$reversed_client_id" && missing_count=$((missing_count + 1))

    if [[ "$missing_count" -eq 3 ]]; then
        echo "hidden (missing or placeholder)"
        return
    fi

    if [[ "$missing_count" -gt 0 ]]; then
        echo "invalid/partial"
        return
    fi

    if ! expected_reversed_client_id="$(expected_google_reversed_client_id "$ios_client_id")"; then
        echo "invalid iOS client ID"
        return
    fi

    if [[ "$reversed_client_id" != "$expected_reversed_client_id" ]]; then
        echo "invalid reversed client ID"
        return
    fi

    echo "configured"
}

relative_latest_path() {
    local root="$1"
    local name="$2"
    local latest

    latest="$(find "$root" -name "$name" -type f -print 2>/dev/null | sort | tail -n 1)"
    if [[ -n "$latest" ]]; then
        echo "$latest"
    else
        echo ""
    fi
}

relative_latest_record() {
    local scenario="$1"
    local latest

    latest="$(find "$ROOT_DIR/.build/hardware-qa-records" -name "${scenario}_*.md" -type f -print 2>/dev/null | sort | tail -n 1)"
    if [[ -n "$latest" ]]; then
        echo "$latest"
    else
        echo ""
    fi
}

current_git_commit() {
    git -C "$ROOT_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown"
}

git_status_line() {
    local branch
    local commit
    local dirty="clean"

    branch="$(git -C "$ROOT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")"
    commit="$(git -C "$ROOT_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")"
    if [[ -n "$(git -C "$ROOT_DIR" status --porcelain --untracked-files=normal)" ]]; then
        dirty="dirty"
    fi

    echo "$branch $commit ($dirty)"
}

summary_git_commit() {
    local file="$1"

    [[ -f "$file" ]] || return 0
    awk -F ':' '
        $1 == "Git commit" {
            value = $2
            gsub(/^[ \t]+|[ \t]+$/, "", value)
            print value
            exit
        }
    ' "$file"
}

hardware_record_git_commit() {
    local file="$1"

    [[ -f "$file" ]] || return 0
    hardware_record_field "$file" "Git commit"
}

hardware_record_field() {
    local file="$1"
    local field="$2"

    [[ -f "$file" ]] || return 0
    awk -F '|' -v wanted="$field" '
        {
            label = $2
            gsub(/^[ \t]+|[ \t]+$/, "", label)
            if (label == wanted) {
                value = $3
                gsub(/^[ \t]+|[ \t]+$/, "", value)
                print value
                exit
            }
        }
    ' "$file"
}

describe_evidence_path() {
    local file="$1"
    local commit="$2"
    local current_commit
    local relative_file

    if [[ -z "$file" ]]; then
        echo "not generated yet"
        return
    fi

    current_commit="$(current_git_commit)"
    relative_file="${file#$ROOT_DIR/}"

    if [[ -z "$commit" ]]; then
        echo "$relative_file (commit unknown; regenerate for current build)"
        return
    fi

    if [[ "$commit" == "$current_commit" ]]; then
        echo "$relative_file (current commit $commit)"
        return
    fi

    echo "$relative_file (stale commit $commit; current $current_commit)"
}

hardware_record_completion_status() {
    local file="$1"
    local build_number
    local field
    local value

    if [[ -z "$file" || ! -f "$file" ]]; then
        echo "not generated yet"
        return
    fi

    build_number="$(hardware_record_field "$file" "Build number")"
    if [[ -z "$build_number" || "$build_number" == "unknown-build" || "$build_number" == "pending-testflight-build" ]]; then
        echo "pending TestFlight build"
        return
    fi

    local required_fields=(
        "Device model"
        "iOS version"
        "Child-used device configured"
        "Parent iPhone role"
        "Parent sign-in tested"
        "Notification state tested"
        "Monitored selection"
        "Content app/activity tested"
        "Brain-break interval"
        "Content started at"
        "Shield appeared at"
        "RevenueCat paywall/offering behaved as expected"
        "RevenueCat offering loaded monthly and annual packages"
        "Purchase activates Childlock Premium entitlement"
        "Restore purchases reactivates Premium"
        "Premium status persists after app restart"
    )

    for field in "${required_fields[@]}"; do
        value="$(hardware_record_field "$file" "$field")"
        if [[ -z "$value" || "$value" == *" / "* ]]; then
            echo "incomplete checklist"
            return
        fi
    done

    if grep -Eq '\|[[:space:]]*(Pass / Fail|Pass / Fail / N/A|Apple / Google / N/A|Allowed / Denied|App / Category / Website|Same iPhone / Child iPad / Child iPhone|Same device / Login smoke only / N/A|Configured / Missing or placeholder)[[:space:]]*\|' "$file"; then
        echo "incomplete checklist"
        return
    fi

    if grep -Eq '\|[[:space:]]*(RevenueCat paywall/offering behaved as expected|RevenueCat offering loaded monthly and annual packages|Purchase activates Childlock Premium entitlement|Restore purchases reactivates Premium|Premium status persists after app restart)[[:space:]]*\|[[:space:]]*Not tested[[:space:]]*\|' "$file"; then
        echo "incomplete paid-flow QA"
        return
    fi

    echo "filled; review manually"
}

hardware_record_simulator_evidence_status() {
    local file="$1"
    local summary_path
    local gallery_path
    local contact_sheet_path
    local summary_file
    local gallery_file
    local contact_sheet_file
    local current_commit
    local commit

    if [[ -z "$file" || ! -f "$file" ]]; then
        echo "simulator evidence missing"
        return
    fi

    summary_path="$(hardware_record_field "$file" "Latest simulator QA summary")"
    gallery_path="$(hardware_record_field "$file" "Latest simulator QA gallery")"
    contact_sheet_path="$(hardware_record_field "$file" "Latest simulator QA contact sheet")"

    if [[ -z "$summary_path" || "$summary_path" == not\ generated* ]]; then
        echo "simulator evidence missing"
        return
    fi

    if [[ "$summary_path" == /* ]]; then
        summary_file="$summary_path"
    else
        summary_file="$ROOT_DIR/$summary_path"
    fi

    if [[ "$gallery_path" == /* ]]; then
        gallery_file="$gallery_path"
    else
        gallery_file="$ROOT_DIR/$gallery_path"
    fi

    if [[ "$contact_sheet_path" == /* ]]; then
        contact_sheet_file="$contact_sheet_path"
    else
        contact_sheet_file="$ROOT_DIR/$contact_sheet_path"
    fi

    if [[ ! -f "$summary_file" || ! -f "$gallery_file" || ! -f "$contact_sheet_file" ]]; then
        echo "simulator evidence file missing"
        return
    fi

    current_commit="$(current_git_commit)"
    commit="$(summary_git_commit "$summary_file")"
    if [[ -z "$commit" || "$commit" != "$current_commit" ]]; then
        echo "simulator evidence stale"
        return
    fi

    echo "simulator evidence current"
}

describe_hardware_record() {
    local file="$1"
    local commit="$2"
    local evidence
    local completion
    local simulator_evidence

    evidence="$(describe_evidence_path "$file" "$commit")"
    completion="$(hardware_record_completion_status "$file")"
    simulator_evidence="$(hardware_record_simulator_evidence_status "$file")"

    echo "$evidence; $completion; $simulator_evidence"
}

append_strict_blocker() {
    strict_blockers+=("$1")
}

collect_strict_blockers() {
    local current_commit
    local summary_commit
    local same_phone_commit
    local child_ipad_commit
    local same_phone_completion
    local child_ipad_completion
    local same_phone_simulator_evidence
    local child_ipad_simulator_evidence
    local google_status

    strict_blockers=()
    current_commit="$(current_git_commit)"

    if [[ -n "$(git -C "$ROOT_DIR" status --porcelain --untracked-files=normal)" ]]; then
        append_strict_blocker "Git tree is dirty; commit, stash, or remove local changes before launch."
    fi

    for key in SUPABASE_URL SUPABASE_PUBLISHABLE_KEY REVENUECAT_API_KEY; do
        if [[ "$(status_for_app_key "$key")" != "set" ]]; then
            append_strict_blocker "App-facing build setting $key is missing or placeholder."
        fi
    done

    google_status="$(google_oauth_status)"
    if [[ "$google_status" == invalid* ]]; then
        append_strict_blocker "Google OAuth build settings are $google_status; fill all three values or leave all three blank."
    fi

    for key in SUPABASE_PROJECT_REF SUPABASE_ACCESS_TOKEN REVENUECAT_WEBHOOK_SECRET; do
        if [[ "$(status_for_server_key "$key")" != "set" ]]; then
            append_strict_blocker "Server/deploy secret $key is missing or placeholder in Config/production.env."
        fi
    done

    summary_commit="$(summary_git_commit "$latest_summary")"
    for evidence in \
        "summary:$latest_summary" \
        "gallery:$latest_gallery" \
        "contact sheet:$latest_contact_sheet"; do
        local evidence_label="${evidence%%:*}"
        local evidence_file="${evidence#*:}"
        if [[ -z "$evidence_file" || ! -f "$evidence_file" ]]; then
            append_strict_blocker "Simulator QA $evidence_label is not generated yet."
        elif [[ -z "$summary_commit" || "$summary_commit" != "$current_commit" ]]; then
            append_strict_blocker "Simulator QA $evidence_label is stale or has unknown commit; regenerate with scripts/qa-simulator-seeds.sh."
        fi
    done

    same_phone_commit="$(hardware_record_git_commit "$latest_same_phone_record")"
    same_phone_completion="$(hardware_record_completion_status "$latest_same_phone_record")"
    same_phone_simulator_evidence="$(hardware_record_simulator_evidence_status "$latest_same_phone_record")"
    if [[ -z "$latest_same_phone_record" || "$same_phone_commit" != "$current_commit" ]]; then
        append_strict_blocker "Same-phone hardware QA record is missing or stale."
    elif [[ "$same_phone_completion" != "filled; review manually" ]]; then
        append_strict_blocker "Same-phone hardware QA record is not launch-complete: $same_phone_completion."
    elif [[ "$same_phone_simulator_evidence" != "simulator evidence current" ]]; then
        append_strict_blocker "Same-phone hardware QA record does not point to current simulator evidence: $same_phone_simulator_evidence."
    fi

    child_ipad_commit="$(hardware_record_git_commit "$latest_child_ipad_record")"
    child_ipad_completion="$(hardware_record_completion_status "$latest_child_ipad_record")"
    child_ipad_simulator_evidence="$(hardware_record_simulator_evidence_status "$latest_child_ipad_record")"
    if [[ -z "$latest_child_ipad_record" || "$child_ipad_commit" != "$current_commit" ]]; then
        append_strict_blocker "Child-iPad hardware QA record is missing or stale."
    elif [[ "$child_ipad_completion" != "filled; review manually" ]]; then
        append_strict_blocker "Child-iPad hardware QA record is not launch-complete: $child_ipad_completion."
    elif [[ "$child_ipad_simulator_evidence" != "simulator evidence current" ]]; then
        append_strict_blocker "Child-iPad hardware QA record does not point to current simulator evidence: $child_ipad_simulator_evidence."
    fi
}

latest_summary="$(relative_latest_path "$ROOT_DIR/.build/qa-simulator-seeds" "summary.md")"
latest_gallery="$(relative_latest_path "$ROOT_DIR/.build/qa-simulator-seeds" "gallery.html")"
latest_contact_sheet="$(relative_latest_path "$ROOT_DIR/.build/qa-simulator-seeds" "contact-sheet.png")"
latest_same_phone_record="$(relative_latest_record "same-phone")"
latest_child_ipad_record="$(relative_latest_record "child-ipad")"

echo "Childlock launch readiness"
echo
echo "Git: $(git_status_line)"
echo
echo "App-facing build settings"
echo "- SUPABASE_URL: $(status_for_app_key "SUPABASE_URL")"
echo "- SUPABASE_PUBLISHABLE_KEY: $(status_for_app_key "SUPABASE_PUBLISHABLE_KEY")"
echo "- REVENUECAT_API_KEY: $(status_for_app_key "REVENUECAT_API_KEY")"
echo "- GOOGLE_IOS_CLIENT_ID: $(status_for_app_key "GOOGLE_IOS_CLIENT_ID")"
echo "- GOOGLE_WEB_CLIENT_ID: $(status_for_app_key "GOOGLE_WEB_CLIENT_ID")"
echo "- GOOGLE_REVERSED_CLIENT_ID: $(status_for_app_key "GOOGLE_REVERSED_CLIENT_ID")"
echo "- Google OAuth build: $(google_oauth_status)"
echo
echo "Server/deploy secrets"
echo "- SUPABASE_PROJECT_REF: $(status_for_server_key "SUPABASE_PROJECT_REF")"
echo "- SUPABASE_ACCESS_TOKEN: $(status_for_server_key "SUPABASE_ACCESS_TOKEN")"
echo "- SUPABASE_SERVICE_ROLE_KEY (optional local fallback): $(status_for_server_key "SUPABASE_SERVICE_ROLE_KEY")"
echo "- REVENUECAT_WEBHOOK_SECRET: $(status_for_server_key "REVENUECAT_WEBHOOK_SECRET")"
if server_secret_next_steps_needed; then
    echo "  Fill Config/production.env from Config/production.env.example."
    echo "  Keep these server-only; do not paste them into app xcconfig files."
    echo "  Deploy after filling: scripts/deploy-production-backend.sh"
    echo "  RevenueCat webhook URL: https://jkncpveupvozsmbbkvgq.supabase.co/functions/v1/revenuecat-webhook"
fi
echo
echo "QA evidence"
echo "- Latest simulator summary: $(describe_evidence_path "$latest_summary" "$(summary_git_commit "$latest_summary")")"
echo "- Latest simulator gallery: $(describe_evidence_path "$latest_gallery" "$(summary_git_commit "$latest_summary")")"
echo "- Latest simulator contact sheet: $(describe_evidence_path "$latest_contact_sheet" "$(summary_git_commit "$latest_summary")")"
echo "- Latest same-phone record: $(describe_hardware_record "$latest_same_phone_record" "$(hardware_record_git_commit "$latest_same_phone_record")")"
echo "- Latest child-iPad record: $(describe_hardware_record "$latest_child_ipad_record" "$(hardware_record_git_commit "$latest_child_ipad_record")")"
echo
echo "TestFlight hardware gates"
echo "- Same-phone shield loop: required before launch"
echo "- Child-iPad shield loop: required if iPad support stays in App Store copy"
echo "- Google sign-in: required only when Google OAuth build is configured and the button is visible"
echo
echo "Useful commands"
echo "- ./build-validation.sh"
echo "- REQUIRE_GOOGLE_OAUTH=1 ./build-validation.sh"
echo "- scripts/deploy-production-backend.sh"
echo "- scripts/check-app-store-submission-copy.sh"
echo "- scripts/launch-readiness-status.sh --strict"
echo "- scripts/prepare-testflight-qa.sh <testflight-build>"
echo "- scripts/new-hardware-qa-record.sh same-phone <testflight-build>"
echo "- scripts/new-hardware-qa-record.sh child-ipad <testflight-build>"

if [[ "$STRICT_MODE" -eq 1 ]]; then
    collect_strict_blockers
    echo
    echo "Strict launch gate"
    if (( ${#strict_blockers[@]} == 0 )); then
        echo "- PASS: no launch blockers detected by this local gate."
        exit 0
    fi

    echo "- BLOCKED: do not submit to public App Review yet."
    for blocker in "${strict_blockers[@]}"; do
        echo "  - $blocker"
    done
    exit 1
fi
