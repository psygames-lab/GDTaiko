import unittest

from validate_asset_audit import parse_table, validate_document, validate_rows


class AssetAuditValidationTests(unittest.TestCase):
    def test_valid_rows_pass(self) -> None:
        text = """
| Asset ID | Path | Type | Source | Author | License | Redistribution | Commercial Use | Status | Include In Repo | Include In Release | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| a | assets/a.png | skin | original | me | MIT | yes | yes | release_allowed | yes | yes | ok |
"""
        rows = parse_table(text)

        self.assertEqual(validate_rows(rows), [])

    def test_release_asset_requires_clear_license(self) -> None:
        text = """
| Asset ID | Path | Type | Source | Author | License | Redistribution | Commercial Use | Status | Include In Repo | Include In Release | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| a | assets/a.png | skin | unknown | unknown | unknown | unknown | unknown | release_allowed | yes | yes | bad |
"""
        rows = parse_table(text)
        errors = validate_rows(rows)

        self.assertTrue(any("clear license" in error for error in errors))

    def test_duplicate_asset_ids_are_rejected(self) -> None:
        text = """
| Asset ID | Path | Type | Source | Author | License | Redistribution | Commercial Use | Status | Include In Repo | Include In Release | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| a | assets/a.png | skin | original | me | MIT | yes | yes | release_allowed | yes | yes | ok |
| a | assets/b.png | skin | original | me | MIT | yes | yes | release_allowed | yes | yes | duplicate |
"""
        rows = parse_table(text)
        errors = validate_rows(rows)

        self.assertTrue(any("duplicate asset id a" in error for error in errors))

    def test_missing_header_table_without_rows_is_rejected(self) -> None:
        text = """
| Asset ID | Path | Type |
| --- | --- | --- |
"""
        errors = validate_document(text)

        self.assertTrue(any("missing header License" in error for error in errors))

    def test_malformed_row_width_is_rejected(self) -> None:
        text = """
| Asset ID | Path | Type | Source | Author | License | Redistribution | Commercial Use | Status | Include In Repo | Include In Release | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| a | assets/a.png | skin | original | me | MIT | yes | yes | release_allowed | yes | yes | bad | extra |
"""
        errors = validate_document(text)

        self.assertTrue(any("expected 12 columns" in error for error in errors))

    def test_release_inclusion_requires_release_allowed_status(self) -> None:
        text = """
| Asset ID | Path | Type | Source | Author | License | Redistribution | Commercial Use | Status | Include In Repo | Include In Release | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| a | assets/a.png | skin | original | me | MIT | yes | yes | repo_allowed | yes | yes | bad |
"""
        errors = validate_document(text)

        self.assertTrue(any("release inclusion requires status=release_allowed" in error for error in errors))

    def test_blocked_asset_cannot_be_included(self) -> None:
        text = """
| Asset ID | Path | Type | Source | Author | License | Redistribution | Commercial Use | Status | Include In Repo | Include In Release | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| a | assets/a.png | skin | original | me | MIT | yes | yes | blocked | yes | no | bad |
"""
        errors = validate_document(text)

        self.assertTrue(any("blocked asset cannot be included" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
