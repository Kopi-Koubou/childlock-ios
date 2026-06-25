#!/bin/zsh
set -euo pipefail

# Validate paste-ready App Store Connect copy against local launch invariants.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

python3 - "$ROOT_DIR" <<'PY'
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
metadata_path = root / "docs" / "APP_STORE_CONNECT_METADATA.md"
review_path = root / "docs" / "APP_REVIEW_NOTES.md"
privacy_path = root / "docs" / "APP_PRIVACY_LABELS.md"
service_path = root / "Sources" / "Childlock" / "Services" / "SubscriptionService.swift"

metadata = metadata_path.read_text(encoding="utf-8")
review_notes = review_path.read_text(encoding="utf-8")
privacy_labels = privacy_path.read_text(encoding="utf-8")
subscription_service = service_path.read_text(encoding="utf-8")

errors: list[str] = []
warnings: list[str] = []


def fenced_after(label: str) -> str:
    pattern = rf"{re.escape(label)}:\s*\n\s*```text\n(.*?)\n```"
    match = re.search(pattern, metadata, re.DOTALL)
    if not match:
        errors.append(f"Missing fenced metadata block for: {label}")
        return ""
    return match.group(1).strip()


def fenced_under_heading(heading: str) -> str:
    pattern = rf"## {re.escape(heading)}\s*\n\s*```text\n(.*?)\n```"
    match = re.search(pattern, metadata, re.DOTALL)
    if not match:
        errors.append(f"Missing fenced metadata section for: {heading}")
        return ""
    return match.group(1).strip()


def normalize_whitespace(value: str) -> str:
    return " ".join(value.split())


def swift_string_constant(name: str) -> str:
    pattern = rf"{re.escape(name)}\s*=\s*\"([^\"]+)\""
    match = re.search(pattern, subscription_service)
    if not match:
        errors.append(f"Missing SubscriptionService constant: {name}")
        return ""
    return match.group(1)


def check_max(label: str, value: str, maximum: int) -> None:
    count = len(value)
    if count > maximum:
        errors.append(f"{label} is {count} characters; App Store limit is {maximum}.")
    else:
        print(f"OK {label}: {count}/{maximum}")


app_name = fenced_after("App name")
subtitle = fenced_after("Subtitle")
promotional_text = fenced_after("Promotional text")
description = fenced_after("Description")
keywords = fenced_after("Keywords")
support_url = fenced_after("Support URL")
privacy_url = fenced_after("Privacy Policy URL")
terms_url = fenced_after("Terms URL")
review_block = fenced_under_heading("App Review Notes")
entitlement = fenced_after("RevenueCat entitlement")
products = [line.strip() for line in fenced_after("Products").splitlines() if line.strip()]
subscription_review_notes = fenced_after("Subscription review notes")

check_max("App name", app_name, 30)
check_max("Subtitle", subtitle, 30)
check_max("Promotional text", promotional_text, 170)
check_max("Description", description, 4000)
check_max("Keywords", keywords, 100)

if keywords.startswith(",") or keywords.endswith(",") or ",," in keywords:
    errors.append("Keywords must not start/end with a comma or contain empty entries.")

keyword_items = [item.strip().lower() for item in keywords.split(",") if item.strip()]
if len(keyword_items) != len(set(keyword_items)):
    errors.append("Keywords contain duplicates.")

expected_urls = {
    "Support URL": "https://kouboulabs.com/childlock/support",
    "Privacy Policy URL": "https://kouboulabs.com/childlock/privacy",
    "Terms URL": "https://kouboulabs.com/childlock/terms",
}
actual_urls = {
    "Support URL": support_url,
    "Privacy Policy URL": privacy_url,
    "Terms URL": terms_url,
}
for label, expected in expected_urls.items():
    actual = actual_urls[label]
    if actual != expected:
        errors.append(f"{label} is {actual!r}; expected {expected!r}.")
    for source_name, source in [
        ("App Review notes", review_notes),
        ("App Store metadata", metadata),
        ("Privacy labels", privacy_labels if label == "Privacy Policy URL" else ""),
    ]:
        if source and expected not in source:
            errors.append(f"{source_name} does not contain {expected}.")

monthly = swift_string_constant("monthlyProductID")
annual = swift_string_constant("annualProductID")
premium_entitlement = swift_string_constant("premiumEntitlementID")

if products != [monthly, annual]:
    errors.append(
        "Metadata product IDs do not match SubscriptionService: "
        f"metadata={products!r}, service={[monthly, annual]!r}."
    )
else:
    print("OK Product IDs match SubscriptionService.")

if entitlement != premium_entitlement:
    errors.append(
        "Metadata RevenueCat entitlement does not match SubscriptionService: "
        f"metadata={entitlement!r}, service={premium_entitlement!r}."
    )
else:
    print("OK RevenueCat entitlement matches SubscriptionService.")

review_sources = normalize_whitespace(review_notes) + " " + normalize_whitespace(review_block)
required_phrases = [
    "There is no separate username/password account",
    "Screen Time enforcement is available without purchase",
    "not presented as a parent-phone remote controller",
    "For a child iPad, install and configure Childlock on the iPad",
]
for phrase in required_phrases:
    if phrase not in review_sources:
        errors.append(f"Review notes are missing required phrase: {phrase}")

if "free trial" in (metadata + review_notes + subscription_review_notes).lower():
    errors.append("Submission copy mentions a free trial, but the app does not advertise unavailable trials.")

if "Data used to track users across apps and websites owned by other companies:" not in privacy_labels:
    errors.append("Privacy labels must include the tracking disclosure prompt.")
if "Raw Screen Time app selection token payloads" not in privacy_labels:
    errors.append("Privacy labels must state raw Screen Time selection token payloads are not collected.")

if warnings:
    print("\nWarnings:")
    for warning in warnings:
        print(f"- {warning}")

if errors:
    print("\nApp Store submission copy check failed:")
    for error in errors:
        print(f"- {error}")
    sys.exit(1)

print("\nApp Store submission copy is locally consistent.")
PY
