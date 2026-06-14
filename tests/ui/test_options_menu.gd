extends SceneTree

const OptionsMenuScript := preload("res://scripts/ui/options_menu.gd")
const GameConfig := preload("res://scripts/config/game_config.gd")

class FakeConfig:
	var chart_offset_ms := -12
	var input_offset_ms := 18
	var master_volume := 0.75
	var music_volume := 0.4
	var sfx_volume := 0.9
	var fullscreen := true
	var show_debug_monitor := false
	var don_keys := [KEY_D]
	var ka_keys := [KEY_K]


var failed_count := 0


func _init() -> void:
	_test_defaults()
	_test_ready_creates_backing_config()
	_test_config_loading_and_updates()
	_test_real_game_config_updates()
	_test_key_rebind_updates_config()

	if failed_count == 0:
		print("PASS: OptionsMenu")
		quit(0)
	else:
		push_error("FAIL: OptionsMenu tests failed with %d assertion(s)." % failed_count)
		quit(1)


func _test_defaults() -> void:
	var menu := OptionsMenuScript.new() as Node
	menu.build()

	_assert(menu.chart_offset_spin.value == float(0), "Default chart offset should be 0 ms")
	_assert(menu.input_offset_spin.value == float(0), "Default input offset should be 0 ms")
	_assert(is_equal_approx(menu.master_volume_slider.value, 1.0), "Default master volume should be 1.0")
	_assert(is_equal_approx(menu.music_volume_slider.value, 1.0), "Default music volume should be 1.0")
	_assert(is_equal_approx(menu.sfx_volume_slider.value, 1.0), "Default SFX volume should be 1.0")
	_assert(not menu.fullscreen_checkbox.button_pressed, "Default fullscreen should be false")
	_assert(menu.don_button.text == "Don: F", "Default Don bind should show F")
	_assert(menu.ka_button.text == "Ka: J", "Default Ka bind should show J")

	menu.free()


func _test_ready_creates_backing_config() -> void:
	DirAccess.remove_absolute("user://config.json")
	var scene := preload("res://scenes/Options.tscn").instantiate()
	scene._ready()
	scene.chart_offset_spin.value = 31
	scene._on_chart_offset_changed(31)
	_assert(scene.config != null, "Options scene should create a backing GameConfig")
	_assert(scene.config.chart_offset_ms == 31, "Options scene should write changes to backing config")
	_assert(FileAccess.file_exists("user://config.json"), "Options scene should save backing config")
	scene.free()
	DirAccess.remove_absolute("user://config.json")


func _test_config_loading_and_updates() -> void:
	var menu := OptionsMenuScript.new() as Node
	var config := FakeConfig.new()
	menu.set_config(config)

	_assert(menu.chart_offset_spin.value == float(-12), "Menu should apply config chart offset")
	_assert(menu.input_offset_spin.value == float(18), "Menu should apply config input offset")
	_assert(is_equal_approx(menu.master_volume_slider.value, 0.75), "Menu should apply config master volume")
	_assert(is_equal_approx(menu.music_volume_slider.value, 0.4), "Menu should apply config music volume")
	_assert(is_equal_approx(menu.sfx_volume_slider.value, 0.9), "Menu should apply config SFX volume")
	_assert(menu.fullscreen_checkbox.button_pressed, "Menu should apply config fullscreen state")
	_assert(not menu.debug_monitor_checkbox.button_pressed, "Menu should apply debug monitor state")
	_assert(menu.don_button.text == "Don: D", "Menu should apply Don key")
	_assert(menu.ka_button.text == "Ka: K", "Menu should apply Ka key")

	menu.chart_offset_spin.value = 25
	menu._on_chart_offset_changed(25)
	menu.input_offset_spin.value = -8
	menu._on_input_offset_changed(-8)
	menu.master_volume_slider.value = 0.2
	menu._on_master_volume_changed(0.2)
	menu.music_volume_slider.value = 0.3
	menu._on_music_volume_changed(0.3)
	menu.sfx_volume_slider.value = 0.5
	menu._on_sfx_volume_changed(0.5)
	menu.fullscreen_checkbox.button_pressed = false
	menu._on_fullscreen_toggled(false)
	menu.debug_monitor_checkbox.button_pressed = true
	menu._on_debug_monitor_toggled(true)

	_assert(menu.chart_offset_spin.value == 25, "Chart offset widget should show set value")
	_assert(config.chart_offset_ms == 25, "Menu change should write chart offset to config")
	_assert(config.input_offset_ms == -8, "Menu change should write input offset to config")
	_assert(is_equal_approx(config.master_volume, 0.2), "Menu change should write master volume to config")
	_assert(is_equal_approx(config.music_volume, 0.3), "Menu change should write music volume to config")
	_assert(is_equal_approx(config.sfx_volume, 0.5), "Menu change should write SFX volume to config")
	_assert(config.fullscreen == false, "Menu change should write fullscreen to config")
	_assert(config.show_debug_monitor == true, "Menu change should write debug monitor visibility to config")

	menu.free()


func _test_real_game_config_updates() -> void:
	var menu := OptionsMenuScript.new() as Node
	var config := GameConfig.new()
	config.chart_offset_ms = 4
	config.input_offset_ms = -2
	config.show_debug_monitor = false
	menu.set_config(config)

	menu.chart_offset_spin.value = 44
	menu._on_chart_offset_changed(44)
	menu.input_offset_spin.value = -22
	menu._on_input_offset_changed(-22)
	menu.debug_monitor_checkbox.button_pressed = true
	menu._on_debug_monitor_toggled(true)

	_assert(config.chart_offset_ms == 44, "Menu should write chart offset to GameConfig")
	_assert(config.input_offset_ms == -22, "Menu should write input offset to GameConfig")
	_assert(config.show_debug_monitor, "Menu should write debug monitor visibility to GameConfig")
	menu.free()


func _test_key_rebind_updates_config() -> void:
	var menu := OptionsMenuScript.new() as Node
	var config := FakeConfig.new()
	menu.set_config(config)

	menu._on_don_bind_pressed()
	var don_key_event := InputEventKey.new()
	don_key_event.keycode = KEY_H
	don_key_event.pressed = true
	menu._unhandled_input(don_key_event)
	_assert(config.don_keys == [KEY_H], "Don rebind should update config key list")
	_assert(menu.don_button.text == "Don: H", "Don button should show rebound key")

	menu._on_ka_bind_pressed()
	var ka_key_event := InputEventKey.new()
	ka_key_event.keycode = KEY_L
	ka_key_event.pressed = true
	menu._unhandled_input(ka_key_event)
	_assert(config.ka_keys == [KEY_L], "Ka rebind should update config key list")
	_assert(menu.ka_button.text == "Ka: L", "Ka button should show rebound key")

	menu.free()


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed_count += 1
		push_error("ASSERTION FAILED: " + message)
