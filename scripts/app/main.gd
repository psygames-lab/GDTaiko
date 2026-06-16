extends Control

const GameConfig := preload("res://scripts/config/game_config.gd")

const MAIN_MENU_BACKGROUND := "res://assets/skin/night_festival/backgrounds/main_menu.png"
const VIEWPORT_SIZE := Vector2(1280.0, 720.0)
const MENU_PANEL_SIZE := Vector2(430.0, 390.0)

var play_button: Button
var options_button: Button
var quit_button: Button


func _ready() -> void:
	var config := GameConfig.new()
	config.load_config()
	config.apply_to_project()
	build()


func build() -> void:
	if play_button != null:
		return

	_add_background()
	_add_background_dim(0.32)

	var panel := Panel.new()
	panel.name = "MenuPanel"
	panel.position = (VIEWPORT_SIZE - MENU_PANEL_SIZE) * 0.5
	panel.size = MENU_PANEL_SIZE
	panel.modulate = Color(1.0, 1.0, 1.0, 0.86)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.04, 0.055, 0.06, 0.78), Color(0.77, 0.58, 0.34, 0.86), 2))
	add_child(panel)

	var menu := VBoxContainer.new()
	menu.name = "MainMenu"
	menu.position = Vector2(48.0, 46.0)
	menu.size = MENU_PANEL_SIZE - Vector2(96.0, 92.0)
	menu.add_theme_constant_override("separation", 16)
	panel.add_child(menu)

	var title := Label.new()
	title.name = "Title"
	title.text = "GDTaiko"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(0.0, 72.0)
	title.add_theme_color_override("font_color", Color(0.96, 0.91, 0.82))
	title.add_theme_font_size_override("font_size", 44)
	menu.add_child(title)

	play_button = _menu_button("Play")
	play_button.name = "PlayButton"
	play_button.pressed.connect(_on_play_pressed)
	menu.add_child(play_button)

	options_button = _menu_button("Options")
	options_button.name = "OptionsButton"
	options_button.pressed.connect(_on_options_pressed)
	menu.add_child(options_button)

	quit_button = _menu_button("Quit")
	quit_button.name = "QuitButton"
	quit_button.pressed.connect(_on_quit_pressed)
	menu.add_child(quit_button)


func _menu_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(334, 52)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 23)
	button.add_theme_color_override("font_color", Color(0.94, 0.91, 0.84))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _button_style(Color(0.07, 0.075, 0.075, 0.54), Color(0.74, 0.56, 0.34, 0.26)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.15, 0.12, 0.09, 0.78), Color(0.92, 0.67, 0.35, 0.82)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.22, 0.15, 0.09, 0.92), Color(1.0, 0.74, 0.40, 0.9)))
	return button


func _add_background() -> void:
	var texture := _load_png_texture(MAIN_MENU_BACKGROUND)
	if texture != null:
		var background := TextureRect.new()
		background.name = "Background"
		background.position = Vector2.ZERO
		background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background.stretch_mode = TextureRect.STRETCH_SCALE
		background.texture = texture
		add_child(background)
		background.size = VIEWPORT_SIZE
		return

	var fallback := ColorRect.new()
	fallback.name = "Background"
	fallback.color = Color(0.06, 0.07, 0.09)
	fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fallback)


func _add_background_dim(alpha: float) -> void:
	var dim := ColorRect.new()
	dim.name = "BackgroundDim"
	dim.color = Color(0.0, 0.0, 0.0, alpha)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)


func _load_png_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var texture := load(path)
		if texture is Texture2D:
			return texture
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)


func _panel_style(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.34)
	style.shadow_size = 14
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	return style


func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 18
	style.content_margin_right = 18
	return style


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/SongSelect.tscn")


func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Options.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
