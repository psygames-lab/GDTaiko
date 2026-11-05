"""Check a converted generate_hed_fixture.gd recording against its source facts."""

import argparse
import csv
import json
import math
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("raw", type=Path)
    parser.add_argument("export", type=Path)
    args = parser.parse_args()
    events = [json.loads(line) for line in args.raw.read_text(encoding="utf-8").splitlines()]
    raw = {event["event_id"]: event for event in events}
    with (args.export / "events.tsv").open(encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle, delimiter="\t"))
    report = json.loads((args.export / "conversion_report.json").read_text(encoding="utf-8"))
    assert report["success"] and not report["hed_issues"], report
    assert (len(events), len(rows), report["excluded_events"]) == (27, 25, 2)
    assert all(rule["count"] > 0 for rule in report["rules"]), "Fixture must exercise every mapping rule"
    assert {row["source_event_id"] for row in rows} == {
        event["event_id"] for event in events if event["event_type"] == "gameplay"
    }, "Every gameplay record must survive export exactly once"
    responses = {row["input_index"]: row for row in rows if row["event_tag"] == "player_response"}
    assert sum(row["event_kind"] == "manual_response" for row in rows) == 5
    assert sum(row["event_kind"] == "replay_response" for row in rows) == 4
    for row in rows:
        event = raw[row["source_event_id"]]
        payload = event["payload"]
        assert float(row["onset"]) == event["session_elapsed_usec"] / 1_000_000
        assert float(row["duration"]) == 0
        if event["event_tag"] == "player_response":
            assert row["event_kind"] == payload["source"] + "_response"
        if event["event_tag"] in {"note_hit", "empty_hit", "roll_hit", "balloon_hit"}:
            response = responses[row["input_index"]]
            assert response["input_source"] == row["input_source"] == payload["source"]
            assert response["song_time"] == row["song_time"]
        if event["event_tag"] in {"note_miss", "roll_end", "balloon_end"}:
            assert row["input_index"] == "0" and row["input_source"] == "game"
        if event["event_tag"] == "note_hit":
            assert math.isclose(float(row["timing_error"]), payload["timing_error_ms"] / 1000, abs_tol=1e-12)
            assert float(row["scheduled_time"]) == payload["scheduled_time_sec"]
            assert float(row["onset"]) != float(row["scheduled_time"]), "Scheduled notes must not replace observed timestamps"
    print("PASS: all HED mapping rules, manual/replay distinction, response/outcome links, timing units and source timestamps")


if __name__ == "__main__":
    main()
