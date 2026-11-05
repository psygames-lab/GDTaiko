extends SceneTree

const GameplayScene: PackedScene = preload("res://scenes/Gameplay.tscn")
const Bridge := preload("res://scripts/telemetry/psygodot_bridge.gd")
var failed_count := 0
var output_dir := "user://telemetry_test_%d" % Time.get_ticks_usec()


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_assert(get_root().get_node("PsyGodotBridge").runtime == null, "Default autoload must not create a recording thread")
	for source in ["manual", "replay"]:
		var baseline := _exercise(false, source)
		var recorded := _exercise(true, source)
		_assert(baseline == recorded, "Capture must preserve every judgment, note state, gauge, score and replay input: " + source)
	_test_lifecycle()
	if failed_count == 0:
		print("PASS: PsyGodot integration (manual/replay boundaries, roll/balloon, lifecycle, complete output)")
	quit(0 if failed_count == 0 else 1)


func _new_controller() -> Node:
	var controller := GameplayScene.instantiate()
	get_root().add_child(controller)
	controller.set_process(false)
	controller.audio_player.stream = null
	controller.game_config.input_offset_ms = 0
	controller.chart.notes.clear()
	for i in range(8):
		controller.chart.notes.append({"id": "note_%d" % i, "time_sec": float(i + 1), "lane": "don", "kind": "don", "state": "pending"})
	controller.chart.notes.append({"id": "roll", "time_sec": 10.0, "duration_sec": 1.0, "lane": "roll", "kind": "roll_start", "state": "pending"})
	controller.chart.notes.append({"id": "balloon_clear", "time_sec": 12.0, "duration_sec": 1.0, "lane": "balloon", "kind": "balloon_start", "required_hits": 2, "state": "pending"})
	controller.chart.notes.append({"id": "balloon_expire", "time_sec": 14.0, "duration_sec": 1.0, "lane": "balloon", "kind": "balloon_start", "required_hits": 3, "state": "pending"})
	controller.chart.notes.append({"id": "final", "time_sec": 17.0, "lane": "don", "kind": "don", "state": "pending"})
	return controller


func _new_bridge(controller: Node) -> Node:
	var bridge := Bridge.new()
	get_root().add_child(bridge)
	bridge.attach(controller, {"output_dir": output_dir})
	return bridge


func _exercise(capture: bool, source: String) -> Array:
	var controller := _new_controller()
	var bridge: Node = _new_bridge(controller) if capture else null
	controller._start_song()
	controller.audio_player.stop()
	controller.clock.configure(null, 0.0)
	var states: Array = []
	var offsets := [0.0, 0.044999, 0.045001, 0.094999, 0.095001, 0.149999, 0.150001]
	for i in range(offsets.size()):
		_input_at(controller, float(i + 1) + offsets[i], source)
		states.append(_state(controller))
	controller._process_misses(9.0)
	states.append(_state(controller))
	_input_at(controller, 10.1, source)
	_input_at(controller, 10.2, source)
	controller._process_misses(11.2)
	states.append(_state(controller))
	_input_at(controller, 12.1, source)
	_input_at(controller, 12.2, source)
	states.append(_state(controller))
	_input_at(controller, 14.1, source)
	controller._process_misses(15.2)
	states.append(_state(controller))
	# Exercise the actual calibrated manual path and the replay path that must
	# not apply the current input offset a second time.
	controller.game_config.input_offset_ms = 37
	_input_at(controller, 17.0, source)
	states.append(_state(controller))
	_assert(controller.last_result["perfects"] == 3, "Boundary fixture should produce three perfects")
	_assert(controller.last_result["goods"] == 2, "Boundary fixture should produce two goods")
	_assert(controller.last_result["bads"] == 2, "Boundary fixture should produce two bads")
	_assert(controller.scoring.balloons_cleared == 1, "One balloon should clear")
	_assert(controller.scoring.roll_hits == 4, "Roll and uncleared balloon hit counts should remain unchanged")
	if capture:
		var events_path: String = bridge.runtime.get_raw_events_path()
		var manifest_path: String = bridge.runtime.get_manifest_path()
		bridge.shutdown()
		_assert(bridge.get_statistics()["complete"], "Capture should drain without drops or write errors")
		var rows := _read_rows(events_path)
		var tags: Array = []
		var prior_timestamp := -1
		for row in rows:
			tags.append(row["event_tag"])
			_assert(int(row["timestamp_usec"]) >= prior_timestamp, "Event capture times should be ordered")
			_assert(int(row["session_elapsed_usec"]) >= 0, "Elapsed capture time must be nonnegative")
			prior_timestamp = int(row["timestamp_usec"])
			if row["event_tag"] == "player_response":
				_assert(row["payload"]["source"] == source, "Raw stream must distinguish manual and replay")
		_assert(tags.count("note_hit") == 7, "Capture should include all accepted normal hits")
		_assert(tags.count("empty_hit") == 1 and tags.count("note_miss") == 2, "Empty hit and expired notes must be distinguishable")
		_assert(tags.count("roll_hit") == 2 and tags.count("roll_end") == 1, "Roll events should be complete")
		_assert(tags.count("balloon_hit") == 3 and tags.count("balloon_end") == 1, "Balloon clear and expiry should be observable")
		_assert(tags[-2] == "song_end" and tags[-1] == "session_end", "Last judgment must precede song and session end")
		var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
		_assert(manifest["metadata"]["notes"][0]["state"] == "pending", "Session chart metadata must be an immutable initial snapshot")
		_assert(manifest["recording"]["complete"], "Closed manifest must declare complete recording")
		DirAccess.remove_absolute(events_path)
		DirAccess.remove_absolute(manifest_path)
		bridge.free()
	controller.free()
	return states


func _input_at(controller: Node, song_time: float, source: String) -> void:
	if source == "replay":
		controller.apply_replay_input("don", song_time)
	else:
		controller.clock.fallback_time_sec = song_time - float(controller.game_config.input_offset_ms) / 1000.0
		var event := InputEventAction.new()
		event.action = "taiko_don"
		event.pressed = true
		controller._unhandled_input(event)


func _state(controller: Node) -> Dictionary:
	return {"result": controller._build_result_payload().duplicate(true), "notes": controller.chart.notes.duplicate(true), "replay": controller.replay_recorder.to_dictionary(), "playing": controller.playing}


func _test_lifecycle() -> void:
	var controller := _new_controller()
	var bridge := _new_bridge(controller)
	controller._start_song()
	var first_path: String = bridge.runtime.get_raw_events_path()
	var first_manifest: String = bridge.runtime.get_manifest_path()
	controller._set_paused(true)
	controller._set_paused(false)
	controller._restart_song()
	var second_path: String = bridge.runtime.get_raw_events_path()
	var second_manifest: String = bridge.runtime.get_manifest_path()
	controller.free()
	bridge.shutdown()
	_assert(bridge.get_statistics()["complete"], "Restart and scene exit must drain both sessions")
	var first := _read_rows(first_path)
	var second := _read_rows(second_path)
	_assert(first[-2]["payload"]["reason"] == "restarted", "Restart must close old session")
	_assert(second[-2]["payload"]["reason"] == "scene_exit", "Leaving scene must close active session")
	_assert(first[2]["event_tag"] == "pause" and first[3]["event_tag"] == "resume", "Pause/resume transitions should be captured once")
	for path in [first_path, first_manifest, second_path, second_manifest]:
		DirAccess.remove_absolute(path)
	bridge.free()
	DirAccess.remove_absolute(output_dir)


func _read_rows(path: String) -> Array:
	var rows: Array = []
	for line in FileAccess.get_file_as_string(path).split("\n", false):
		rows.append(JSON.parse_string(line))
	return rows


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed_count += 1
		push_error("ASSERTION FAILED: " + message)
