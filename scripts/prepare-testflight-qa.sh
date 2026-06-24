#!/bin/zsh
set -euo pipefail

# Prepare the physical TestFlight QA packet for a specific build. This keeps
# same-phone and child-iPad evidence together so the launch gate is harder to
# half-run by accident.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

usage() {
    cat <<EOF
Usage: scripts/prepare-testflight-qa.sh <testflight-build-number>

Creates fresh hardware QA records for:
  1. same-phone
  2. child-ipad

The records are written under ignored .build/hardware-qa-records output.
EOF
}

build_number="${1:-}"
if [[ "$build_number" == "-h" || "$build_number" == "--help" ]]; then
    usage
    exit 0
fi

if [[ -z "$build_number" ]]; then
    usage
    exit 1
fi

echo "=== Childlock TestFlight QA Packet ==="
echo "Build: $build_number"
echo ""

echo "Current readiness:"
"$ROOT_DIR/scripts/launch-readiness-status.sh"
echo ""

echo "Creating physical QA records..."
same_phone_output="$("$ROOT_DIR/scripts/new-hardware-qa-record.sh" same-phone "$build_number")"
child_ipad_output="$("$ROOT_DIR/scripts/new-hardware-qa-record.sh" child-ipad "$build_number")"

same_phone_record="$(printf "%s\n" "$same_phone_output" | tail -n 1)"
child_ipad_record="$(printf "%s\n" "$child_ipad_output" | tail -n 1)"

echo ""
echo "Records:"
echo "- Same-phone: $same_phone_record"
echo "- Child iPad: $child_ipad_record"
echo ""

cat <<EOF
Test order:
1. Run same-phone first.
   Parent sets up on the shared iPhone, locks the parent dashboard, hands the
   phone over, child consumes selected content, shield appears after threshold,
   child solves the brain break, sees Swipe up, returns to unlocked content,
   and the dashboard stays PIN-gated.

2. Run child-iPad if iPad support remains in launch copy.
   Install/configure Childlock on the child iPad itself. A parent-only iPhone
   install is not remote iPad control for this launch.

3. Run one denied-notification pass.
   After Start Brain Break, press Home and open Childlock. The pending
   challenge should still appear.

4. Run one second full shield loop on the same device.
   This proves monitoring re-arms after challenge completion.

Checklist:
- docs/QA_TESTFLIGHT_CHECKLIST.md

Launch is not ready until the generated records are filled with passing results
and scripts/launch-readiness-status.sh no longer reports pending or incomplete
hardware QA for the required scenarios.
EOF
