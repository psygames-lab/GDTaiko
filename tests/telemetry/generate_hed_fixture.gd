extends SceneTree

# Original generated notes and scripted inputs. No song library or audio is used.
const Gameplay := preload("res://scripts/gameplay/gameplay_controller.gd")
const Bridge := preload("res://scripts/telemetry/psygodot_bridge.gd")
var controller: Node

func _init() -> void:
	call_deferred("run")

func run() -> void:
	controller = Gameplay.new()
	root.add_child(controller)
	controller.set_process(false)
	controller.audio_player.stream = null
	controller.don_sfx_player.stream = null
	controller.ka_sfx_player.stream = null
	controller.game_config.input_offset_ms = 0
	controller.game_config.chart_offset_ms = 0
	controller.clock.configure(null, 0.0)
	controller.current_chart_path = "original_hed_fixture"
	controller.chart.notes.assign([
		{"id": "manual", "time_sec": 1.0, "lane": "don", "kind": "don", "state": "pending"},
		{"id": "replay", "time_sec": 2.0, "lane": "ka", "kind": "ka", "state": "pending"},
		{"id": "miss", "time_sec": 3.0, "lane": "don", "kind": "don", "state": "pending"},
		{"id": "roll", "time_sec": 4.0, "duration_sec": 1.0, "lane": "roll", "kind": "roll_start", "state": "pending"},
		{"id": "balloon_clear", "time_sec": 6.0, "duration_sec": 1.0, "lane": "balloon", "kind": "balloon_start", "required_hits": 2, "state": "pending"},
		{"id": "balloon_expire", "time_sec": 8.0, "duration_sec": 1.0, "lane": "balloon", "kind": "balloon_start", "required_hits": 3, "state": "pending"},
		{"id": "final", "time_sec": 10.0, "lane": "don", "kind": "don", "state": "pending"},
	])
	var bridge := Bridge.new()
	root.add_child(bridge)
	bridge.attach(controller, {"output_dir": "res://output/hed_fixture", "study_id": "original_hed_fixture"})
	controller._start_song()
	manual_input("don", 1.0)
	controller.apply_replay_input("ka", 2.035)
	controller._process_misses(3.2)
	manual_input("don", 4.1)
	controller.apply_replay_input("ka", 4.2)
	controller._process_misses(5.2)
	manual_input("don", 6.1)
	controller.apply_replay_input("ka", 6.2)
	manual_input("don", 8.1)
	controller._process_misses(9.2)
	manual_input("don", 9.5)
	controller._set_paused(true)
	controller._set_paused(false)
	controller.apply_replay_input("don", 10.1)
	bridge.shutdown()
	print("RAW=", ProjectSettings.globalize_path(bridge.runtime.get_raw_events_path()))
	print("MANIFEST=", ProjectSettings.globalize_path(bridge.runtime.get_manifest_path()))
	var statistics: Dictionary = bridge.get_statistics()
	print("RECORDING=", JSON.stringify(statistics))
	controller.free()
	bridge.free()
	quit(0 if statistics["complete"] else 1)

func manual_input(lane: String, song_time: float) -> void:
	controller.clock.fallback_time_sec = song_time
	var event := InputEventAction.new()
	event.action = "taiko_" + lane
	event.pressed = true
	controller._unhandled_input(event)
