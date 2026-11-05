"""Run three alternating rendered A/B pairs and compare exact game outcomes."""

import argparse
import json
from pathlib import Path
import subprocess


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True)
    parser.add_argument("--output", default="output/telemetry_benchmark")
    args = parser.parse_args()
    project = Path(__file__).resolve().parents[2]
    output = (project / args.output).resolve()
    output.mkdir(parents=True, exist_ok=True)
    runs = []
    pairs = []
    for pair, order in enumerate(((False, True), (True, False), (False, True)), 1):
        paired = {}
        for capture in order:
            label = f"pair_{pair}_{'on' if capture else 'off'}"
            path = output / f"{label}.json"
            command = [
                args.godot, "--path", str(project),
                "--script", "tools/telemetry_benchmark/run.gd", "--",
                f"--output={path.as_posix()}",
            ]
            if capture:
                command.append("--capture")
            print(f"Running {label} (2 s warmup + 10 s measured)", flush=True)
            result = subprocess.run(command, text=True, capture_output=True, timeout=90)
            (output / f"{label}.log").write_text(result.stdout + result.stderr, encoding="utf-8")
            if result.returncode or "SCRIPT ERROR" in result.stderr or "SCRIPT ERROR" in result.stdout:
                raise RuntimeError(f"{label} failed; see {output / (label + '.log')}")
            data = json.loads(path.read_text(encoding="utf-8"))
            paired[capture] = data
            runs.append({"pair": pair, **{key: value for key, value in data.items()
                                         if key not in ("judgment_trace", "notes")}})
            print(json.dumps({"run": label, "frame_ms": data["frame_ms"]}), flush=True)
        equal = all(paired[False][key] == paired[True][key]
                    for key in ("judgment_trace", "notes", "result", "inputs", "simulation_steps"))
        pairs.append({"pair": pair, "exact_judgments_equal": equal,
                      "capture_complete": paired[True]["recording"]["complete"]})
    summary = {"runs": runs, "comparisons": pairs}
    (output / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    if not all(pair["exact_judgments_equal"] and pair["capture_complete"] for pair in pairs):
        raise SystemExit("FAIL: outcomes differ or capture incomplete")
    print(f"PASS: all three pairs have exact game outcomes and complete capture. {output / 'summary.json'}")


if __name__ == "__main__":
    main()
