extends Node

const GameConfig := preload("res://scripts/config/game_config.gd")

var selected_tja_path: String = ""
var selected_audio_path: String = ""
var selected_course_name: String = ""
var selected_course_index: int = -1
var config := GameConfig.new()


func _ready() -> void:
	config.load_config()
	config.apply_to_project()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_fullscreen_shortcut(event):
		return
	config.load_config()
	config.toggle_fullscreen()
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()


func clear_selection() -> void:
	selected_tja_path = ""
	selected_audio_path = ""
	selected_course_name = ""
	selected_course_index = -1


func _is_fullscreen_shortcut(event: InputEvent) -> bool:
	if not event is InputEventKey:
		return false
	var key_event := event as InputEventKey
	return key_event.pressed and not key_event.echo and key_event.keycode == KEY_F11
