# Measurement on 2026-11-05

Windows; Intel Core Ultra 9 275HX; NVIDIA GeForce RTX 5060 Laptop GPU;
Godot 4.6.2.stable.official.71f334935, Forward+ renderer, 1280x720,
vsync off and unlimited FPS. Command and workload are described in README.md.
The machine was not running concurrent test suites during these measurements.

Each row is a separate process with 2 seconds of warmup and 10 measured seconds.
Run order alternated off/on, on/off, off/on. Times below are milliseconds.

| Pair | Capture | Frame p50 | Frame p95 | Frame p99 | Frame max | Frames >16.67 ms |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Off | 0.446 | 2.101 | 2.339 | 4.806 | 0 |
| 1 | On | 0.443 | 2.076 | 2.343 | 5.250 | 0 |
| 2 | Off | 0.282 | 1.265 | 2.848 | 5.022 | 0 |
| 2 | On | 0.283 | 1.143 | 2.693 | 9.007 | 0 |
| 3 | Off | 0.278 | 1.341 | 3.026 | 21.180 | 2 |
| 3 | On | 0.286 | 1.985 | 3.330 | 5.829 | 0 |

No run had a frame over 33.33 ms. Enabled runs had no frames over 16.67 ms;
the third disabled run had two. This does not establish that recording improves
performance: scheduling variance is visible, and the third enabled run has a
higher p95/p99 than its disabled counterpart.

All three pairs had identical complete 1,440-step judgment traces, final note
states and score/gauge/results. Each run applied 98 fixed replay inputs.
Each enabled run wrote all 217 accepted events with zero dropped events,
zero dropped samples, zero rejected sessions and zero write errors. Producer
queue peak was 3 jobs in each enabled run.

Measured mean gameplay input-call duration (86 calls after warmup) increased
from 247.3 to 262.9 microseconds in pair 1, 305.9 to 335.7 in pair 2, and 328.6
to 382.9 in pair 3: paired increases of 15.6, 29.8 and 54.3 microseconds.
These include game logic, HUD/effects and signal handling, so they are not an
isolated logger benchmark. The added capture cost is nonzero, while this
workload retained substantial frame-time headroom on this machine.

This evidence supports unchanged deterministic judgments and no observed
capture-enabled missed 60 Hz frame budget in the measured workload. It does
not establish physical input/audio latency or guarantee results on lower-end
hardware, dense charts, slow storage, or with optional high-frequency sampling.

The machine-readable run summaries are in `results_2026-11-05.json`. Full
per-step traces and captured raw events remain in ignored local output; no
song library or copyrighted music was used by this benchmark.
