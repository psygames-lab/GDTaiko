extends RefCounted
class_name GameConfig

const DEFAULT_CONFIG_PATH := "user://config.json"

var config_path := DEFAULT_CONFIG_PATH
var master_volume := 1.0
var music_volume := 1.0
var sfx_volume := 1.0
var chart_offset_ms := 0
var input_offset_ms := 0
var don_keys: Array = [KEY_F]
var ka_keys: Array = [KEY_J]
var fullscreen := false
var show_debug_monitor := false


func load_config() -> bool:
	if not FileAccess.file_exists(config_path):
		return false
	var file := FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return false
	_apply_dictionary(parsed)
	return true


func save_config() -> bool:
	var file := FileAccess.open(config_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(_to_dictionary(), "\t"))
	return true


func apply_to_project() -> void:
	_set_bus_volume("Master", master_volume)
	_set_bus_volume("Music", music_volume)
	_set_bus_volume("SFX", sfx_volume)
	_ensure_action_keys("taiko_don", don_keys)
	_ensure_action_keys("taiko_ka", ka_keys)
	DisplayServer.window_set_mode(_window_mode_for_fullscreen(fullscreen))


func toggle_fullscreen() -> void:
	fullscreen = not fullscreen
	apply_to_project()
	save_config()


func _window_mode_for_fullscreen(is_fullscreen: bool) -> DisplayServer.WindowMode:
	return DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN if is_fullscreen else DisplayServer.WINDOW_MODE_WINDOWED


func _to_dictionary() -> Dictionary:
	return {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"chart_offset_ms": chart_offset_ms,
		"input_offset_ms": input_offset_ms,
		"don_keys": don_keys,
		"ka_keys": ka_keys,
		"fullscreen": fullscreen,
		"show_debug_monitor": show_debug_monitor,
	}


func _apply_dictionary(data: Dictionary) -> void:
	master_volume = clampf(float(data.get("master_volume", master_volume)), 0.0, 1.0)
	music_volume = clampf(float(data.get("music_volume", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(data.get("sfx_volume", sfx_volume)), 0.0, 1.0)
	chart_offset_ms = int(data.get("chart_offset_ms", chart_offset_ms))
	input_offset_ms = int(data.get("input_offset_ms", input_offset_ms))
	don_keys = _parse_keys(data.get("don_keys", don_keys), don_keys)
	ka_keys = _parse_keys(data.get("ka_keys", ka_keys), ka_keys)
	fullscreen = bool(data.get("fullscreen", fullscreen))
	show_debug_monitor = bool(data.get("show_debug_monitor", show_debug_monitor))


func _parse_keys(value: Variant, fallback: Array) -> Array:
	if not value is Array:
		return fallback.duplicate()
	var keys := []
	for item in value:
		keys.append(int(item))
	return keys


func _ensure_action_keys(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	for key in keys:
		var event := InputEventKey.new()
		event.keycode = int(key)
		InputMap.action_add_event(action, event)


func _set_bus_volume(bus_name: String, value: float) -> void:
	var bus_index := _ensure_audio_bus(bus_name)
	if bus_index == -1:
		return
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(clampf(value, 0.0, 1.0)))


func _ensure_audio_bus(bus_name: String) -> int:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index != -1:
		return bus_index
	if bus_name == "Master":
		return -1
	AudioServer.add_bus()
	bus_index = AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(bus_index, bus_name)
	return bus_index
