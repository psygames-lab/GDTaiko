extends Node2D
class_name GameplayController

signal game_event(tag: String, payload: Dictionary, timestamp_usec: int)

const TjaParser := preload("res://scripts/chart/tja_parser.gd")
const TimingMap := preload("res://scripts/chart/timing_map.gd")
const Judge := preload("res://scripts/gameplay/judge.gd")
const Scoring := preload("res://scripts/gameplay/scoring.gd")
const SoulGauge := preload("res://scripts/gameplay/soul_gauge.gd")
const SongClock := preload("res://scripts/gameplay/song_clock.gd")
const RollManager := preload("res://scripts/gameplay/roll_manager.gd")
const BalloonManager := preload("res://scripts/gameplay/balloon_manager.gd")
const NoteLane := preload("res://scripts/gameplay/note_lane.gd")
const HitEffects := preload("res://scripts/gameplay/hit_effects.gd")
const FrameMonitor := preload("res://scripts/debug/frame_monitor.gd")
const TaikoTheme := preload("res://scripts/theme/taiko_theme.gd")
const TaikoHud := preload("res://scripts/ui/hud.gd")
const ResultScreen := preload("res://scripts/ui/result_screen.gd")
const NoteModel := preload("res://scripts/gameplay/note_model.gd")
const ReplayRecorder := preload("res://scripts/replay/replay_recorder.gd")
const GameConfig := preload("res://scripts/config/game_config.gd")
const ResultScene := preload("res://scenes/Result.tscn")

const SAMPLE_CHART_PATH := "res://assets/sample/sample.tja"
const SKIN_BACKGROUND_PATH := "res://assets/skin/night_festival/backgrounds/gameplay_stage.png"
const SKIN_CHARACTER_PATH := "res://assets/skin/night_festival/characters/festival_drummer.png"
const SKIN_PROPS_PATH := "res://assets/skin/night_festival/props/props_sheet.png"
const VIEWPORT_SIZE := Vector2(1280.0, 720.0)
const SONG_SELECT_SCENE_PATH := "res://scenes/SongSelect.tscn"

var chart
var timing_map := TimingMap.new()
var judge := Judge.new()
var scoring := Scoring.new()
var soul_gauge := SoulGauge.new()
var roll_manager := RollManager.new()
var balloon_manager := BalloonManager.new()
var clock: SongClock
var lane: NoteLane
var hit_effects: HitEffects
var frame_monitor: FrameMonitor
var hud: TaikoHud
var result_screen: ResultScreen
var replay_recorder: ReplayRecorder
var audio_player: AudioStreamPlayer
var don_sfx_player: AudioStreamPlayer
var ka_sfx_player: AudioStreamPlayer
var skin_background: TextureRect
var skin_character: TextureRect
var skin_props: TextureRect
var pause_button: Button
var pause_menu: CanvasLayer
var resume_button: Button
var restart_button: Button
var back_to_select_button: Button
var game_config: GameConfig
var theme: TaikoTheme
var don_texture: Texture2D
var ka_texture: Texture2D
var playing := false
var gameplay_paused := false
var last_result: Dictionary = {}
var current_chart_path := SAMPLE_CHART_PATH
var _event_song_active := false
var _event_song_time_sec := 0.0
var _event_input_source := "manual"
var _event_input_index := 0


func _ready() -> void:
	_build_scene()
	_load_sample_chart()


func _process(delta: float) -> void:
	_update_frame_monitor(delta)
	if not playing or gameplay_paused:
		return
	clock.advance(delta)
	var song_time := clock.time_sec()
	_event_song_time_sec = song_time
	_update_timing_states(song_time)
	lane.update_notes(chart.notes, song_time, timing_map)
	_process_misses(song_time)


func _unhandled_input(event: InputEvent) -> void:
	if _is_pause_event(event):
		_toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if gameplay_paused:
		return
	if event.is_action_pressed("taiko_start"):
		_start_song()
	elif event.is_action_pressed("taiko_don"):
		_play_hit_sfx(NoteModel.DON)
		lane.show_input_feedback(NoteModel.DON)
		_hit(NoteModel.DON)
	elif event.is_action_pressed("taiko_ka"):
		_play_hit_sfx(NoteModel.KA)
		lane.show_input_feedback(NoteModel.KA)
		_hit(NoteModel.KA)


func _build_scene() -> void:
	game_config = GameConfig.new()
	game_config.load_config()
	game_config.apply_to_project()
	theme = TaikoTheme.load_active()

	_add_skin_background()
	_add_skin_decorations()

	audio_player = AudioStreamPlayer.new()
	audio_player.name = "Audio"
	audio_player.bus = "Music"
	add_child(audio_player)

	don_sfx_player = _build_hit_sfx_player("DonSfx", theme.sfx_don_path)
	ka_sfx_player = _build_hit_sfx_player("KaSfx", theme.sfx_ka_path)

	clock = SongClock.new()
	add_child(clock)

	lane = NoteLane.new()
	lane.name = "Lane"
	add_child(lane)
	lane.build_skin()
	lane.apply_theme(theme)

	hit_effects = HitEffects.new()
	hit_effects.name = "HitEffects"
	add_child(hit_effects)

	frame_monitor = FrameMonitor.new()
	frame_monitor.name = "FrameMonitor"
	frame_monitor.position = Vector2(1032.0, 16.0)
	frame_monitor.visible = game_config.show_debug_monitor
	frame_monitor.build()
	add_child(frame_monitor)

	hud = TaikoHud.new()
	hud.name = "Hud"
	hud.build()
	hud.apply_theme(theme)
	add_child(hud)

	result_screen = ResultScene.instantiate() as ResultScreen
	result_screen.name = "Result"
	add_child(result_screen)
	result_screen.build()
	result_screen.apply_theme(theme)

	don_texture = theme.get_note_don_texture()
	if don_texture == null:
		don_texture = _load_note_texture("res://assets/notes/note_don.png", Color.RED)
	ka_texture = theme.get_note_ka_texture()
	if ka_texture == null:
		ka_texture = _load_note_texture("res://assets/notes/note_ka.png", Color.CORNFLOWER_BLUE)
	lane.configure(don_texture, ka_texture)
	_build_pause_controls()


func _update_frame_monitor(delta: float) -> void:
	if frame_monitor == null:
		return
	var active_note_count := 0
	if lane != null:
		active_note_count = lane.active_sprites.size()
	frame_monitor.update_metrics(delta, active_note_count)


func _add_skin_background() -> void:
	var texture := _load_png_texture(SKIN_BACKGROUND_PATH)
	if texture == null:
		return
	skin_background = TextureRect.new()
	skin_background.name = "SkinBackground"
	skin_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	skin_background.stretch_mode = TextureRect.STRETCH_SCALE
	skin_background.texture = texture
	skin_background.modulate = Color(1.0, 1.0, 1.0, 0.78)
	skin_background.z_index = -100
	add_child(skin_background)
	skin_background.size = VIEWPORT_SIZE


func _load_png_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var texture := load(path)
		if texture is Texture2D:
			return texture
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)


func _add_skin_decorations() -> void:
	var character_texture := _load_png_texture(SKIN_CHARACTER_PATH)
	if character_texture != null:
		skin_character = TextureRect.new()
		skin_character.name = "SkinCharacter"
		skin_character.texture = character_texture
		skin_character.position = Vector2(18.0, 420.0)
		skin_character.size = Vector2(220.0, 260.0)
		skin_character.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		skin_character.z_index = -50
		add_child(skin_character)

	var props_texture := _load_png_texture(SKIN_PROPS_PATH)
	if props_texture != null:
		skin_props = TextureRect.new()
		skin_props.name = "SkinProps"
		skin_props.texture = props_texture
		skin_props.position = Vector2(1000.0, 510.0)
		skin_props.size = Vector2(220.0, 146.0)
		skin_props.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		skin_props.z_index = -50
		add_child(skin_props)


func _load_sample_chart() -> void:
	var chart_path := SAMPLE_CHART_PATH
	var audio_path := ""
	var selected_course_name := ""
	var selected_course_index := -1
	var session := get_node_or_null("/root/SessionState")
	if session != null and String(session.get("selected_tja_path")) != "":
		chart_path = String(session.get("selected_tja_path"))
		audio_path = String(session.get("selected_audio_path"))
		selected_course_name = String(session.get("selected_course_name"))
		selected_course_index = int(session.get("selected_course_index"))
	current_chart_path = chart_path
	chart = _parse_selected_chart(chart_path, selected_course_name, selected_course_index)
	if chart == null:
		push_error("Failed to load chart from %s" % chart_path)
		hud.set_status("Missing chart")
		return
	if audio_path == "":
		audio_path = _resolve_chart_audio_path(chart_path, String(chart.wave))
	var loaded_stream := _load_optional_audio(audio_path)
	audio_player.stream = loaded_stream
	clock.configure(audio_player, chart.offset_sec + (float(game_config.chart_offset_ms) / 1000.0))
	_build_timing_map()
	lane.spawn_notes(chart.notes)
	hud.update_score(scoring.score, scoring.combo)
	hud.update_gauge(soul_gauge.value)
	hud.set_status("Loaded %s - press Space" % chart.title)


func _start_song() -> void:
	if chart == null:
		return
	_end_song_event("restarted")
	_set_paused(false)
	for note in chart.notes:
		note["state"] = NoteModel.PENDING
		if balloon_manager.is_balloon(note):
			note["balloon_hits"] = 0
	lane.spawn_notes(chart.notes)
	scoring.reset()
	soul_gauge.reset()
	roll_manager.reset()
	balloon_manager.reset()
	scoring.set_gogo(false)
	hud.set_gogo(false)
	result_screen.hide_result()
	last_result = {}
	replay_recorder = ReplayRecorder.new()
	replay_recorder.start(_chart_replay_hash(current_chart_path), chart.course, int(round((chart.offset_sec + (float(game_config.chart_offset_ms) / 1000.0)) * 1000.0)), game_config.input_offset_ms)
	clock.reset()
	_event_input_index = 0
	_event_song_time_sec = clock.chart_offset_sec
	_event_song_active = true
	if game_event.has_connections():
		game_event.emit("song_start", {
			"chart_path": current_chart_path,
			"course": chart.course,
			"chart_offset_sec": clock.chart_offset_sec,
			"input_offset_ms": game_config.input_offset_ms,
			"notes": chart.notes,
		}, Time.get_ticks_usec())
	if audio_player.stream != null:
		audio_player.stop()
		audio_player.play()
	playing = true
	hud.update_score(scoring.score, scoring.combo)
	hud.update_gauge(soul_gauge.value)
	hud.set_status("Playing")


func _build_pause_controls() -> void:
	pause_button = Button.new()
	pause_button.name = "PauseButton"
	pause_button.text = "Pause"
	pause_button.position = Vector2(1150.0, 18.0)
	pause_button.size = Vector2(98.0, 42.0)
	pause_button.z_index = 100
	pause_button.pressed.connect(_toggle_pause)
	add_child(pause_button)

	pause_menu = CanvasLayer.new()
	pause_menu.name = "PauseMenu"
	pause_menu.layer = 20
	pause_menu.visible = false
	add_child(pause_menu)

	var overlay := ColorRect.new()
	overlay.name = "PauseOverlay"
	overlay.position = Vector2.ZERO
	overlay.size = VIEWPORT_SIZE
	overlay.color = Color(0.0, 0.0, 0.0, 0.48)
	pause_menu.add_child(overlay)

	var panel := Panel.new()
	panel.name = "PausePanel"
	panel.position = Vector2(440.0, 210.0)
	panel.size = Vector2(400.0, 280.0)
	pause_menu.add_child(panel)

	var title := Label.new()
	title.name = "PauseTitle"
	title.text = "Paused"
	title.position = Vector2(44.0, 28.0)
	title.size = Vector2(312.0, 44.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	panel.add_child(title)

	resume_button = _pause_menu_button("ResumeButton", "Resume", Vector2(70.0, 92.0))
	restart_button = _pause_menu_button("RestartButton", "Restart", Vector2(70.0, 148.0))
	back_to_select_button = _pause_menu_button("BackToSelectButton", "Song Select", Vector2(70.0, 204.0))
	panel.add_child(resume_button)
	panel.add_child(restart_button)
	panel.add_child(back_to_select_button)
	resume_button.pressed.connect(_resume_song)
	restart_button.pressed.connect(_restart_song)
	back_to_select_button.pressed.connect(_return_to_song_select)


func _pause_menu_button(button_name: String, text: String, position: Vector2) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = text
	button.position = position
	button.size = Vector2(260.0, 42.0)
	return button


func _is_pause_event(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		return key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE
	return false


func _toggle_pause() -> void:
	_set_paused(not gameplay_paused)


func _resume_song() -> void:
	_set_paused(false)


func _restart_song() -> void:
	_set_paused(false)
	_start_song()


func _return_to_song_select() -> void:
	_end_song_event("song_select")
	playing = false
	_set_paused(false)
	if audio_player != null:
		audio_player.stop()
	set_meta("last_scene_request", SONG_SELECT_SCENE_PATH)
	call_deferred("_change_scene_to_file", SONG_SELECT_SCENE_PATH)


func _change_scene_to_file(path: String) -> void:
	if is_inside_tree():
		get_tree().change_scene_to_file(path)


func _set_paused(paused: bool) -> void:
	var changed := gameplay_paused != paused
	gameplay_paused = paused
	if pause_menu != null:
		pause_menu.visible = gameplay_paused
	if audio_player != null:
		audio_player.stream_paused = gameplay_paused
	if hud != null:
		hud.set_status("Paused" if gameplay_paused else ("Playing" if playing else "Ready"))
	if changed and _event_song_active and game_event.has_connections():
		game_event.emit("pause" if paused else "resume", {
			"last_observed_song_time_sec": _event_song_time_sec,
		}, Time.get_ticks_usec())


func _hit(lane_name: String, record_replay_input: bool = true) -> void:
	if not playing or chart == null:
		return
	var song_time := clock.time_sec() + (float(game_config.input_offset_ms) / 1000.0)
	_apply_hit_at(lane_name, song_time, record_replay_input)


func apply_replay_input(lane_name: String, replay_song_time_sec: Variant = null) -> void:
	if not playing or chart == null:
		return
	var song_time := clock.time_sec()
	if replay_song_time_sec != null:
		song_time = float(replay_song_time_sec)
	_apply_hit_at(lane_name, song_time, false)


func _apply_hit_at(lane_name: String, song_time: float, record_replay_input: bool) -> void:
	_event_song_time_sec = song_time
	_event_input_source = "manual" if record_replay_input else "replay"
	_event_input_index += 1
	if game_event.has_connections():
		game_event.emit("player_response", {
			"lane": lane_name,
			"song_time_sec": song_time,
			"source": _event_input_source,
			"input_index": _event_input_index,
		}, Time.get_ticks_usec())
	if replay_recorder != null and record_replay_input:
		replay_recorder.record_input(song_time, lane_name)
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
		_apply_empty_miss(lane_name, song_time)
		return

	var result := judge.judge(float(best_note["time_sec"]), song_time)
	if result["judgment"] == "miss":
		if _apply_active_long_note_hit(song_time):
			return
		_apply_empty_miss(lane_name, song_time)
		return

	best_note["state"] = NoteModel.HIT
	lane.show_input_feedback(lane_name)
	var note_kind := String(best_note.get("kind", ""))
	scoring.apply_judgment(result["judgment"], note_kind)
	soul_gauge.apply_judgment(result["judgment"])
	hit_effects.spawn_hit(Vector2(NoteLane.HIT_X, NoteLane.NOTE_Y), result["judgment"], note_kind)
	hud.update_score(scoring.score, scoring.combo)
	hud.update_gauge(soul_gauge.value)
	hud.show_judgment(result["judgment"], result["timing_error_ms"])
	if game_event.has_connections():
		_emit_note_event("note_hit", best_note, song_time, {
			"judgment": result["judgment"],
			"timing_error_ms": result["timing_error_ms"],
		})
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
			lane.update_notes(chart.notes, song_time, timing_map)
			scoring.apply_balloon_clear()
			if game_event.has_connections():
				_emit_note_event("balloon_hit", note, song_time, {
					"hits": note["balloon_hits"], "cleared": true,
				})
			_process_song_finished()
		else:
			scoring.apply_roll_hit()
			lane.update_notes(chart.notes, song_time, timing_map)
			if game_event.has_connections():
				_emit_note_event("balloon_hit", note, song_time, {
					"hits": note["balloon_hits"], "cleared": false,
				})
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
		if game_event.has_connections():
			_emit_note_event("roll_hit", note, song_time, {
				"hits": roll_manager.hit_count(String(note["id"])),
			})
		return true
	return false


func _apply_empty_miss(lane_name: String = "", song_time: float = 0.0) -> void:
	lane.show_input_feedback("miss")
	scoring.apply_judgment("miss")
	soul_gauge.apply_judgment("miss")
	hit_effects.spawn_miss(Vector2(NoteLane.HIT_X, NoteLane.NOTE_Y))
	hud.update_score(scoring.score, scoring.combo)
	hud.update_gauge(soul_gauge.value)
	hud.show_judgment("miss", 0.0)
	if game_event.has_connections():
		game_event.emit("empty_hit", {
			"lane": lane_name, "song_time_sec": song_time,
			"source": _event_input_source, "input_index": _event_input_index,
			"score": scoring.score, "combo": scoring.combo,
		}, Time.get_ticks_usec())


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
	lane.set_gogo(gogo)


func _process_misses(song_time: float) -> void:
	if chart == null:
		return
	_event_song_time_sec = song_time
	for note in chart.notes:
		if String(note.get("state", NoteModel.PENDING)) != NoteModel.PENDING:
			continue
		var expiry_time := float(note["time_sec"])
		if balloon_manager.is_balloon(note):
			expiry_time += float(note.get("duration_sec", 0.0))
			if judge.is_expired(expiry_time, song_time):
				note["state"] = NoteModel.HIT
				lane.update_notes(chart.notes, song_time, timing_map)
				if game_event.has_connections():
					_emit_note_event("balloon_end", note, song_time, {
						"source": "game", "input_index": 0, "cleared": false,
						"hits": int(note.get("balloon_hits", 0)),
					})
				_process_song_finished()
			continue
		if roll_manager.is_roll(note):
			expiry_time += float(note.get("duration_sec", 0.0))
			if judge.is_expired(expiry_time, song_time):
				note["state"] = NoteModel.HIT
				lane.update_notes(chart.notes, song_time, timing_map)
				if game_event.has_connections():
					_emit_note_event("roll_end", note, song_time, {
						"source": "game", "input_index": 0,
						"hits": roll_manager.hit_count(String(note["id"])),
					})
				_process_song_finished()
			continue
		if judge.is_expired(expiry_time, song_time):
			note["state"] = NoteModel.MISSED
			lane.show_input_feedback("miss")
			scoring.apply_judgment("miss")
			soul_gauge.apply_judgment("miss")
			hit_effects.spawn_miss(Vector2(NoteLane.HIT_X, NoteLane.NOTE_Y))
			hud.update_score(scoring.score, scoring.combo)
			hud.update_gauge(soul_gauge.value)
			hud.show_judgment("miss", 0.0)
			lane.update_notes(chart.notes, song_time, timing_map)
			if game_event.has_connections():
				_emit_note_event("note_miss", note, song_time, {
					"source": "game", "input_index": 0, "reason": "expired",
				})
			_process_song_finished()


func _process_song_finished() -> void:
	if chart == null:
		return
	for note in chart.notes:
		if String(note.get("state", NoteModel.PENDING)) == NoteModel.PENDING:
			return
	playing = false
	last_result = _build_result_payload()
	if replay_recorder != null:
		replay_recorder.set_result(last_result)
	_end_song_event("completed")
	result_screen.show_result(last_result)


func _emit_note_event(tag: String, note: Dictionary, song_time: float, details: Dictionary) -> void:
	if not game_event.has_connections():
		return
	var payload := {
		"note_id": note["id"], "lane": note["lane"],
		"scheduled_time_sec": note["time_sec"], "song_time_sec": song_time,
		"source": _event_input_source, "input_index": _event_input_index,
		"score": scoring.score, "combo": scoring.combo,
	}
	payload.merge(details, true)
	game_event.emit(tag, payload, Time.get_ticks_usec())


func _end_song_event(reason: String) -> void:
	if not _event_song_active:
		return
	_event_song_active = false
	if game_event.has_connections():
		game_event.emit("song_end", {
			"reason": reason, "result": _build_result_payload(),
			"last_observed_song_time_sec": _event_song_time_sec,
		}, Time.get_ticks_usec())


func _exit_tree() -> void:
	_end_song_event("scene_exit")


func _build_result_payload() -> Dictionary:
	return {
		"score": scoring.score,
		"song_key": current_chart_path,
		"course": chart.course,
		"max_combo": scoring.max_combo,
		"perfects": scoring.perfects,
		"goods": scoring.goods,
		"bads": scoring.bads,
		"misses": scoring.misses,
		"gauge": soul_gauge.value,
		"clear": soul_gauge.is_clear(),
	}


func _load_optional_audio(path: String) -> AudioStream:
	if not FileAccess.file_exists(path):
		return null
	if ResourceLoader.exists(path):
		var stream = load(path)
		if stream is AudioStream:
			return stream
	if path.get_extension().to_lower() == "ogg":
		return AudioStreamOggVorbis.load_from_file(path)
	if path.get_extension().to_lower() == "wav":
		return AudioStreamWAV.load_from_file(path)
	return null


func _build_hit_sfx_player(player_name: String, stream_path: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = "SFX"
	player.stream = _load_optional_audio(stream_path)
	add_child(player)
	return player


func _play_hit_sfx(lane_name: String) -> void:
	set_meta("last_sfx_lane", lane_name)
	var player := don_sfx_player if lane_name == NoteModel.DON else ka_sfx_player
	if player == null or player.stream == null:
		return
	player.stop()
	player.play()


func _parse_selected_chart(chart_path: String, course_name: String, course_index: int) -> Variant:
	if course_name != "":
		var candidates := TjaParser.parse_courses_file(chart_path)
		if course_index >= 0 and course_index < candidates.size():
			var indexed_candidate = candidates[course_index]
			if String(indexed_candidate.course).to_lower() == course_name.to_lower():
				return indexed_candidate
		for candidate in candidates:
			if String(candidate.course).to_lower() == course_name.to_lower():
				return candidate
	return TjaParser.parse_file(chart_path)


func _resolve_chart_audio_path(chart_path: String, wave_path: String) -> String:
	if wave_path == "":
		return ""
	if wave_path.begins_with("res://") or wave_path.begins_with("user://") or wave_path.is_absolute_path():
		return wave_path
	return chart_path.get_base_dir().path_join(wave_path)


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


func _chart_replay_hash(path: String) -> String:
	if FileAccess.file_exists(path):
		return FileAccess.get_file_as_string(path).sha256_text()
	return path.sha256_text()
