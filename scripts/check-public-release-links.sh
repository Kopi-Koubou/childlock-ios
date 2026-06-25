#!/bin/bash
# Verify public Childlock links used by App Store Connect and in-app settings.

set -euo pipefail

URLS=(
    "https://kouboulabs.com/childlock/support"
    "https://kouboulabs.com/childlock/privacy"
    "https://kouboulabs.com/childlock/terms"
)

echo "=== Childlock public release links ==="
echo ""

for url in "${URLS[@]}"; do
    response="$(curl -LsS -o /dev/null -w "%{http_code} %{content_type} %{url_effective}" "$url")"
    http_code="${response%% *}"
    rest="${response#* }"
    content_type="${rest%% *}"
    effective_url="${rest#* }"

    if [[ "$http_code" != 2* ]]; then
        echo "❌ $url returned HTTP $http_code"
        exit 1
    fi

    if [[ "$content_type" != text/html* ]]; then
        echo "❌ $url returned unexpected content type: $content_type"
        exit 1
    fi

    echo "✅ $url -> $http_code $content_type ($effective_url)"
done

echo ""
echo "All public release links are live."
