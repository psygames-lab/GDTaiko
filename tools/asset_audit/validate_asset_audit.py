from __future__ import annotations

import sys
from pathlib import Path


REQUIRED_HEADERS = [
    "Asset ID",
    "Path",
    "Type",
    "Source",
    "Author",
    "License",
    "Redistribution",
    "Commercial Use",
    "Status",
    "Include In Repo",
    "Include In Release",
    "Notes",
]

CLEAR_LICENSES = {
    "MIT",
    "CC0",
    "CC0-1.0",
    "CC-BY",
    "CC-BY-4.0",
    "CC-BY-SA",
    "Apache-2.0",
    "BSD-2-Clause",
    "BSD-3-Clause",
}

VALID_STATUSES = {"local_reference", "repo_allowed", "release_allowed", "blocked"}
YES_NO_HEADERS = {"Redistribution", "Commercial Use", "Include In Repo", "Include In Release"}


def parse_table(text: str) -> list[dict[str, str]]:
    headers = parse_headers(text)
    if not headers:
        return []
    lines = [line.strip() for line in text.splitlines() if line.strip().startswith("|")]
    if len(lines) < 3:
        return []
    rows: list[dict[str, str]] = []
    for line in lines[2:]:
        values = [part.strip() for part in line.strip("|").split("|")]
        if len(values) != len(headers):
            continue
        rows.append(dict(zip(headers, values)))
    return rows


def malformed_row_errors(text: str) -> list[str]:
    errors: list[str] = []
    headers = parse_headers(text)
    if not headers:
        return errors
    lines = [line.strip() for line in text.splitlines() if line.strip().startswith("|")]
    for index, line in enumerate(lines[2:], start=1):
        values = [part.strip() for part in line.strip("|").split("|")]
        if len(values) != len(headers):
            errors.append(f"row {index}: expected {len(headers)} columns, got {len(values)}")
    return errors


def parse_headers(text: str) -> list[str]:
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith("|"):
            return [part.strip() for part in stripped.strip("|").split("|")]
    return []


def validate_document(text: str) -> list[str]:
    errors: list[str] = []
    headers = parse_headers(text)
    if not headers:
        errors.append("missing asset audit table")
        return errors
    for header in REQUIRED_HEADERS:
        if header not in headers:
            errors.append(f"missing header {header}")
    errors.extend(malformed_row_errors(text))
    errors.extend(validate_rows(parse_table(text)))
    return errors


def validate_rows(rows: list[dict[str, str]]) -> list[str]:
    errors: list[str] = []
    seen_ids: set[str] = set()
    for index, row in enumerate(rows, start=1):
        for header in REQUIRED_HEADERS:
            if header not in row or row[header] == "":
                errors.append(f"row {index}: missing {header}")

        asset_id = row.get("Asset ID", "")
        if asset_id in seen_ids:
            errors.append(f"row {index}: duplicate asset id {asset_id}")
        if asset_id:
            seen_ids.add(asset_id)

        status = row.get("Status", "")
        if status and status not in VALID_STATUSES:
            errors.append(f"row {index}: invalid status {status}")

        for header in YES_NO_HEADERS:
            value = row.get(header, "").lower()
            if value not in {"yes", "no"}:
                errors.append(f"row {index}: {header} must be yes or no")

        include_release = row.get("Include In Release", "").lower() == "yes"
        include_repo = row.get("Include In Repo", "").lower() == "yes"
        license_name = row.get("License", "")
        redistribution = row.get("Redistribution", "").lower()
        commercial_use = row.get("Commercial Use", "").lower()

        if include_release and status != "release_allowed":
            errors.append(f"row {index}: release inclusion requires status=release_allowed")
        if status == "blocked" and (include_repo or include_release):
            errors.append(f"row {index}: blocked asset cannot be included")
        if include_release or status == "release_allowed":
            if license_name not in CLEAR_LICENSES:
                errors.append(f"row {index}: release asset requires clear license")
            if redistribution != "yes":
                errors.append(f"row {index}: release asset requires redistribution=yes")
            if commercial_use != "yes":
                errors.append(f"row {index}: release asset requires commercial use=yes")
        if include_release and not include_repo:
            errors.append(f"row {index}: release asset must also be included in repo")
    return errors


def main(argv: list[str] | None = None) -> int:
    args = argv if argv is not None else sys.argv[1:]
    path = Path(args[0]) if args else Path("docs/ASSET_AUDIT.md")
    errors = validate_document(path.read_text(encoding="utf-8"))
    for error in errors:
        print(error)
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
