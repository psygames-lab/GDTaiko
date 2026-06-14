# User Skins

GDTaiko loads the built-in default theme from:

```text
res://themes/default/theme.json
```

Users can override the active skin locally by creating:

```text
user://skins/default/skin.json
```

The user skin file is optional and may be partial. Missing keys inherit from the
built-in default theme.

Example:

```json
{
  "name": "My Local Skin",
  "note_don": "user://skins/default/note_don.png",
  "note_ka": "user://skins/default/note_ka.png",
  "lane_color": "#1b1b1b",
  "gogo_color": "#f5a623",
  "hud_top_band_color": "#141417",
  "gauge_fill_color": "#ff9f1c",
  "result_panel_color": "#141417"
}
```

Supported keys:

- `name`
- `note_don`
- `note_ka`
- `sfx_don`
- `sfx_ka`
- `font_main`
- `lane_color`
- `gogo_color`
- `hud_top_band_color`
- `gauge_fill_color`
- `result_panel_color`

Skin assets placed under `user://skins/` are user-local and are not bundled in
GDTaiko releases.

OpenTaiko-related skins, fonts, SFX, voices, songs, jackets, and BGA assets must
not be committed or bundled unless `docs/ASSET_AUDIT.md` marks the exact asset
`release_allowed`.
