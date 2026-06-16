extends SceneTree

const SessionState := preload("res://scripts/app/session_state.gd")
const GameConfig := preload("res://scripts/config/game_config.gd")

var failed_count := 0


func _init() -> void:
	var state := SessionState.new()
	_assert(state.selected_tja_path == "", "Selected TJA path should default empty")
	_assert(state.selected_audio_path == "", "Selected audio path should default empty")
	state.selected_tja_path = "res://songs/sample/sample.tja"
	state.selected_audio_path = "res://songs/sample/sample.ogg"
	state.clear_selection()
	_assert(state.selected_tja_path == "", "clear_selection should clear selected TJA path")
	_assert(state.selected_audio_path == "", "clear_selection should clear selected audio path")
	state.free()

	_test_fullscreen_shortcut_toggles_and_saves_config()
	_test_fullscreen_shortcut_reloads_saved_config_before_toggle()

	if failed_count == 0:
		print("PASS: SessionState")
		quit(0)
	else:
		push_error("FAIL: SessionState tests failed with %d assertion(s)." % failed_count)
		quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed_count += 1
		push_error("ASSERTION FAILED: " + message)


func _test_fullscreen_shortcut_toggles_and_saves_config() -> void:
	var path := "user://session_fullscreen_shortcut_test.json"
	DirAccess.remove_absolute(path)

	var state := SessionState.new()
	state.config.config_path = path
	state.config.fullscreen = false

	var event := InputEventKey.new()
	event.keycode = KEY_F11
	event.pressed = true
	state._unhandled_input(event)

	var loaded := GameConfig.new()
	loaded.config_path = path
	_assert(state.config.fullscreen, "F11 should toggle SessionState config fullscreen")
	_assert(loaded.load_config(), "F11 should save the toggled fullscreen config")
	_assert(loaded.fullscreen, "Saved config should preserve F11 fullscreen toggle")

	state.free()
	DirAccess.remove_absolute(path)


func _test_fullscreen_shortcut_reloads_saved_config_before_toggle() -> void:
	var path := "user://session_fullscreen_reload_test.json"
	DirAccess.remove_absolute(path)

	var saved := GameConfig.new()
	saved.config_path = path
	saved.fullscreen = true
	saved.save_config()

	var state := SessionState.new()
	state.config.config_path = path
	state.config.fullscreen = false

	var event := InputEventKey.new()
	event.keycode = KEY_F11
	event.pressed = true
	state._unhandled_input(event)

	var loaded := GameConfig.new()
	loaded.config_path = path
	_assert(not state.config.fullscreen, "F11 should reload saved fullscreen before toggling")
	_assert(loaded.load_config(), "Reloaded F11 toggle should save config")
	_assert(not loaded.fullscreen, "Saved config should switch from fullscreen back to windowed")

	state.free()
	DirAccess.remove_absolute(path)
