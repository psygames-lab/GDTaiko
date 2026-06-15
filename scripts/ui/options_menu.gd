extends Control
class_name OptionsMenu

signal options_changed

const GameConfig := preload("res://scripts/config/game_config.gd")

const OPTIONS_BACKGROUND := "res://assets/skin/night_festival/backgrounds/main_menu.png"
const UI_PANEL_SHEET := "res://assets/skin/night_festival/ui/ui_panels.png"
const VIEWPORT_SIZE := Vector2(1280.0, 720.0)
const OPTIONS_PANEL_SIZE := Vector2(720.0, 624.0)

const DEFAULT_CHART_OFFSET_MS := 0
const DEFAULT_INPUT_OFFSET_MS := 0
const DEFAULT_MASTER_VOLUME := 1.0
const DEFAULT_MUSIC_VOLUME := 1.0
const DEFAULT_SFX_VOLUME := 1.0
const DEFAULT_FULLSCREEN := false
const DEFAULT_SHOW_DEBUG_MONITOR := false
const DEFAULT_DON_KEYS: Array[int] = [KEY_F]
const DEFAULT_KA_KEYS: Array[int] = [KEY_J]

var config: Object
var is_syncing_ui := false
var pending_keybind_action := ""

var chart_offset_ms := DEFAULT_CHART_OFFSET_MS
var input_offset_ms := DEFAULT_INPUT_OFFSET_MS
var master_volume := DEFAULT_MASTER_VOLUME
var music_volume := DEFAULT_MUSIC_VOLUME
var sfx_volume := DEFAULT_SFX_VOLUME
var fullscreen := DEFAULT_FULLSCREEN
var show_debug_monitor := DEFAULT_SHOW_DEBUG_MONITOR
var don_keys: Array = DEFAULT_DON_KEYS.duplicate()
var ka_keys: Array = DEFAULT_KA_KEYS.duplicate()

var chart_offset_spin: SpinBox
var input_offset_spin: SpinBox
var master_volume_slider: HSlider
var music_volume_slider: HSlider
var sfx_volume_slider: HSlider
var master_volume_label: Label
var music_volume_label: Label
var sfx_volume_label: Label
var fullscreen_checkbox: CheckBox
var debug_monitor_checkbox: CheckBox
var don_button: Button
var ka_button: Button
var back_button: Button


func _ready() -> void:
	build()
	if config == null:
		var loaded_config := GameConfig.new()
		loaded_config.load_config()
		set_config(loaded_config)
		loaded_config.apply_to_project()
	else:
		set_config(config)


func set_config(new_config: Object) -> void:
	config = new_config
	if chart_offset_spin == null:
		build()
		return
	_load_from_config()
	_sync_ui_from_state()


func build() -> void:
	if chart_offset_spin != null:
		return
	var panel := _add_background()

	var container := VBoxContainer.new()
	container.name = "OptionsContainer"
	container.position = Vector2(56, 42)
	container.size = OPTIONS_PANEL_SIZE - Vector2(112, 84)
	container.add_theme_constant_override("separation", 14)
	panel.add_child(container)

	var header := HBoxContainer.new()
	header.name = "Header"
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override("separation", 16)
	container.add_child(header)

	var title := _label("Options", 36)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(120, 44)
	back_button.pressed.connect(_on_back_pressed)
	header.add_child(back_button)

	var chart_row := HBoxContainer.new()
	chart_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(chart_row)
	chart_row.add_child(_label("Chart Offset (ms)", 28))
	chart_offset_spin = SpinBox.new()
	chart_offset_spin.min_value = -500
	chart_offset_spin.max_value = 500
	chart_offset_spin.step = 1
	chart_offset_spin.allow_greater = true
	chart_offset_spin.allow_lesser = true
	chart_offset_spin.value_changed.connect(_on_chart_offset_changed)
	chart_row.add_child(chart_offset_spin)

	var input_row := HBoxContainer.new()
	input_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(input_row)
	input_row.add_child(_label("Input Offset (ms)", 28))
	input_offset_spin = SpinBox.new()
	input_offset_spin.min_value = -500
	input_offset_spin.max_value = 500
	input_offset_spin.step = 1
	input_offset_spin.allow_greater = true
	input_offset_spin.allow_lesser = true
	input_offset_spin.value_changed.connect(_on_input_offset_changed)
	input_row.add_child(input_offset_spin)

	var master_row := HBoxContainer.new()
	master_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(master_row)
	master_volume_label = _label("Master: 100%", 24)
	master_row.add_child(master_volume_label)
	master_volume_slider = HSlider.new()
	master_volume_slider.min_value = 0.0
	master_volume_slider.max_value = 1.0
	master_volume_slider.step = 0.01
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	master_row.add_child(master_volume_slider)

	var music_row := HBoxContainer.new()
	music_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(music_row)
	music_volume_label = _label("Music: 100%", 24)
	music_row.add_child(music_volume_label)
	music_volume_slider = HSlider.new()
	music_volume_slider.min_value = 0.0
	music_volume_slider.max_value = 1.0
	music_volume_slider.step = 0.01
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	music_row.add_child(music_volume_slider)

	var sfx_row := HBoxContainer.new()
	sfx_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(sfx_row)
	sfx_volume_label = _label("SFX: 100%", 24)
	sfx_row.add_child(sfx_volume_label)
	sfx_volume_slider = HSlider.new()
	sfx_volume_slider.min_value = 0.0
	sfx_volume_slider.max_value = 1.0
	sfx_volume_slider.step = 0.01
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	sfx_row.add_child(sfx_volume_slider)

	var fullscreen_row := HBoxContainer.new()
	fullscreen_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(fullscreen_row)
	fullscreen_row.add_child(_label("Fullscreen", 28))
	fullscreen_checkbox = CheckBox.new()
	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
	fullscreen_row.add_child(fullscreen_checkbox)

	var debug_row := HBoxContainer.new()
	debug_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(debug_row)
	debug_row.add_child(_label("Debug Monitor", 28))
	debug_monitor_checkbox = CheckBox.new()
	debug_monitor_checkbox.toggled.connect(_on_debug_monitor_toggled)
	debug_row.add_child(debug_monitor_checkbox)

	var don_row := HBoxContainer.new()
	don_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(don_row)
	don_row.add_child(_label("Don", 28))
	don_button = Button.new()
	don_button.pressed.connect(_on_don_bind_pressed)
	don_row.add_child(don_button)

	var ka_row := HBoxContainer.new()
	ka_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(ka_row)
	ka_row.add_child(_label("Ka", 28))
	ka_button = Button.new()
	ka_button.pressed.connect(_on_ka_bind_pressed)
	ka_row.add_child(ka_button)

	_load_from_config()
	_sync_ui_from_state()


func _unhandled_input(event: InputEvent) -> void:
	if pending_keybind_action == "":
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	var key_event := event as InputEventKey
	if key_event.keycode == KEY_ESCAPE:
		pending_keybind_action = ""
		_sync_ui_from_state()
		return

	if key_event.keycode == 0:
		return

	_bind_key(key_event.keycode)
	pending_keybind_action = ""
	_sync_ui_from_state()
	emit_signal("options_changed")


func _load_from_config() -> void:
	chart_offset_ms = int(_read_int("chart_offset_ms", DEFAULT_CHART_OFFSET_MS))
	input_offset_ms = int(_read_int("input_offset_ms", DEFAULT_INPUT_OFFSET_MS))
	master_volume = float(_read_float("master_volume", DEFAULT_MASTER_VOLUME))
	music_volume = float(_read_float("music_volume", DEFAULT_MUSIC_VOLUME))
	sfx_volume = float(_read_float("sfx_volume", DEFAULT_SFX_VOLUME))
	fullscreen = bool(_read_bool("fullscreen", DEFAULT_FULLSCREEN))
	show_debug_monitor = bool(_read_bool("show_debug_monitor", DEFAULT_SHOW_DEBUG_MONITOR))
	don_keys = _read_key_list("don_keys", DEFAULT_DON_KEYS.duplicate())
	ka_keys = _read_key_list("ka_keys", DEFAULT_KA_KEYS.duplicate())


func _sync_ui_from_state() -> void:
	if is_syncing_ui:
		return
	is_syncing_ui = true

	chart_offset_spin.value = chart_offset_ms
	input_offset_spin.value = input_offset_ms
	master_volume_slider.value = clamp(master_volume, 0.0, 1.0)
	music_volume_slider.value = clamp(music_volume, 0.0, 1.0)
	sfx_volume_slider.value = clamp(sfx_volume, 0.0, 1.0)
	fullscreen_checkbox.button_pressed = fullscreen
	debug_monitor_checkbox.button_pressed = show_debug_monitor

	master_volume_label.text = "Master: %d%%" % int(round(master_volume * 100.0))
	music_volume_label.text = "Music: %d%%" % int(round(music_volume * 100.0))
	sfx_volume_label.text = "SFX: %d%%" % int(round(sfx_volume * 100.0))
	don_button.text = _key_button_text("Don", _key_list_to_text(don_keys), pending_keybind_action == "don")
	ka_button.text = _key_button_text("Ka", _key_list_to_text(ka_keys), pending_keybind_action == "ka")

	is_syncing_ui = false


func _on_chart_offset_changed(value: float) -> void:
	if is_syncing_ui:
		return
	chart_offset_ms = int(value)
	_write_config("chart_offset_ms", chart_offset_ms)
	emit_signal("options_changed")


func _on_input_offset_changed(value: float) -> void:
	if is_syncing_ui:
		return
	input_offset_ms = int(value)
	_write_config("input_offset_ms", input_offset_ms)
	emit_signal("options_changed")


func _on_master_volume_changed(value: float) -> void:
	if is_syncing_ui:
		return
	master_volume = clamp(value, 0.0, 1.0)
	master_volume_label.text = "Master: %d%%" % int(round(master_volume * 100.0))
	_write_config("master_volume", master_volume)
	emit_signal("options_changed")


func _on_music_volume_changed(value: float) -> void:
	if is_syncing_ui:
		return
	music_volume = clamp(value, 0.0, 1.0)
	music_volume_label.text = "Music: %d%%" % int(round(music_volume * 100.0))
	_write_config("music_volume", music_volume)
	emit_signal("options_changed")


func _on_sfx_volume_changed(value: float) -> void:
	if is_syncing_ui:
		return
	sfx_volume = clamp(value, 0.0, 1.0)
	sfx_volume_label.text = "SFX: %d%%" % int(round(sfx_volume * 100.0))
	_write_config("sfx_volume", sfx_volume)
	emit_signal("options_changed")


func _on_fullscreen_toggled(value: bool) -> void:
	if is_syncing_ui:
		return
	fullscreen = value
	_write_config("fullscreen", fullscreen)
	emit_signal("options_changed")


func _on_debug_monitor_toggled(value: bool) -> void:
	if is_syncing_ui:
		return
	show_debug_monitor = value
	_write_config("show_debug_monitor", show_debug_monitor)
	emit_signal("options_changed")


func _on_don_bind_pressed() -> void:
	pending_keybind_action = "don"
	_sync_ui_from_state()


func _on_ka_bind_pressed() -> void:
	pending_keybind_action = "ka"
	_sync_ui_from_state()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _bind_key(keycode: int) -> void:
	if pending_keybind_action == "don":
		don_keys = [keycode]
		_write_config("don_keys", don_keys.duplicate())
	elif pending_keybind_action == "ka":
		ka_keys = [keycode]
		_write_config("ka_keys", ka_keys.duplicate())


func _key_button_text(prefix: String, key_names: String, is_pending: bool) -> String:
	if is_pending:
		return "%s: press a key..." % prefix
	return "%s: %s" % [prefix, key_names]


func _read_int(key: String, fallback: int) -> int:
	var value: Variant = _read_config_property(key)
	if value is int:
		return int(value)
	if value is float:
		return int(value)
	return fallback


func _read_float(key: String, fallback: float) -> float:
	var value: Variant = _read_config_property(key)
	if value is float:
		return float(value)
	if value is int:
		return float(value)
	return fallback


func _read_bool(key: String, fallback: bool) -> bool:
	var value: Variant = _read_config_property(key)
	if value is bool:
		return bool(value)
	return fallback


func _read_key_list(key: String, fallback: Array) -> Array:
	var value: Variant = _read_config_property(key)
	if value is Array:
		return (value as Array).duplicate()
	if value is PackedInt32Array:
		return Array(value)
	return fallback.duplicate()


func _read_config_property(property_name: String) -> Variant:
	if config == null:
		return null
	for property in config.get_property_list():
		if String(property["name"]) == property_name:
			return config.get(property_name)
	return null


func _write_config(key: String, value: Variant) -> void:
	if config == null:
		return
	for property in config.get_property_list():
		if String(property["name"]) == key:
			config.set(key, value)
			if config.has_method("save_config"):
				config.save_config()
			if config.has_method("apply_to_project"):
				config.apply_to_project()
			return


func _key_list_to_text(keys: Array) -> String:
	if keys.is_empty():
		return "unbound"
	var labels: PackedStringArray = PackedStringArray()
	for key in keys:
		labels.append(_key_name(int(key)))
	return ", ".join(labels)


func _key_name(keycode: int) -> String:
	if keycode == KEY_SPACE:
		return "Space"
	if keycode == KEY_ENTER:
		return "Enter"
	if keycode == KEY_BACKSPACE:
		return "Backspace"
	if keycode == KEY_TAB:
		return "Tab"
	if keycode >= KEY_A and keycode <= KEY_Z:
		return char(keycode)
	if keycode >= KEY_0 and keycode <= KEY_9:
		return char(keycode)
	if keycode == 0:
		return "Unbound"
	return "Key %d" % keycode


func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _add_background() -> TextureRect:
	var texture := _load_png_texture(OPTIONS_BACKGROUND)
	if texture is Texture2D:
		var background := TextureRect.new()
		background.name = "Background"
		background.position = Vector2.ZERO
		background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background.stretch_mode = TextureRect.STRETCH_SCALE
		background.texture = texture
		add_child(background)
		background.size = VIEWPORT_SIZE
	else:
		var fallback := ColorRect.new()
		fallback.name = "Background"
		fallback.color = Color(0.035, 0.04, 0.055)
		fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(fallback)

	var dim := ColorRect.new()
	dim.name = "BackgroundDim"
	dim.color = Color(0.0, 0.0, 0.0, 0.36)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := TextureRect.new()
	panel.name = "OptionsPanel"
	panel.position = (VIEWPORT_SIZE - OPTIONS_PANEL_SIZE) * 0.5
	panel.size = OPTIONS_PANEL_SIZE
	panel.texture = _make_ui_panel_texture(Rect2(42.0, 74.0, 690.0, 486.0))
	panel.stretch_mode = TextureRect.STRETCH_SCALE
	panel.modulate = Color(1.0, 1.0, 1.0, 0.92)
	add_child(panel)
	return panel


func _load_png_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var texture := load(path)
		if texture is Texture2D:
			return texture
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)


func _make_ui_panel_texture(region: Rect2) -> Texture2D:
	var sheet := _load_png_texture(UI_PANEL_SHEET)
	if sheet == null:
		return null
	var texture := AtlasTexture.new()
	texture.atlas = sheet
	texture.region = region
	return texture
