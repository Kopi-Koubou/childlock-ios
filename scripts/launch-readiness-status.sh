#!/bin/zsh
set -euo pipefail

# Print a no-secret snapshot of launch readiness. This intentionally reports
# only set/missing/invalid status, never credential values.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_CONFIG_BASE="$ROOT_DIR/Config/AppSecrets.xcconfig"
APP_CONFIG_LOCAL="$ROOT_DIR/Config/AppSecrets.local.xcconfig"
SERVER_CONFIG="$ROOT_DIR/Config/production.env"

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
        echo "${latest#$ROOT_DIR/}"
    else
        echo "not generated yet"
    fi
}

relative_latest_record() {
    local scenario="$1"
    local latest

    latest="$(find "$ROOT_DIR/.build/hardware-qa-records" -name "${scenario}_*.md" -type f -print 2>/dev/null | sort | tail -n 1)"
    if [[ -n "$latest" ]]; then
        echo "${latest#$ROOT_DIR/}"
    else
        echo "not generated yet"
    fi
}

git_status_line() {
    local branch
    local commit
    local dirty="clean"

    branch="$(git -C "$ROOT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")"
    commit="$(git -C "$ROOT_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")"
    if ! git -C "$ROOT_DIR" diff --quiet || ! git -C "$ROOT_DIR" diff --cached --quiet; then
        dirty="dirty"
    fi

    echo "$branch $commit ($dirty)"
}

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
echo "- SUPABASE_SERVICE_ROLE_KEY: $(status_for_server_key "SUPABASE_SERVICE_ROLE_KEY")"
echo "- REVENUECAT_WEBHOOK_SECRET: $(status_for_server_key "REVENUECAT_WEBHOOK_SECRET")"
echo
echo "QA evidence"
echo "- Latest simulator summary: $(relative_latest_path "$ROOT_DIR/.build/qa-simulator-seeds" "summary.md")"
echo "- Latest simulator gallery: $(relative_latest_path "$ROOT_DIR/.build/qa-simulator-seeds" "gallery.html")"
echo "- Latest same-phone record: $(relative_latest_record "same-phone")"
echo "- Latest child-iPad record: $(relative_latest_record "child-ipad")"
echo
echo "TestFlight hardware gates"
echo "- Same-phone shield loop: required before launch"
echo "- Child-iPad shield loop: required if iPad support stays in App Store copy"
echo "- Google sign-in: required only when Google OAuth build is configured and the button is visible"
echo
echo "Useful commands"
echo "- ./build-validation.sh"
echo "- REQUIRE_GOOGLE_OAUTH=1 ./build-validation.sh"
echo "- scripts/new-hardware-qa-record.sh same-phone <testflight-build>"
echo "- scripts/new-hardware-qa-record.sh child-ipad <testflight-build>"
