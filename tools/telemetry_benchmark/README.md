# Rendered PsyGodot A/B benchmark

From the repository root:

```powershell
python tools/telemetry_benchmark/compare.py --godot D:/Godot/Godot_v4.6.2-stable_win64_console.exe
```

The runner performs three paired comparisons in alternating off/on, on/off,
off/on order. Each process has a 2-second warmup and a 10-second measurement.
Keep other workloads idle and the game window visible. Results and event files
are written under ignored `output/telemetry_benchmark/`.

The workload renders the actual gameplay scene at 1280x720 with vsync and the
FPS cap disabled. It uses 140 original generated notes (10 per song second),
fixed replay inputs with perfect/good offsets and deliberate misses, the
project's original sample audio, sprites, HUD and hit effects. The song clock
advances at 120 deterministic steps per wall-clock second; replay inputs carry
fixed song timestamps. This makes the workload and judgments comparable even
when rendering rates differ. The original sample audio lasts 10 seconds;
the benchmark continues for 2 more seconds using the deterministic clock.

Frame intervals are wall-clock measurements between main-loop callbacks,
including rendering/OS scheduling between callbacks. Output includes p50, p95,
p99, maximum, counts over 16.67/33.33 ms, and full gameplay input-call duration.
Input-call duration includes judging and visual effects as well as capture; it
is not the isolated logger cost. Every pair compares the entire per-step
judgment trace, final note states and result, and verifies complete recording.

These are rendered synthetic-workload measurements, not proof of physical
keyboard-to-audio latency or behavior on every device/song. They deliberately
exclude startup and shutdown from steady-state frame statistics. Inspect tail
latencies and repeat on target hardware before setting performance budgets.
