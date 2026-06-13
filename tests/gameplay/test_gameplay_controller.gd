extends SceneTree

const GameplayScene: PackedScene = preload("res://scenes/Gameplay.tscn")
const GameplayController := preload("res://scripts/gameplay/gameplay_controller.gd")
const NoteModel := preload("res://scripts/gameplay/note_model.gd")

var failed_count := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_instantiates_gameplay_scene()
	_test_ready_builds_scene_and_loads_sample()
	_test_loads_sample_chart()
	_test_textures_and_spawned_notes()
	_test_start_song_resets_state()
	_test_input_actions_start_and_hit()
	_test_ka_input_action_hits_ka()
	_test_process_moves_notes()
	_test_immediate_don_hit()
	_test_process_misses_marks_pending_as_missed()
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
	var lane_child_count: int = controller.lane.get_child_count()
	_assert(lane_child_count == controller.chart.notes.size(), "lane should spawn one sprite per note")
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


func _test_free_instantiated_scene() -> void:
	var controller := _new_controller()
	_assert(is_instance_valid(controller), "Controller instance should be valid before cleanup")
	controller.free()


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed_count += 1
		push_error("ASSERTION FAILED: " + message)
