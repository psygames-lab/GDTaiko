extends Control
class_name SongSelect

const SongFolderScanner := preload("res://scripts/song/song_folder_scanner.gd")
const SongEntry := preload("res://scripts/song/song_entry.gd")
const SongCourse := preload("res://scripts/song/song_course.gd")

const SONG_SELECT_BACKGROUND := "res://assets/skin/night_festival/backgrounds/main_menu.png"
const VIEWPORT_SIZE := Vector2(1280.0, 720.0)
const DEFAULT_SONG_ROOTS := ["res://songs", "res://local_songs", "user://songs"]
const WHEEL_ROW_COUNT := 5

var songs: Array[SongEntry] = []
var selected_song_index := 0
var selected_course_index := 0
var title_label: Label
var subtitle_label: Label
var detail_label: Label
var metadata_label: Label
var list_label: Label
var song_wheel: Control
var course_strip: HBoxContainer
var options_button: Button
var preview_player: AudioStreamPlayer
var preview_fade_tween: Tween
var preview_audio_key := ""
var preview_restart_count := 0
var auto_load_on_ready := true


func _ready() -> void:
	build()
	if auto_load_on_ready:
		load_song_roots(default_song_roots())


func build() -> void:
	if title_label != null:
		return
	_add_background()
	_add_background_dim(0.34)

	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var top_bar := HBoxContainer.new()
	top_bar.name = "TopBar"
	top_bar.position = Vector2(32, 20)
	top_bar.size = Vector2(1216, 52)
	top_bar.add_theme_constant_override("separation", 12)
	root.add_child(top_bar)

	var heading := Label.new()
	heading.name = "Heading"
	heading.text = "Song Select"
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_font_size_override("font_size", 30)
	top_bar.add_child(heading)

	options_button = Button.new()
	options_button.name = "OptionsButton"
	options_button.text = "Options"
	options_button.custom_minimum_size = Vector2(132, 44)
	options_button.add_theme_font_size_override("font_size", 19)
	options_button.add_theme_stylebox_override("normal", _button_style(Color(0.08, 0.075, 0.07, 0.56), Color(0.78, 0.58, 0.34, 0.36)))
	options_button.add_theme_stylebox_override("hover", _button_style(Color(0.15, 0.11, 0.08, 0.82), Color(0.92, 0.68, 0.36, 0.86)))
	options_button.pressed.connect(_on_options_pressed)
	top_bar.add_child(options_button)

	var content := Control.new()
	content.name = "Content"
	content.position = Vector2(44.0, 84.0)
	content.size = Vector2(1192.0, 584.0)
	root.add_child(content)

	var list_panel := Panel.new()
	list_panel.name = "ListPanel"
	list_panel.position = Vector2.ZERO
	list_panel.size = Vector2(420, 584)
	list_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.045, 0.05, 0.78), Color(0.78, 0.58, 0.35, 0.62), 2))
	content.add_child(list_panel)

	song_wheel = Control.new()
	song_wheel.name = "SongWheel"
	song_wheel.position = Vector2(22, 28)
	song_wheel.size = Vector2(376, 528)
	list_panel.add_child(song_wheel)

	var detail_panel := Panel.new()
	detail_panel.name = "DetailPanel"
	detail_panel.position = Vector2(462, 64)
	detail_panel.size = Vector2(730, 378)
	detail_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.92, 0.82, 0.63, 0.86), Color(0.78, 0.52, 0.24, 0.84), 2))
	content.add_child(detail_panel)

	list_label = _label(song_wheel, "", Vector2.ZERO, 18, Vector2(1, 1))
	list_label.visible = false
	title_label = _label(detail_panel, "No songs", Vector2(38, 34), 34, Vector2(650, 92))
	subtitle_label = _label(detail_panel, "", Vector2(38, 126), 21, Vector2(640, 34))
	detail_label = _label(detail_panel, "", Vector2(38, 176), 26, Vector2(650, 46))
	metadata_label = _label(detail_panel, "", Vector2(38, 290), 19, Vector2(650, 62))
	for label in [title_label, subtitle_label, detail_label, metadata_label]:
		label.add_theme_color_override("font_color", Color(0.12, 0.105, 0.085))
	course_strip = HBoxContainer.new()
	course_strip.name = "CourseStrip"
	course_strip.position = Vector2(38, 234)
	course_strip.size = Vector2(650, 44)
	course_strip.add_theme_constant_override("separation", 10)
	detail_panel.add_child(course_strip)
	preview_player = AudioStreamPlayer.new()
	preview_player.name = "PreviewPlayer"
	_ensure_audio_bus("Music")
	preview_player.bus = "Music"
	add_child(preview_player)


func load_songs(root_path: String) -> void:
	songs = SongFolderScanner.scan(root_path)
	selected_song_index = 0
	selected_course_index = 0
	_update_selection()


static func default_song_roots() -> Array:
	return DEFAULT_SONG_ROOTS.duplicate()


func load_song_roots(root_paths: Array) -> void:
	songs = []
	for root_path in root_paths:
		songs.append_array(SongFolderScanner.scan(String(root_path)))
	songs.sort_custom(func(a: SongEntry, b: SongEntry) -> bool: return a.title.naturalnocasecmp_to(b.title) < 0)
	selected_song_index = 0
	selected_course_index = 0
	_update_selection()


func select_next_song() -> void:
	if songs.is_empty():
		return
	selected_song_index = (selected_song_index + 1) % songs.size()
	selected_course_index = 0
	_update_selection(true)


func select_previous_song() -> void:
	if songs.is_empty():
		return
	selected_song_index = (selected_song_index - 1 + songs.size()) % songs.size()
	selected_course_index = 0
	_update_selection(true)


func select_next_course() -> void:
	var song := selected_song()
	if song == null or song.courses.is_empty():
		return
	selected_course_index = (selected_course_index + 1) % song.courses.size()
	_update_selection(false)


func select_previous_course() -> void:
	var song := selected_song()
	if song == null or song.courses.is_empty():
		return
	selected_course_index = (selected_course_index - 1 + song.courses.size()) % song.courses.size()
	_update_selection(false)


func selected_song() -> SongEntry:
	if songs.is_empty():
		return null
	return songs[clamp(selected_song_index, 0, songs.size() - 1)]


func selected_course() -> SongCourse:
	var song := selected_song()
	if song == null or song.courses.is_empty():
		return null
	return song.courses[clamp(selected_course_index, 0, song.courses.size() - 1)]


func start_selected_course() -> void:
	if not apply_selected_course_to_session():
		return
	get_tree().change_scene_to_file("res://scenes/Gameplay.tscn")


func open_options() -> void:
	get_tree().change_scene_to_file("res://scenes/Options.tscn")


func apply_selected_course_to_session() -> bool:
	var course := selected_course()
	if course == null:
		return false
	if not course.can_launch():
		return false
	var state := get_tree().root.get_node_or_null("SessionState")
	if state != null:
		state.selected_tja_path = course.tja_path
		state.selected_audio_path = course.wave
		state.selected_course_name = course.course
		state.selected_course_index = course.course_index if course.course_index >= 0 else selected_course_index
	return state != null


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_down"):
		select_next_song()
	elif event.is_action_pressed("ui_up"):
		select_previous_song()
	elif event.is_action_pressed("ui_right"):
		select_next_course()
	elif event.is_action_pressed("ui_left"):
		select_previous_course()
	elif event.is_action_pressed("ui_accept"):
		start_selected_course()


func _on_options_pressed() -> void:
	open_options()


func _update_selection(restart_preview: bool = true) -> void:
	build()
	if songs.is_empty():
		_update_song_wheel()
		title_label.text = "No songs"
		subtitle_label.text = ""
		detail_label.text = ""
		metadata_label.text = ""
		_update_course_strip(null)
		_stop_preview()
		return

	var song := selected_song()
	var course := selected_course()
	_update_song_wheel()
	title_label.text = _normalize_display_text(song.title)
	subtitle_label.text = _normalize_display_text(song.subtitle)
	metadata_label.text = _metadata_text(song)
	_update_course_strip(song)
	if course == null:
		detail_label.text = "No courses"
	elif course.audio_missing:
		detail_label.text = "%s  Missing audio: %s" % [_course_display_text(course), course.expected_audio_path.get_file()]
	else:
		detail_label.text = _course_display_text(course)
	if restart_preview:
		_update_preview(song)


func _label(parent: Node, text: String, label_position: Vector2, font_size: int, label_size: Vector2) -> Label:
	var label := Label.new()
	label.text = text
	label.position = label_position
	label.size = label_size
	label.custom_minimum_size = label_size
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.88))
	parent.add_child(label)
	return label


func _add_background() -> void:
	var texture := _load_png_texture(SONG_SELECT_BACKGROUND)
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
	fallback.color = Color(0.035, 0.04, 0.055)
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


func _song_has_missing_audio(song: SongEntry) -> bool:
	for course in song.courses:
		if course.audio_missing:
			return true
	return false


func _update_song_wheel() -> void:
	if song_wheel == null:
		return
	for child in song_wheel.get_children():
		if child != list_label:
			song_wheel.remove_child(child)
			child.free()
	if songs.is_empty():
		return

	var center_y := song_wheel.size.y * 0.5
	var row_height := 84.0
	var start_offset := -int(WHEEL_ROW_COUNT / 2)
	for row in range(WHEEL_ROW_COUNT):
		var offset := start_offset + row
		var song_index := (selected_song_index + offset + songs.size()) % songs.size()
		var is_selected := offset == 0
		var distance: int = abs(offset)
		var panel := Panel.new()
		panel.name = "SongRow%d" % row
		panel.position = Vector2(0.0, center_y + (offset * row_height) - 34.0)
		panel.size = Vector2(song_wheel.size.x, 68.0)
		panel.scale = Vector2.ONE * (1.0 if is_selected else 0.94)
		panel.modulate = Color(1.0, 1.0, 1.0, 1.0 - (0.18 * distance))
		panel.add_theme_stylebox_override("panel", _panel_style(
			Color(0.15, 0.11, 0.08, 0.88) if is_selected else Color(0.04, 0.05, 0.055, 0.56),
			Color(0.92, 0.67, 0.34, 0.92) if is_selected else Color(0.72, 0.55, 0.34, 0.26),
			2 if is_selected else 1
		))
		song_wheel.add_child(panel)

		var title := Label.new()
		title.name = "Title"
		title.position = Vector2(18, 9)
		title.size = Vector2(panel.size.x - 36.0, 28.0)
		title.text = _ellipsize(_normalize_display_text(songs[song_index].title), 34)
		title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		title.add_theme_font_size_override("font_size", 23 if is_selected else 19)
		title.add_theme_color_override("font_color", Color(0.98, 0.92, 0.78) if is_selected else Color(0.82, 0.84, 0.80))
		panel.add_child(title)

		var meta := Label.new()
		meta.name = "Meta"
		meta.position = Vector2(18, 38)
		meta.size = Vector2(panel.size.x - 36.0, 22.0)
		meta.text = _song_row_meta(songs[song_index])
		meta.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		meta.add_theme_font_size_override("font_size", 15)
		meta.add_theme_color_override("font_color", Color(0.90, 0.74, 0.48) if is_selected else Color(0.56, 0.60, 0.58))
		panel.add_child(meta)


func _update_course_strip(song: SongEntry) -> void:
	if course_strip == null:
		return
	for child in course_strip.get_children():
		course_strip.remove_child(child)
		child.free()
	if song == null:
		return
	for i in range(song.courses.size()):
		var course := song.courses[i]
		var selected := i == selected_course_index
		var badge := Panel.new()
		badge.name = "CourseBadge%d" % i
		badge.custom_minimum_size = Vector2(118, 38)
		badge.add_theme_stylebox_override("panel", _panel_style(
			_course_color(course.course, 0.88) if selected else Color(0.16, 0.14, 0.12, 0.38),
			Color(0.12, 0.10, 0.08, 0.42),
			1
		))
		course_strip.add_child(badge)

		var label := Label.new()
		label.position = Vector2(10, 7)
		label.size = Vector2(98, 24)
		label.text = "%s %d" % [_course_icon(course.course), course.level]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color.WHITE if selected else Color(0.80, 0.78, 0.72))
		badge.add_child(label)


func _song_row_meta(song: SongEntry) -> String:
	var parts: Array[String] = []
	if song.genre != "":
		parts.append(_normalize_display_text(song.genre))
	if not song.courses.is_empty():
		parts.append("%d courses" % song.courses.size())
	if _song_has_missing_audio(song):
		parts.append("missing audio")
	return " / ".join(parts)


func _course_display_text(course: SongCourse) -> String:
	return "%s %s  Level %d" % [_course_icon(course.course), _course_name(course.course), course.level]


func _course_icon(course_name: String) -> String:
	match course_name.to_lower():
		"easy":
			return "[E]"
		"normal":
			return "[N]"
		"hard":
			return "[H]"
		"oni":
			return "[O]"
		"edit":
			return "[X]"
		_:
			return "[?]"


func _course_name(course_name: String) -> String:
	match course_name.to_lower():
		"easy":
			return "Easy"
		"normal":
			return "Normal"
		"hard":
			return "Hard"
		"oni":
			return "Oni"
		"edit":
			return "Edit"
		_:
			return _normalize_display_text(course_name)


func _course_color(course_name: String, alpha: float) -> Color:
	match course_name.to_lower():
		"easy":
			return Color(0.20, 0.62, 0.42, alpha)
		"normal":
			return Color(0.28, 0.47, 0.86, alpha)
		"hard":
			return Color(0.82, 0.48, 0.18, alpha)
		"oni":
			return Color(0.74, 0.18, 0.18, alpha)
		"edit":
			return Color(0.54, 0.31, 0.75, alpha)
		_:
			return Color(0.46, 0.46, 0.46, alpha)


func _normalize_display_text(value: String) -> String:
	var text := value.strip_edges().replace("\n", " ").replace("\t", " ")
	while text.contains("  "):
		text = text.replace("  ", " ")
	return text


func _ellipsize(value: String, max_chars: int) -> String:
	if value.length() <= max_chars:
		return value
	return value.left(max_chars - 3) + "..."


func _panel_style(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.26)
	style.shadow_size = 8
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
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
	return style


func _metadata_text(song: SongEntry) -> String:
	var parts: Array[String] = []
	if song.genre != "":
		parts.append("Genre: %s" % _normalize_display_text(song.genre))
	if song.maker != "":
		parts.append("Maker: %s" % _normalize_display_text(song.maker))
	var course_parts: Array[String] = []
	for course in song.courses:
		course_parts.append(_course_display_text(course))
	if not course_parts.is_empty():
		parts.append("Courses: %s" % ", ".join(course_parts))
	return "  |  ".join(parts)


func _update_preview(song: SongEntry) -> void:
	if preview_player == null:
		return
	if preview_audio_key == song.preview_audio_path and preview_player.stream != null:
		return
	_stop_preview()
	if song.preview_audio_path == "" or not FileAccess.file_exists(song.preview_audio_path):
		return
	var stream := _load_audio_stream(song.preview_audio_path)
	if stream == null:
		return
	preview_audio_key = song.preview_audio_path
	preview_restart_count += 1
	preview_player.stream = stream
	preview_player.volume_db = linear_to_db(0.01)
	preview_player.play(song.preview_start_sec)
	preview_fade_tween = create_tween()
	preview_fade_tween.tween_property(preview_player, "volume_db", linear_to_db(1.0), 0.25)


func _stop_preview() -> void:
	if preview_fade_tween != null:
		preview_fade_tween.kill()
		preview_fade_tween = null
	if preview_player != null:
		preview_player.stop()
		preview_player.stream = null
	preview_audio_key = ""


func _ensure_audio_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, bus_name)


func _load_audio_stream(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		var stream = load(path)
		if stream is AudioStream:
			return stream
	if path.get_extension().to_lower() == "ogg":
		return AudioStreamOggVorbis.load_from_file(path)
	return null
