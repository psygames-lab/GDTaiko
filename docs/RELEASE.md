# Release

## Windows

GDTaiko currently targets Godot `4.6.2.stable.official`.

Create the output directory before exporting:

```powershell
New-Item -ItemType Directory -Force builds\windows
```

Build the Windows release preset:

```powershell
D:\Godot\Godot_v4.6.2-stable_win64_console.exe --headless --path E:\10_创作\GDTaiko --export-release "Windows Desktop" builds\windows\GDTaiko.exe
```

The build output is intentionally ignored by git under `builds/`.
