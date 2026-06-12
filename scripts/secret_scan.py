#!/usr/bin/env python3
"""Fail CI if tracked files contain likely secrets.

The scanner reports file paths and rule names only. It intentionally does not
print matched values, so CI logs do not become another secret leak.
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path


DENIED_TRACKED_PATHS = {
    ".env",
    ".vercel/project.json",
    "backend/.env",
    "backend/firebase-service-account.json",
    "android/app/google-services.json",
    "ios/Runner/GoogleService-Info.plist",
    "lib/firebase_options.dart",
}

DENIED_SUFFIXES = (
    ".keystore",
    ".jks",
    ".mobileprovision",
    ".p12",
    ".p8",
    ".pem",
)

CONTENT_RULES = {
    "private_key_block": re.compile(rb"-----BEGIN (?:RSA |EC |OPENSSH |)?PRIVATE KEY-----"),
    "google_api_key": re.compile(rb"AIza[0-9A-Za-z_-]{20,}"),
    "database_url": re.compile(rb"(?:postgres(?:ql)?|mysql|mongodb)://[^\s\"']+"),
    "bearer_token": re.compile(rb"Bearer\s+[A-Za-z0-9._~+/=-]{20,}"),
    "jwt": re.compile(rb"eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}"),
    "firebase_admin_email": re.compile(
        rb"firebase-adminsdk-[A-Za-z0-9_-]+@[A-Za-z0-9_-]+\.iam\.gserviceaccount\.com"
    ),
}

ALLOWED_PATHS = {
    "backend/.env.example",
}

SKIP_PREFIXES = (
    "docs/",
)

SKIP_SUFFIXES = (
    ".lock",
    ".png",
    ".jpg",
    ".jpeg",
    ".gif",
    ".webp",
    ".pdf",
    ".zip",
)


def tracked_files() -> list[str]:
    output = subprocess.check_output(["git", "ls-files"], text=True)
    return [line for line in output.splitlines() if line]


def should_scan(path: str) -> bool:
    if path in ALLOWED_PATHS:
        return False
    if path.startswith(SKIP_PREFIXES):
        return False
    if path.endswith(SKIP_SUFFIXES):
        return False
    return True


def main() -> int:
    findings: list[tuple[str, str]] = []

    for path in tracked_files():
        if path in DENIED_TRACKED_PATHS or path.endswith(DENIED_SUFFIXES):
            findings.append((path, "tracked_secret_file"))
            continue

        if not should_scan(path):
            continue

        file_path = Path(path)
        if not file_path.exists() or not file_path.is_file():
            continue

        try:
            data = file_path.read_bytes()
        except OSError:
            continue

        for rule_name, rule in CONTENT_RULES.items():
            if rule.search(data):
                findings.append((path, rule_name))

    if findings:
        print("Secret scan failed. Remove the tracked secret or move it to CI/provider secrets.")
        for path, rule_name in sorted(set(findings)):
            print(f"- {path}: {rule_name}")
        return 1

    print("Secret scan passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
