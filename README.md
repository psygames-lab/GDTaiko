# GDTaiko

GDTaiko is an independent Godot Taiko rhythm game. OpenTaiko is used as a behavioral reference, but implementation is Godot-native.

## Current Target

- Godot: `4.6.2.stable.official.71f334935`
- Runtime: Godot/GDScript
- Assets: original or explicitly audited before inclusion

## Current Phase 1 Status

- Godot project is available and `project.godot` is configured.
- `res://scenes/Main.tscn` launches gameplay flow.
- Sample chart/audio/note placeholders exist under `assets/sample/` and `assets/notes/`.
- Controls: `F` (Don), `J` (Ka), `Space` (Start).

## Run

```powershell
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --path .
```

The plain `godot` command is not currently on this machine's PATH.

## Optional PsyGodot Capture

GDTaiko remains an independent game. The optional integration sends gameplay
events to the shared PsyGodot framework through a game-specific bridge; scoring,
judgment rules, and the song clock remain owned by GDTaiko.

Capture is off by default. Enable it with:

```powershell
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --path . -- --psygodot
```

The game-specific bridge lives in `scripts/telemetry/psygodot_bridge.gd`.
The shared framework is vendored unchanged in `addons/psygodot/`; see its
`UPSTREAM.md` before updating it. Events are buffered on the game thread and
serialized/written by a background worker. Output goes to `user://psygodot`
(`%APPDATA%/Godot/app_userdata/GDTaiko/psygodot` on Windows). Each song creates
a raw JSONL file and a session manifest with chart metadata and recording counts.
Check the manifest's `recording.complete` before analysis. Offline HED conversion
uses files generated from `telemetry/event_catalog.json`; event matching, marker
codes and HED annotations are maintained there once. Generated HED files remain
in `analysis/hed/`; they add no runtime HED processing. See its README for generation.

Focused integration verification:

```powershell
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . --script tests/telemetry/test_psygodot_integration.gd
```

This compares manual/replay judgments, score, gauge, and note state with capture
off and on. See `tools/telemetry_benchmark/` for reproducible rendered measurements.

## Local Music

Keep imported charts, music, covers, and song packs in `local_songs/` (ignored by
Git and excluded from exports). Do not force-add this directory. The repository
includes only the audited original sample tone, original hit SFX, original sample
charts, and compatibility fixtures; it does not include the local music library.
See `docs/USER_SONG_IMPORT.md` and `docs/ASSET_AUDIT.md`.

## Tests

```powershell
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/test_smoke.gd
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/chart/test_taiko_chart.gd
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/chart/test_tja_tokenizer.gd
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/chart/test_tja_parser.gd
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/gameplay/test_judge.gd
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/gameplay/test_scoring.gd
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/gameplay/test_song_clock.gd
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/gameplay/test_note_lane.gd
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/gameplay/test_gameplay_controller.gd
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/ui/test_hud.gd
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/app/test_main_scene.gd
```
