# AGENTS.md

## Project

GDTaiko is an independent Godot Taiko rhythm game. OpenTaiko is a behavior and `.tja` compatibility reference, not a source tree to mechanically translate.

## Development Mode

Use a multi-agent workflow by default.

Preferred model routing when available:

- `5.5 high`: architecture, OpenTaiko compatibility decisions, parser/timing/scoring review, branch/replay design, asset-license audit, release review.
- `5.3-codex-spark`: routine GDScript implementation, focused tests, fixtures, UI glue, simple docs, mechanical cleanup.

If those exact models are unavailable, preserve the role split: strongest available model for design/review, faster coding model for routine implementation.

## Review Gates

Require `5.5 high` review before accepting changes to:

- `.tja` parser semantics and compatibility fixtures.
- Timing map, BPM/SCROLL/MEASURE behavior, and audio sync.
- Judgment windows, scoring, soul gauge, branch rules, roll/balloon behavior.
- Song folder scanning, score storage, and replay formats.
- Theme/skin architecture and asset pipeline.
- Asset license audit and release inclusion decisions.
- Export/release configuration.

## Engineering Rules

- Keep the Godot runtime native to Godot/GDScript.
- Use Python only for optional offline tooling.
- Treat OpenTaiko as a behavioral reference, not a C# to GDScript translation target.
- Prefer the wording "Godot-native recreation" or "compatibility implementation" over source-tree translation language when describing OpenTaiko work.
- Build playable vertical slices before broad feature expansion.
- Add tests for parser, timing, judging, scoring, storage, and compatibility changes.
- Use `.tja` fixtures for compatibility-sensitive behavior.
- Keep changes surgical and task-scoped.

## Engine Target

- Current target: Godot `4.6.2.stable.official`.
- If a lower minimum Godot version is desired, document it separately and verify the project opens and tests pass on that version.
- Keep `project.godot` feature/version metadata aligned with the selected target before editing scenes.

## Compatibility Evidence

For every OpenTaiko or TJAPlayer compatibility-sensitive behavior:

- Record the OpenTaiko repository URL and commit or tag used as reference.
- Link or note the relevant source file, documentation, or observed behavior.
- Add an original minimal `.tja` fixture; do not copy copyrighted charts.
- Add expected parser/runtime output in a sidecar file or focused test assertion.
- If GDTaiko intentionally differs from OpenTaiko, document the reason before accepting the change.

## Asset Rules

- Music and song packs are user-local by default and are not bundled unless a specific license clearly allows redistribution.
- Create or update `docs/ASSET_AUDIT.md` before adding any asset file, including placeholder art, SFX, fonts, and sample audio.
- Skin, font, and SFX assets may be imported only after `docs/ASSET_AUDIT.md` marks them `release_allowed`.
- Assets with unclear license must remain `local_reference` or `blocked`.
- Do not copy commercial Taiko UI, art, sounds, songs, or fonts without verified permission.

## Startup Checklist

- Confirm the Godot version before editing scenes.
- Run `git init` if the project is not already a repository.
- Create `.gitignore` before generating Godot import/cache files.
- Create or update `README.md` and `DEVELOPMENT_PLAN.md` before large implementation work.
- Create or update `docs/ASSET_AUDIT.md` before adding assets.
- Start with Phase 0 unless bootstrap has already been completed or the user explicitly redirects scope.

## Verification

Run focused tests after every implementation task. If a test runner is not yet available, add deterministic test scenes/scripts that return non-zero on failure and document the exact manual command used.
