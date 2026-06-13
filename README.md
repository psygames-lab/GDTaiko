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
