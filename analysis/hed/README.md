# GDTaiko offline HED mapping

`mapping.json` extracts captured game facts. `events.json` supplies standard HED
8.3.0 annotations. Neither file is read by the game or PsyGodot capture runtime.
The converter belongs to the sibling PsyGodot repository; no game-specific
conversion code is added there.

With the repositories next to each other, install PsyGodot's offline HED
requirements and run its converter with the Python environment containing
`hedtools`:

```powershell
../psygodot/.venv/Scripts/python.exe ../psygodot/analysis/convert_hed.py RAW_JSONL --manifest SESSION_MANIFEST --mapping analysis/hed/mapping.json --output output/hed_run
```

Replace `RAW_JSONL` and `SESSION_MANIFEST` with a paired recording. Choose a new
output directory for each conversion. Successful output consists of
`events.tsv`, `events.json`, and `conversion_report.json`; raw files are unchanged.
The report must pass raw completeness, mapping coverage and official HED
validation. An unknown event or missing required field must be resolved before
the export is accepted.

## What the mapping means

- `manual_response` describes an input processed through the live input path.
  `replay_response` describes controller replay execution, never a new human
  participant response. This is based on the game's source field, not inferred
  from the note judgment.
- `note_hit`, `note_miss`, `empty_hit`, roll and balloon events describe game
  controller processing. They do not claim that visual or auditory feedback
  physically appeared at the captured time.
- `song_start` and `song_end` are software song-state transitions. Pause and
  resume are separate control change points. All exported rows have duration
  zero as observations; they are not sustained song, note, or pause intervals.
- `onset` is recorder-relative observation time. `song_time` is the game's
  timing coordinate, and `scheduled_time` is the planned chart coordinate.
  Neither replaces `onset`. `timing_error` converts the game's millisecond
  difference to seconds; it is neither reaction time nor physical input latency.
- The song-start hook happens just before recorder initialization. Its original
  `observed_timestamp_usec` is retained as an extra column; the exported row
  keeps its actual recorder observation time, so it does not pretend this is
  an audio start measurement.
- `source_event_id` links each output row to its raw event. Positive
  `input_index` values link responses and results within the same song; zero
  identifies autonomous expiry processing. `note_id` links long-note updates.
- Recorder `session_start` and `session_end` are explicitly excluded as
  bookkeeping. Their raw records and manifest remain available and validated.
  Song boundaries are exported. All other unknown events fail conversion.
- This mapping targets the default bridge with raw input and frame sampling
  disabled. Optional raw-input, frame-sample or marker records require explicit
  study-specific mapping or exclusion; they are not silently discarded.
- Game scores and perfect/good/bad labels are retained as game data. No
  cognitive construct, scientific correctness, handedness or physical key is
  inferred from lane names or performance.

The mapping uses standard HED event and agent tags plus `Label/` values for
game-specific concepts. These are ordinary HED labels, not a custom schema.
Review or copy the mapping for study-specific experimental roles before use.

## Reproducible coverage fixture

The fixture creates original notes and exercises the real controller and bridge
without audio or imported songs. It covers manual/replay responses, normal
judgments, empty hits, expiry, roll/balloon processing, pause/resume and song end.

```powershell
& 'D:/Godot/Godot_v4.6.2-stable_win64_console.exe' --headless --path . --script tests/telemetry/generate_hed_fixture.gd
```

Use the printed `RAW` and `MANIFEST` paths in the converter command above.
Then check the fixture's converted data against its source facts:

```powershell
python tests/telemetry/check_hed_export.py RAW_JSONL output/hed_run
```

This verifies coverage of all 15 rules (13 exported kinds and two explicit
exclusions), manual/replay separation, response-to-outcome links, source timing
and millisecond-to-second conversion. The fixture contains 27 raw events and
exports 25 gameplay rows; HED 8.3.0 validation must report no issues.

Generated recordings and exports remain under ignored `output/`; no participant
recording, copyrighted chart or audio is included as a repository fixture.

Reference: https://www.hedtags.org/hed-specification/03_HED_formats.html
