# Asset Policy

## Music And Song Packs

Music and song packs are not bundled by default. GDTaiko supports user-local import of `.tja` charts and audio files. A music file can enter the repository or release only when its license explicitly allows redistribution.

## Skin, Font, And SFX Assets

Skin, font, and sound-effect assets can be imported from OpenTaiko-related repositories only after asset-level license review.

Allowed for release:

- Original GDTaiko assets.
- Assets with clear MIT, CC0, CC-BY, or another compatible redistribution license.
- Assets whose license allows modification and redistribution in a game package.

Not allowed for release:

- Assets with unknown license.
- Assets copied from commercial Taiko games.
- Assets whose license allows personal use only.
- Assets that require attribution if attribution is not included in `NOTICE.md`.

## Permission Levels

- `local_reference`: may exist only outside release assets; useful for comparison.
- `repo_allowed`: may be committed to the repository.
- `release_allowed`: may be bundled in exported builds.
- `blocked`: must not be committed or distributed.
