# Event catalog integration measurement (2026-11-05)

Re-ran the existing rendered A/B workload after integrating generated marker configuration.
The enabled condition records ordinary events with catalog identity; mock markers are off.
Same 2-second warmup, 10-second measurement, original generated notes and alternating order
as the benchmark README. This does not measure a physical trigger driver or HED processing.

| Pair | Capture off p99 (ms) | Capture on p99 (ms) | Off max (ms) | On max (ms) |
| --- | ---: | ---: | ---: | ---: |
| 1 | 0.751 | 0.864 | 2.008 | 4.061 |
| 2 | 0.743 | 0.771 | 1.944 | 2.068 |
| 3 | 0.781 | 0.622 | 2.288 | 3.368 |

All three pairs had identical complete judgment traces, final note states and results.
Every capture-on run wrote all 217 accepted events with zero drops or write errors.
No measured run exceeded 16.67 ms. Variation between runs is visible; this is not
a zero-overhead claim, physical timing calibration, or guarantee on other hardware.

Machine-readable summary: `results_2026-11-05_catalog.json`. The original measurement
remains in `RESULTS.md`; these are separate measurements, not a controlled comparison
between the earlier and current code versions.
