# PsyGodot source

These seven GDScript files are an unchanged copy of the generic framework at
https://github.com/psygames-lab/psygodot/tree/c91ead6f67b397e5f7c5fdb098f446acbed68ef5/addons/psygodot
(schema 0.2.0).

Make framework improvements in the PsyGodot repository, then copy the core
files here and update this reference. Keep GDTaiko-specific event hooks in
`scripts/telemetry/psygodot_bridge.gd` and the game controller. Re-run the
integration test and rendered benchmark after changes affecting capture cost.

The game works with capture disabled by default; `--psygodot` enables it.
