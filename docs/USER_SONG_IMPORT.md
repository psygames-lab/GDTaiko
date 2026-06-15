# User Song Import

GDTaiko does not bundle music by default. Users can place their own `.tja`
charts and matching audio files in:

```text
user://songs/
```

On Windows, Godot usually maps this project path to:

```text
%APPDATA%\Godot\app_userdata\GDTaiko\songs\
```

Recommended folder layout:

```text
user://songs/My Song/
  chart.tja
  song.ogg
```

The `.tja` `WAVE:` field should point to the audio file in the same folder:

```text
TITLE:My Song
WAVE:song.ogg
#START
1000,
#END
```

One `.tja` may contain multiple `COURSE` blocks that share the same `WAVE`.
Song select will show each course as a selectable difficulty.

Songs with a missing `WAVE` audio file still appear in song select, but gameplay
launch is blocked until the expected audio file is added.

For generated or converted songs whose redistribution license is not confirmed,
keep the `.tja` and audio under `user://songs/` instead of committing them to the
repository.
