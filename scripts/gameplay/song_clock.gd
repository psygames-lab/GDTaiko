extends Node
class_name SongClock

var audio_player: AudioStreamPlayer
var chart_offset_sec := 0.0
var fallback_time_sec := 0.0
var using_audio_position := true

func configure(player: AudioStreamPlayer, offset_sec: float) -> void:
	audio_player = player
	chart_offset_sec = offset_sec
	fallback_time_sec = 0.0

func reset() -> void:
	fallback_time_sec = 0.0

func advance(delta: float) -> void:
	if audio_player != null and audio_player.playing and using_audio_position:
		return
	fallback_time_sec += delta

func time_sec() -> float:
	if audio_player != null and audio_player.playing and using_audio_position:
		return audio_player.get_playback_position() + chart_offset_sec
	return fallback_time_sec + chart_offset_sec
