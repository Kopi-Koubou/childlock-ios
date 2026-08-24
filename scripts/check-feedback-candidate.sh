#!/bin/zsh
set -euo pipefail

# Verify that the normal Release candidate resolves rapid testing OFF without
# printing any other resolved build settings or app-facing configuration.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="Release"
BUILT_APP=""

usage() {
    cat <<EOF
Usage: scripts/check-feedback-candidate.sh [--configuration NAME] [--built-app PATH]

Checks the resolved Childlock app build setting and, when supplied, the built
app Info.plist. Both must set Childlock rapid testing to NO.
EOF
}

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --configuration)
            [[ "$#" -ge 2 ]] || { usage; exit 2; }
            CONFIGURATION="$2"
            shift 2
            ;;
        --built-app)
            [[ "$#" -ge 2 ]] || { usage; exit 2; }
            BUILT_APP="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            usage
            exit 2
            ;;
    esac
done

cd "$ROOT_DIR"

resolved_rapid_testing="$({
    xcodebuild \
        -project Childlock.xcodeproj \
        -target Childlock \
        -configuration "$CONFIGURATION" \
        -showBuildSettings 2>&1
} | awk -F ' = ' '
    $1 ~ /^[[:space:]]*CHILDLOCK_RAPID_TESTING$/ {
        value = $2
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
        found = 1
    }
    END {
        if (!found) exit 1
        print value
    }
')"

if [[ "$resolved_rapid_testing" != "NO" ]]; then
    echo "ERROR: $CONFIGURATION resolves CHILDLOCK_RAPID_TESTING=$resolved_rapid_testing; feedback candidates require NO."
    echo "Remove any local override before building the feedback candidate."
    exit 1
fi

echo "OK resolved $CONFIGURATION CHILDLOCK_RAPID_TESTING=NO"

if [[ -n "$BUILT_APP" ]]; then
    info_plist="$BUILT_APP/Info.plist"
    if [[ ! -f "$info_plist" ]]; then
        echo "ERROR: built app Info.plist not found at $info_plist"
        exit 1
    fi

    built_value="$(plutil -extract ChildlockRapidTestingEnabled raw -o - "$info_plist")"
    if [[ "$built_value" != "NO" ]]; then
        echo "ERROR: built app has ChildlockRapidTestingEnabled=$built_value; feedback candidates require NO."
        exit 1
    fi

    echo "OK built app ChildlockRapidTestingEnabled=NO"
fi
