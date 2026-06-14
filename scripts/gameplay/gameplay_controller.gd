extends Node2D
class_name GameplayController

const TjaParser := preload("res://scripts/chart/tja_parser.gd")
const TimingMap := preload("res://scripts/chart/timing_map.gd")
const Judge := preload("res://scripts/gameplay/judge.gd")
const Scoring := preload("res://scripts/gameplay/scoring.gd")
const SongClock := preload("res://scripts/gameplay/song_clock.gd")
const RollManager := preload("res://scripts/gameplay/roll_manager.gd")
const BalloonManager := preload("res://scripts/gameplay/balloon_manager.gd")
const NoteLane := preload("res://scripts/gameplay/note_lane.gd")
const TaikoHud := preload("res://scripts/ui/hud.gd")
const NoteModel := preload("res://scripts/gameplay/note_model.gd")

const SAMPLE_CHART_PATH := "res://assets/sample/sample.tja"
const SAMPLE_ASSET_PATH := "res://assets/sample/"

var chart
var timing_map := TimingMap.new()
var judge := Judge.new()
var scoring := Scoring.new()
var roll_manager := RollManager.new()
var balloon_manager := BalloonManager.new()
var clock: SongClock
var lane: NoteLane
var hud: TaikoHud
var audio_player: AudioStreamPlayer
var don_texture: Texture2D
var ka_texture: Texture2D
var playing := false


func _ready() -> void:
	_build_scene()
	_load_sample_chart()


func _process(delta: float) -> void:
	if not playing:
		return
	clock.advance(delta)
	var song_time := clock.time_sec()
	_update_timing_states(song_time)
	lane.update_notes(chart.notes, song_time, timing_map)
	_process_misses(song_time)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("taiko_start"):
		_start_song()
	elif event.is_action_pressed("taiko_don"):
		_hit(NoteModel.DON)
	elif event.is_action_pressed("taiko_ka"):
		_hit(NoteModel.KA)


func _build_scene() -> void:
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "Audio"
	add_child(audio_player)

	clock = SongClock.new()
	add_child(clock)

	lane = NoteLane.new()
	lane.name = "Lane"
	add_child(lane)

	hud = TaikoHud.new()
	hud.name = "Hud"
	hud.build()
	add_child(hud)

	don_texture = _load_note_texture("res://assets/notes/note_don.png", Color.RED)
	ka_texture = _load_note_texture("res://assets/notes/note_ka.png", Color.CORNFLOWER_BLUE)
	lane.configure(don_texture, ka_texture)


func _load_sample_chart() -> void:
	chart = TjaParser.parse_file(SAMPLE_CHART_PATH)
	if chart == null:
		push_error("Failed to load sample chart from %s" % SAMPLE_CHART_PATH)
		hud.set_status("Missing chart")
		return
	var audio_path: String = SAMPLE_ASSET_PATH + String(chart.wave)
	var loaded_stream := _load_optional_audio(audio_path)
	audio_player.stream = loaded_stream
	clock.configure(audio_player, chart.offset_sec)
	_build_timing_map()
	lane.spawn_notes(chart.notes)
	hud.update_score(scoring.score, scoring.combo)
	hud.set_status("Loaded %s - press Space" % chart.title)


func _start_song() -> void:
	if chart == null:
		return
	for note in chart.notes:
		note["state"] = NoteModel.PENDING
	lane.spawn_notes(chart.notes)
	scoring.reset()
	roll_manager.reset()
	balloon_manager.reset()
	scoring.set_gogo(false)
	hud.set_gogo(false)
	clock.reset()
	if audio_player.stream != null:
		audio_player.stop()
		audio_player.play()
	playing = true
	hud.update_score(scoring.score, scoring.combo)
	hud.set_status("Playing")


func _hit(lane_name: String) -> void:
	if not playing or chart == null:
		return
	var song_time := clock.time_sec()
	_update_timing_states(song_time)
	var best_note: Dictionary = {}
	var best_error := INF

	for note in chart.notes:
		if String(note.get("state", NoteModel.PENDING)) != NoteModel.PENDING:
			continue
		if balloon_manager.is_balloon(note):
			continue
		if roll_manager.is_roll(note):
			continue
		if String(note.get("lane", NoteModel.DON)) != lane_name:
			continue
		var error := absf(float(note["time_sec"]) - song_time)
		if error < best_error:
			best_error = error
			best_note = note

	if best_note.is_empty():
		if _apply_active_long_note_hit(song_time):
			return
		_apply_empty_miss()
		return

	var result := judge.judge(float(best_note["time_sec"]), song_time)
	if result["judgment"] == "miss":
		if _apply_active_long_note_hit(song_time):
			return
		_apply_empty_miss()
		return

	best_note["state"] = NoteModel.HIT
	scoring.apply_judgment(result["judgment"])
	hud.update_score(scoring.score, scoring.combo)
	hud.show_judgment(result["judgment"], result["timing_error_ms"])
	_process_song_finished()


func _apply_active_long_note_hit(song_time: float) -> bool:
	if _apply_active_balloon_hit(song_time):
		return true
	return _apply_active_roll_hit(song_time)


func _apply_active_balloon_hit(song_time: float) -> bool:
	for note in chart.notes:
		if String(note.get("state", NoteModel.PENDING)) != NoteModel.PENDING:
			continue
		if not balloon_manager.is_balloon(note):
			continue
		if not roll_manager.is_active(note, song_time):
			continue
		if balloon_manager.register_hit(note):
			note["state"] = NoteModel.HIT
			scoring.apply_balloon_clear()
			_process_song_finished()
		else:
			scoring.apply_roll_hit()
		hud.update_score(scoring.score, scoring.combo)
		return true
	return false


func _apply_active_roll_hit(song_time: float) -> bool:
	for note in chart.notes:
		if not roll_manager.is_roll(note):
			continue
		if not roll_manager.is_active(note, song_time):
			continue
		roll_manager.register_hit(note)
		scoring.apply_roll_hit()
		hud.update_score(scoring.score, scoring.combo)
		return true
	return false


func _apply_empty_miss() -> void:
	scoring.apply_judgment("miss")
	hud.update_score(scoring.score, scoring.combo)
	hud.show_judgment("miss", 0.0)


func _build_timing_map() -> void:
	timing_map = TimingMap.new()
	for event in chart.timing_events:
		timing_map.add_event(float(event["time_sec"]), String(event["type"]), event["value"])


func _update_timing_states(song_time: float) -> void:
	var gogo := false
	for event in chart.timing_events:
		if String(event["type"]) == "gogo" and float(event["time_sec"]) <= song_time:
			gogo = bool(event["value"])
	scoring.set_gogo(gogo)
	hud.set_gogo(gogo)


func _process_misses(song_time: float) -> void:
	if chart == null:
		return
	for note in chart.notes:
		if String(note.get("state", NoteModel.PENDING)) != NoteModel.PENDING:
			continue
		var expiry_time := float(note["time_sec"])
		if balloon_manager.is_balloon(note):
			expiry_time += float(note.get("duration_sec", 0.0))
			if judge.is_expired(expiry_time, song_time):
				note["state"] = NoteModel.HIT
				lane.update_notes(chart.notes, song_time, timing_map)
				_process_song_finished()
			continue
		if roll_manager.is_roll(note):
			expiry_time += float(note.get("duration_sec", 0.0))
			if judge.is_expired(expiry_time, song_time):
				note["state"] = NoteModel.HIT
				lane.update_notes(chart.notes, song_time, timing_map)
				_process_song_finished()
			continue
		if judge.is_expired(expiry_time, song_time):
			note["state"] = NoteModel.MISSED
			scoring.apply_judgment("miss")
			hud.update_score(scoring.score, scoring.combo)
			hud.show_judgment("miss", 0.0)
			lane.update_notes(chart.notes, song_time, timing_map)
			_process_song_finished()


func _process_song_finished() -> void:
	if chart == null:
		return
	for note in chart.notes:
		if String(note.get("state", NoteModel.PENDING)) == NoteModel.PENDING:
			return
	playing = false


func _load_optional_audio(path: String) -> AudioStream:
	if not FileAccess.file_exists(path):
		return null
	if ResourceLoader.exists(path):
		var stream = load(path)
		if stream is AudioStream:
			return stream
	return null


func _load_note_texture(path: String, fallback_color: Color) -> Texture2D:
	if ResourceLoader.exists(path):
		var texture := load(path)
		if texture is Texture2D:
			return texture

	var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center := Vector2(64.0, 64.0)
	var radius := 48.0
	for x in range(0, 128):
		for y in range(0, 128):
			var point := Vector2(x, y)
			if center.distance_to(point) <= radius:
				image.set_pixel(x, y, fallback_color)
	return ImageTexture.create_from_image(image)
