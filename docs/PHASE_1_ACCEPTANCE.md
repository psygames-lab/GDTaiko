# Phase 1 Acceptance

**Godot console pattern used in this repo**

- `& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s <test_script>`
- Reported engine version: `4.6.2.stable.official.71f334935`

## Required

- [x] `res://scenes/Main.tscn` is wired to load gameplay flow (`scripts/app/main.gd` calls `Gameplay.tscn`).
- [x] `res://scenes/Main.tscn` loads in the project without runtime parse/load failure.
- [x] Sample `.tja` parses without crash (`tests/chart/test_tja_parser.gd`).
- [x] Sample audio placeholder exists and is loaded with the sample chart (`assets/sample/sample.ogg`; `tests/gameplay/test_gameplay_controller.gd` checks sample wave load path and audio player wiring).
- [x] Don notes can be hit (`F` action mapping in runtime code and `tests/gameplay/test_gameplay_controller.gd`).
- [x] Ka notes can be hit with `J` (`tests/gameplay/test_gameplay_controller.gd`).
- [x] Misses are detected when notes pass timing window (`tests/gameplay/test_gameplay_controller.gd`).
- [x] Score updates (`tests/gameplay/test_scoring.gd`, `tests/gameplay/test_gameplay_controller.gd`).
- [x] Combo updates (`tests/gameplay/test_scoring.gd`, `tests/gameplay/test_gameplay_controller.gd`).
- [x] Parser tests pass (`tests/chart/test_taiko_chart.gd`, `tests/chart/test_tja_parser.gd`).
- [x] Judge tests pass (`tests/gameplay/test_judge.gd`).
- [x] Scoring tests pass (`tests/gameplay/test_scoring.gd`).

## Expanded Phase 1 Verification Suite

| Test | Command | Result |
| --- | --- | --- |
| `test_smoke` | `& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/test_smoke.gd` | PASS |
| `test_taiko_chart` | `& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/chart/test_taiko_chart.gd` | PASS |
| `test_tja_tokenizer` | `& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/chart/test_tja_tokenizer.gd` | PASS |
| `test_tja_parser` | `& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/chart/test_tja_parser.gd` | PASS |
| `test_judge` | `& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/gameplay/test_judge.gd` | PASS |
| `test_scoring` | `& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/gameplay/test_scoring.gd` | PASS |
| `test_song_clock` | `& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/gameplay/test_song_clock.gd` | PASS |
| `test_note_lane` | `& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/gameplay/test_note_lane.gd` | PASS |
| `test_gameplay_controller` | `& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/gameplay/test_gameplay_controller.gd` | PASS |
| `test_hud` | `& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/ui/test_hud.gd` | PASS |
| `test_main_scene` | `& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . -s res://tests/app/test_main_scene.gd` | PASS |

## Known Phase 1 Limits

- Roll notes are not implemented.
- Balloon notes are not implemented.
- GOGO time is not implemented.
- Branching is not implemented.
- Song select is not implemented.
- Skinning is not implemented.
