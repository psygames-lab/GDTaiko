# GDTaiko

GDTaiko is an independent Godot Taiko rhythm game. It uses OpenTaiko as a behavioral reference for Taiko gameplay and `.tja` compatibility, but it is implemented as a Godot-native project rather than a direct C# source-tree translation.

## Current Target

- Godot: `4.6.2.stable.official`
- Runtime: Godot/GDScript
- Assets: original or explicitly audited before inclusion

## Current Status

Planning and bootstrap stage. `project.godot` has not been created yet; follow Phase 0 and Phase 1 in `DEVELOPMENT_PLAN.md`.

## Verification

After the Godot project is created, focused tests should use the documented headless pattern:

```powershell
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path 'E:\10_创作\GDTaiko' -s res://tests/test_smoke.gd
```

The plain `godot` command is not currently on this machine's PATH.
