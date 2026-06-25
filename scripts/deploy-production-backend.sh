#!/bin/zsh
set -euo pipefail

# Deploy the production Supabase backend without echoing secret values.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SERVER_CONFIG="$ROOT_DIR/Config/production.env"
FUNCTION_NAME="revenuecat-webhook"
SKIP_DB_PUSH=0

usage() {
    cat <<EOF
Usage: scripts/deploy-production-backend.sh [--skip-db-push]

Deploys the Childlock Supabase migration and RevenueCat webhook function using
the ignored Config/production.env file.

Options:
  --skip-db-push  Deploy the function/secrets without running supabase db push.
  -h, --help      Show this help.
EOF
}

case "${1:-}" in
    "")
        ;;
    --skip-db-push)
        SKIP_DB_PUSH=1
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

is_missing_value() {
    local value="$1"
    [[ -z "$value" || "$value" == *"YOUR_"* || "$value" == *"_YOUR_"* || "$value" == \$\(* ]]
}

require_env_value() {
    local key="$1"
    local value="${(P)key:-}"

    if is_missing_value "$value"; then
        echo "Missing required value in Config/production.env: $key" >&2
        exit 1
    fi
}

echo "Loading production backend environment from Config/production.env..."
if [[ ! -f "$SERVER_CONFIG" ]]; then
    echo "Missing Config/production.env. Copy Config/production.env.example and fill the production values first." >&2
    exit 1
fi

set -a
source "$SERVER_CONFIG"
set +a

require_env_value "SUPABASE_PROJECT_REF"
require_env_value "SUPABASE_ACCESS_TOKEN"
require_env_value "SUPABASE_SERVICE_ROLE_KEY"
require_env_value "REVENUECAT_WEBHOOK_SECRET"

if ! command -v supabase >/dev/null 2>&1; then
    echo "Supabase CLI is not installed or not on PATH." >&2
    echo "Install it first, then rerun this script: https://supabase.com/docs/guides/cli" >&2
    exit 1
fi

export SUPABASE_ACCESS_TOKEN
SUPABASE_URL="${SUPABASE_URL:-https://${SUPABASE_PROJECT_REF}.supabase.co}"

echo "Linking Supabase project $SUPABASE_PROJECT_REF..."
supabase link --project-ref "$SUPABASE_PROJECT_REF"

if [[ "$SKIP_DB_PUSH" -eq 0 ]]; then
    echo "Applying database migrations..."
    supabase db push
else
    echo "Skipping database migrations (--skip-db-push)."
fi

echo "Deploying Edge Function: $FUNCTION_NAME..."
supabase functions deploy "$FUNCTION_NAME"

echo "Setting Edge Function runtime secrets..."
supabase secrets set \
    SUPABASE_URL="$SUPABASE_URL" \
    SUPABASE_SERVICE_ROLE_KEY="$SUPABASE_SERVICE_ROLE_KEY" \
    REVENUECAT_WEBHOOK_SECRET="$REVENUECAT_WEBHOOK_SECRET"

cat <<EOF

Production backend deploy complete.

RevenueCat webhook URL:
https://${SUPABASE_PROJECT_REF}.supabase.co/functions/v1/${FUNCTION_NAME}

RevenueCat Authorization bearer token:
Use the same REVENUECAT_WEBHOOK_SECRET value from Config/production.env.
EOF
