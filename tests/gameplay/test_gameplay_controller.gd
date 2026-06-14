extends SceneTree

const GameplayScene: PackedScene = preload("res://scenes/Gameplay.tscn")
const GameplayController := preload("res://scripts/gameplay/gameplay_controller.gd")
const NoteModel := preload("res://scripts/gameplay/note_model.gd")

var failed_count := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	DirAccess.remove_absolute("user://config.json")
	_test_instantiates_gameplay_scene()
	_test_ready_builds_scene_and_loads_sample()
	_test_ready_loads_session_selected_chart()
	_test_loads_sample_chart()
	_test_textures_and_spawned_notes()
	_test_start_song_resets_state()
	_test_input_actions_start_and_hit()
	_test_ka_input_action_hits_ka()
	_test_process_moves_notes()
	_test_immediate_don_hit()
	_test_immediate_don_hit_spawns_effect()
	_test_process_misses_marks_pending_as_missed()
	_test_empty_miss_spawns_effect()
	_test_roll_hit_without_normal_note()
	_test_active_roll_is_not_missed_at_start_expiry()
	_test_roll_finishes_without_miss_after_duration()
	_test_normal_note_inside_roll_window_takes_priority()
	_test_balloon_hits_clear_note()
	_test_balloon_expires_without_miss_when_not_cleared()
	_test_cleared_balloon_does_not_score_again()
	_test_gogo_event_updates_scoring_before_hit()
	_test_gogo_event_updates_lane_overlay()
	_test_config_offsets_apply_to_clock_and_input()
	_test_song_finish_shows_result_payload()
	_test_free_instantiated_scene()

	if failed_count == 0:
		print("PASS: GameplayController")
		quit(0)
	else:
		push_error("FAIL: GameplayController tests failed with %d assertion(s)." % failed_count)
		quit(1)


func _new_controller() -> Node:
	var scene := GameplayScene.instantiate() as Node
	get_root().add_child(scene)
	return scene


func _test_instantiates_gameplay_scene() -> void:
	var scene := GameplayScene.instantiate()
	_assert(scene != null, "Gameplay.tscn should instantiate")
	_assert(scene is GameplayController, "Gameplay scene root should use gameplay_controller.gd")
	scene.free()


func _test_ready_builds_scene_and_loads_sample() -> void:
	var controller := _new_controller()
	_assert(controller.chart != null, "Ready should load sample chart")
	_assert(controller.audio_player != null, "AudioStreamPlayer should be built")
	_assert(controller.clock != null, "SongClock should be built")
	_assert(controller.lane != null, "NoteLane should be built")
	_assert(controller.hud != null, "TaikoHud should be built")
	controller.free()


func _test_ready_loads_session_selected_chart() -> void:
	var state = get_root().get_node_or_null("SessionState")
	_assert(state != null, "SessionState autoload should exist")
	if state == null:
		return
	var chart_path := "user://selected_song.tja"
	var chart := FileAccess.open(chart_path, FileAccess.WRITE)
	chart.store_string("""TITLE:Selected Song
COURSE:Oni
LEVEL:4
BPM:120
#START
1000,
#END
""")
	chart.close()
	state.selected_tja_path = chart_path
	state.selected_audio_path = ""

	var controller := _new_controller()
	_assert(controller.chart.title == "Selected Song", "Gameplay should load SessionState selected chart")
	_assert(controller.chart.level == 4, "Gameplay should load selected chart metadata")
	controller.free()
	state.clear_selection()
	DirAccess.remove_absolute(chart_path)


func _test_loads_sample_chart() -> void:
	var controller := _new_controller()
	_assert(controller.chart != null, "Sample chart should load from sample.tja")
	_assert(controller.chart.title == "GDTaiko Sample", "Sample title should match fixture")
	_assert(controller.chart.wave == "sample.ogg", "Sample wave should match fixture")
	_assert(controller.chart.notes.size() == 6, "Sample chart should include 6 supported notes")
	_assert(controller.chart.notes[0]["lane"] == NoteModel.DON, "First sample note should be Don")
	_assert(is_equal_approx(controller.chart.notes[0]["time_sec"], 0.0), "First sample note should be at time 0.0")
	controller.free()


func _test_textures_and_spawned_notes() -> void:
	var controller := _new_controller()
	_assert(controller.lane.get_node_or_null("LaneBackground") != null, "Gameplay lane should build skin background")
	_assert(controller.lane.note_nodes.size() == controller.chart.notes.size(), "lane should track one sprite per note")
	var first_note: String = controller.chart.notes[0]["id"]
	var second_note: String = controller.chart.notes[1]["id"]
	_assert(controller.lane.note_nodes.has(first_note), "spawned note should be tracked by id")
	_assert(controller.lane.note_nodes.has(second_note), "spawned note should be tracked by id")
	_assert((controller.lane.note_nodes[first_note] as Sprite2D).texture != null, "Don note sprite should have texture")
	_assert((controller.lane.note_nodes[second_note] as Sprite2D).texture != null, "Ka note sprite should have texture")
	controller.free()


func _test_start_song_resets_state() -> void:
	var controller := _new_controller()
	controller.scoring.apply_judgment("perfect")
	controller.scoring.apply_judgment("good")
	controller._start_song()
	_assert(controller.playing, "start action should set playing=true")
	_assert(controller.scoring.score == 0, "start action should reset score")
	_assert(controller.scoring.combo == 0, "start action should reset combo")
	_assert(controller.hud.status_label.text == "Playing", "HUD should say Playing after start")
	controller.free()


func _test_input_actions_start_and_hit() -> void:
	var controller := _new_controller()
	var start_event := InputEventAction.new()
	start_event.action = "taiko_start"
	start_event.pressed = true
	controller._unhandled_input(start_event)
	_assert(controller.playing, "taiko_start action should start playback")

	var don_event := InputEventAction.new()
	don_event.action = "taiko_don"
	don_event.pressed = true
	controller._unhandled_input(don_event)
	_assert(controller.chart.notes[0]["state"] == NoteModel.HIT, "taiko_don action should hit the first Don")
	_assert(controller.scoring.combo == 1, "taiko_don action should update combo")
	controller.free()


func _test_ka_input_action_hits_ka() -> void:
	var controller := _new_controller()
	controller._start_song()
	controller.audio_player.stop()
	controller.clock.configure(null, 0.0)
	controller.clock.advance(1.5)

	var ka_event := InputEventAction.new()
	ka_event.action = "taiko_ka"
	ka_event.pressed = true
	controller._unhandled_input(ka_event)

	_assert(controller.chart.notes[1]["state"] == NoteModel.HIT, "taiko_ka action should hit the first Ka")
	_assert(controller.scoring.combo == 1, "taiko_ka action should update combo")
	controller.free()


func _test_process_moves_notes() -> void:
	var controller := _new_controller()
	controller._start_song()
	var first_note_id: String = controller.chart.notes[0]["id"]
	var sprite := controller.lane.note_nodes[first_note_id] as Sprite2D
	var start_x := sprite.position.x
	controller._process(0.25)
	_assert(sprite.position.x < start_x, "process should move spawned notes toward the hit target")
	controller.free()


func _test_immediate_don_hit() -> void:
	var controller := _new_controller()
	controller._start_song()
	controller._hit("don")
	_assert(controller.scoring.score == 1000, "Hitting first Don at time 0 should score perfect")
	_assert(controller.scoring.combo == 1, "Hitting first Don should increment combo to 1")
	_assert(controller.chart.notes[0]["state"] == NoteModel.HIT, "First sample note should become hit")
	controller.free()


func _test_immediate_don_hit_spawns_effect() -> void:
	var controller := _new_controller()
	controller._start_song()
	controller._hit("don")
	_assert(_has_effect(controller.hit_effects, "hit", "perfect"), "Perfect hit should spawn a hit effect")
	controller.free()


func _test_process_misses_marks_pending_as_missed() -> void:
	var controller := _new_controller()
	controller._start_song()
	controller._process_misses(10.0)
	var miss_count := 0
	for note in controller.chart.notes:
		if String(note.get("state", NoteModel.PENDING)) == NoteModel.MISSED:
			miss_count += 1
	_assert(miss_count == controller.chart.notes.size(), "All pending notes should be marked missed at late time")
	_assert(controller.scoring.misses == controller.chart.notes.size(), "Miss count should match number of missed notes")
	_assert(controller.scoring.combo == 0, "Combo should be zero after miss processing")
	controller.free()


func _test_empty_miss_spawns_effect() -> void:
	var controller := _new_controller()
	controller._start_song()
	controller._apply_empty_miss()
	_assert(_has_effect(controller.hit_effects, "miss", "miss"), "Empty miss should spawn a miss effect")
	controller.free()


func _test_roll_hit_without_normal_note() -> void:
	var controller := _new_controller()
	controller.chart.notes.clear()
	controller.chart.notes.append({
		"id": "roll_1",
		"time_sec": 1.0,
		"duration_sec": 2.0,
		"lane": "roll",
		"kind": "roll_start",
		"state": NoteModel.PENDING,
	})
	controller._start_song()
	controller.audio_player.stop()
	controller.clock.configure(null, 0.0)
	controller.clock.advance(1.0)

	var don_event := InputEventAction.new()
	don_event.action = "taiko_don"
	don_event.pressed = true
	controller._unhandled_input(don_event)

	_assert(controller.scoring.roll_hits == 1, "Pressing Don during active roll should increment roll hit count")
	_assert(controller.scoring.score == 100, "Roll hit should add 100 score")
	_assert(controller.scoring.combo == 0, "Roll hit should not change combo")
	controller.free()


func _test_active_roll_is_not_missed_at_start_expiry() -> void:
	var controller := _new_controller()
	controller.chart.notes.clear()
	controller.chart.notes.append({
		"id": "roll_1",
		"time_sec": 1.0,
		"duration_sec": 2.0,
		"lane": "roll",
		"kind": "roll_start",
		"state": NoteModel.PENDING,
	})
	controller._start_song()
	controller._process_misses(1.25)
	_assert(controller.chart.notes[0]["state"] == NoteModel.PENDING, "Active roll should not miss before its end")
	_assert(controller.playing, "Single-roll chart should keep playing while roll is active")
	controller.free()


func _test_roll_finishes_without_miss_after_duration() -> void:
	var controller := _new_controller()
	controller.chart.notes.clear()
	controller.chart.notes.append({
		"id": "roll_1",
		"time_sec": 1.0,
		"duration_sec": 2.0,
		"lane": "roll",
		"kind": "roll_start",
		"state": NoteModel.PENDING,
	})
	controller._start_song()
	controller._process_misses(3.2)
	_assert(controller.chart.notes[0]["state"] == NoteModel.HIT, "Expired roll should complete without miss")
	_assert(controller.scoring.misses == 0, "Expired roll should not increment misses")
	_assert(controller.playing == false, "Single-roll chart should finish after roll duration")
	controller.free()


func _test_normal_note_inside_roll_window_takes_priority() -> void:
	var controller := _new_controller()
	controller.chart.notes.clear()
	controller.chart.notes.append({
		"id": "roll_1",
		"time_sec": 1.0,
		"duration_sec": 2.0,
		"lane": "roll",
		"kind": "roll_start",
		"state": NoteModel.PENDING,
	})
	controller.chart.notes.append({
		"id": "don_1",
		"time_sec": 1.5,
		"lane": NoteModel.DON,
		"kind": NoteModel.DON,
		"state": NoteModel.PENDING,
	})
	controller._start_song()
	controller.audio_player.stop()
	controller.clock.configure(null, 0.0)
	controller.clock.advance(1.5)

	var don_event := InputEventAction.new()
	don_event.action = "taiko_don"
	don_event.pressed = true
	controller._unhandled_input(don_event)

	_assert(controller.chart.notes[1]["state"] == NoteModel.HIT, "Normal Don note should be hittable during active roll")
	_assert(controller.scoring.combo == 1, "Normal Don hit should update combo during active roll")
	_assert(controller.scoring.roll_hits == 0, "Normal Don priority should not also score a roll hit")
	controller.free()


func _test_balloon_hits_clear_note() -> void:
	var controller := _new_controller()
	controller.chart.notes.clear()
	controller.chart.notes.append({
		"id": "balloon_1",
		"time_sec": 1.0,
		"duration_sec": 2.0,
		"lane": "balloon",
		"kind": "balloon_start",
		"required_hits": 2,
		"state": NoteModel.PENDING,
	})
	controller._start_song()
	controller.audio_player.stop()
	controller.clock.configure(null, 0.0)
	controller.clock.advance(1.0)

	var don_event := InputEventAction.new()
	don_event.action = "taiko_don"
	don_event.pressed = true
	controller._unhandled_input(don_event)
	_assert(controller.scoring.roll_hits == 1, "First balloon hit should count as roll hit")
	_assert(controller.scoring.score == 100, "First balloon hit should award roll score")
	_assert(controller.chart.notes[0]["state"] == NoteModel.PENDING, "Balloon should remain pending before required hits")

	controller._unhandled_input(don_event)
	_assert(controller.scoring.balloons_cleared == 1, "Required balloon hit should clear balloon")
	_assert(controller.scoring.score == 5100, "Balloon clear should add clear score after prior roll hit")
	_assert(controller.chart.notes[0]["state"] == NoteModel.HIT, "Cleared balloon should become hit")
	_assert(controller.playing == false, "Single-balloon chart should finish when balloon clears")
	controller.free()


func _test_balloon_expires_without_miss_when_not_cleared() -> void:
	var controller := _new_controller()
	controller.chart.notes.clear()
	controller.chart.notes.append({
		"id": "balloon_1",
		"time_sec": 1.0,
		"duration_sec": 2.0,
		"lane": "balloon",
		"kind": "balloon_start",
		"required_hits": 3,
		"state": NoteModel.PENDING,
	})
	controller._start_song()
	controller._process_misses(3.2)
	_assert(controller.chart.notes[0]["state"] == NoteModel.HIT, "Expired balloon should be consumed without normal miss")
	_assert(controller.scoring.misses == 0, "Expired balloon should not increment misses")
	_assert(controller.scoring.balloons_cleared == 0, "Uncleared expired balloon should not count as cleared")
	_assert(controller.playing == false, "Single-balloon chart should finish after duration")
	controller.free()


func _test_cleared_balloon_does_not_score_again() -> void:
	var controller := _new_controller()
	controller.chart.notes.clear()
	controller.chart.notes.append({
		"id": "balloon_1",
		"time_sec": 1.0,
		"duration_sec": 2.0,
		"lane": "balloon",
		"kind": "balloon_start",
		"required_hits": 1,
		"state": NoteModel.PENDING,
	})
	controller.chart.notes.append({
		"id": "don_future",
		"time_sec": 4.0,
		"lane": NoteModel.DON,
		"kind": NoteModel.DON,
		"state": NoteModel.PENDING,
	})
	controller._start_song()
	controller.audio_player.stop()
	controller.clock.configure(null, 0.0)
	controller.clock.advance(1.0)

	var don_event := InputEventAction.new()
	don_event.action = "taiko_don"
	don_event.pressed = true
	controller._unhandled_input(don_event)
	controller._unhandled_input(don_event)

	_assert(controller.scoring.balloons_cleared == 1, "Cleared balloon should not clear again while chart continues")
	_assert(controller.scoring.score == 5000, "Second hit after clear should not add duplicate balloon score")
	_assert(controller.chart.notes[1]["state"] == NoteModel.PENDING, "Future note should keep chart playing for regression")
	controller.free()


func _test_gogo_event_updates_scoring_before_hit() -> void:
	var controller := _new_controller()
	controller.chart.timing_events.append({
		"time_sec": 0.0,
		"type": "gogo",
		"value": true,
	})
	controller._start_song()
	controller.audio_player.stop()
	controller.clock.configure(null, 0.0)
	controller._hit(NoteModel.DON)
	_assert(controller.scoring.score == 1200, "GOGO event at current time should multiply normal hit score")
	controller.free()


func _test_gogo_event_updates_lane_overlay() -> void:
	var controller := _new_controller()
	controller.chart.timing_events.append({
		"time_sec": 0.0,
		"type": "gogo",
		"value": true,
	})
	controller._start_song()
	controller._update_timing_states(0.0)
	var overlay := controller.lane.get_node("GogoOverlay") as CanvasItem
	_assert(overlay.visible, "GOGO timing event should show lane overlay")
	controller.free()


func _test_config_offsets_apply_to_clock_and_input() -> void:
	var controller := _new_controller()
	controller.game_config.chart_offset_ms = 250
	controller.game_config.input_offset_ms = 100
	controller._load_sample_chart()
	_assert(is_equal_approx(controller.clock.chart_offset_sec, controller.chart.offset_sec + 0.25), "Config chart offset should apply to song clock")
	controller._start_song()
	controller._hit(NoteModel.DON)
	_assert(is_equal_approx(float(controller.replay_recorder.inputs[0]["time_sec"]), controller.chart.offset_sec + 0.35), "Config input offset should apply to recorded hit time")
	controller.free()


func _test_song_finish_shows_result_payload() -> void:
	var controller := _new_controller()
	controller.chart.notes.clear()
	controller.chart.notes.append({
		"id": "don_1",
		"time_sec": 0.0,
		"lane": NoteModel.DON,
		"kind": NoteModel.DON,
		"state": NoteModel.PENDING,
	})
	controller._start_song()
	controller._hit(NoteModel.DON)

	var result_screen = controller.get("result_screen")
	var last_result = controller.get("last_result")
	_assert(controller.playing == false, "Single-note chart should stop when final note is resolved")
	_assert(result_screen != null, "Controller should expose a result screen")
	_assert(result_screen != null and result_screen.visible, "Result screen should be visible after song finish")
	_assert(last_result is Dictionary, "Controller should expose a result payload")
	if last_result is Dictionary:
		_assert(last_result["score"] == 1000, "Result payload should include final score")
		_assert(last_result.has("song_key"), "Result payload should include song key for score storage")
		_assert(last_result.has("course"), "Result payload should include course for score storage")
		if last_result.has("song_key"):
			_assert(last_result["song_key"] != "", "Result payload song key should not be empty")
		if last_result.has("course"):
			_assert(last_result["course"] == "Oni", "Result payload should include course for score storage")
		_assert(last_result["max_combo"] == 1, "Result payload should include max combo")
		_assert(last_result["perfects"] == 1, "Result payload should include perfect count")
		_assert(is_equal_approx(float(last_result["gauge"]), 2.0), "Result payload should include soul gauge value")
		_assert(last_result["clear"] == false, "Low gauge should not clear")
	controller.free()


func _test_free_instantiated_scene() -> void:
	var controller := _new_controller()
	_assert(is_instance_valid(controller), "Controller instance should be valid before cleanup")
	controller.free()


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed_count += 1
		push_error("ASSERTION FAILED: " + message)


func _has_effect(hit_effects: Node, kind: String, judgment: String) -> bool:
	for effect in hit_effects.effects:
		if effect.get_meta("effect_type", "") == kind and effect.get_meta("judgment", "") == judgment:
			return true
	return false
