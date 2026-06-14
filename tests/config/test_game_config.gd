extends SceneTree

const GameConfig := preload("res://scripts/config/game_config.gd")

var failed_count := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_defaults()
	_test_save_and_load_config()
	_test_apply_to_project_updates_audio_and_input_map()

	if failed_count == 0:
		print("PASS: GameConfig")
		quit(0)
	else:
		push_error("FAIL: GameConfig tests failed with %d assertion(s)." % failed_count)
		quit(1)


func _test_defaults() -> void:
	var config := GameConfig.new()
	_assert(is_equal_approx(config.master_volume, 1.0), "Default master volume should be 1")
	_assert(is_equal_approx(config.music_volume, 1.0), "Default music volume should be 1")
	_assert(is_equal_approx(config.sfx_volume, 1.0), "Default SFX volume should be 1")
	_assert(config.chart_offset_ms == 0, "Default chart offset should be 0")
	_assert(config.input_offset_ms == 0, "Default input offset should be 0")
	_assert(config.don_keys == [KEY_F], "Default Don key should be F")
	_assert(config.ka_keys == [KEY_J], "Default Ka key should be J")
	_assert(not config.fullscreen, "Default fullscreen should be false")
	_assert(config.show_debug_monitor, "Default debug monitor should be visible in development")


func _test_save_and_load_config() -> void:
	var path := "user://config_test.json"
	DirAccess.remove_absolute(path)

	var config := GameConfig.new()
	config.config_path = path
	config.master_volume = 0.7
	config.music_volume = 0.4
	config.sfx_volume = 0.6
	config.chart_offset_ms = -25
	config.input_offset_ms = 12
	config.don_keys = [KEY_D, KEY_F]
	config.ka_keys = [KEY_J, KEY_K]
	config.fullscreen = true
	config.show_debug_monitor = false
	_assert(config.save_config(), "Config should save")

	var loaded := GameConfig.new()
	loaded.config_path = path
	_assert(loaded.load_config(), "Config should load")
	_assert(is_equal_approx(loaded.master_volume, 0.7), "Loaded master volume should match")
	_assert(is_equal_approx(loaded.music_volume, 0.4), "Loaded music volume should match")
	_assert(is_equal_approx(loaded.sfx_volume, 0.6), "Loaded SFX volume should match")
	_assert(loaded.chart_offset_ms == -25, "Loaded chart offset should match")
	_assert(loaded.input_offset_ms == 12, "Loaded input offset should match")
	_assert(loaded.don_keys == [KEY_D, KEY_F], "Loaded Don keys should match")
	_assert(loaded.ka_keys == [KEY_J, KEY_K], "Loaded Ka keys should match")
	_assert(loaded.fullscreen, "Loaded fullscreen should match")
	_assert(not loaded.show_debug_monitor, "Loaded debug monitor visibility should match")
	DirAccess.remove_absolute(path)


func _test_apply_to_project_updates_audio_and_input_map() -> void:
	var config := GameConfig.new()
	config.master_volume = 0.5
	config.music_volume = 0.25
	config.sfx_volume = 0.75
	config.don_keys = [KEY_D]
	config.ka_keys = [KEY_K]
	config.fullscreen = false
	config.apply_to_project()

	_assert(InputMap.has_action("taiko_don"), "Config should ensure taiko_don action")
	_assert(InputMap.has_action("taiko_ka"), "Config should ensure taiko_ka action")
	_assert(_action_has_key("taiko_don", KEY_D), "Config should apply Don key")
	_assert(_action_has_key("taiko_ka", KEY_K), "Config should apply Ka key")
	_assert(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")), linear_to_db(0.5)), "Config should apply master volume")
	_assert(AudioServer.get_bus_index("Music") != -1, "Config should ensure Music bus exists")
	_assert(AudioServer.get_bus_index("SFX") != -1, "Config should ensure SFX bus exists")
	_assert(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")), linear_to_db(0.25)), "Config should apply music volume")
	_assert(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")), linear_to_db(0.75)), "Config should apply SFX volume")


func _action_has_key(action: String, keycode: Key) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and event.keycode == keycode:
			return true
	return false


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed_count += 1
		push_error("ASSERTION FAILED: " + message)
