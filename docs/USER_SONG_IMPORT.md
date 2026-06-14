# User Song Import

GDTaiko does not bundle music by default. Users can place their own `.tja`
charts and matching audio files in:

```text
user://songs/
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

Songs with a missing `WAVE` audio file still appear in song select, but gameplay
launch is blocked until the expected audio file is added.
