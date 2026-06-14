# Performance Budget

- Target FPS: 60 stable.
- Gameplay frame time: under 16.67 ms.
- Input-to-judgment path: no allocations in hot path after chart load.
- Note node count: pool notes; do not create/free nodes every frame.
- Audio clock: use audio playback position during normal play.
