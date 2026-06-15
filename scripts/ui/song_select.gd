extends Control
class_name SongSelect

const SongFolderScanner := preload("res://scripts/song/song_folder_scanner.gd")
const SongEntry := preload("res://scripts/song/song_entry.gd")
const SongCourse := preload("res://scripts/song/song_course.gd")

const SONG_SELECT_BACKGROUND := "res://assets/skin/night_festival/backgrounds/main_menu.png"
const UI_PANEL_SHEET := "res://assets/skin/night_festival/ui/ui_panels.png"
const VIEWPORT_SIZE := Vector2(1280.0, 720.0)

var songs: Array[SongEntry] = []
var selected_song_index := 0
var selected_course_index := 0
var title_label: Label
var subtitle_label: Label
var detail_label: Label
var metadata_label: Label
var list_label: Label
var options_button: Button
var preview_player: AudioStreamPlayer
var preview_fade_tween: Tween


func _ready() -> void:
	build()
	load_song_roots(["res://songs", "user://songs"])


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
	options_button.pressed.connect(_on_options_pressed)
	top_bar.add_child(options_button)

	var content := Control.new()
	content.name = "Content"
	content.position = Vector2(44.0, 84.0)
	content.size = Vector2(1192.0, 584.0)
	root.add_child(content)

	var list_panel := TextureRect.new()
	list_panel.name = "ListPanel"
	list_panel.position = Vector2.ZERO
	list_panel.size = Vector2(430, 584)
	list_panel.texture = _make_ui_panel_texture(Rect2(42.0, 74.0, 690.0, 486.0))
	list_panel.stretch_mode = TextureRect.STRETCH_SCALE
	list_panel.modulate = Color(1.0, 1.0, 1.0, 0.88)
	content.add_child(list_panel)

	var detail_panel := TextureRect.new()
	detail_panel.name = "DetailPanel"
	detail_panel.position = Vector2(464, 44)
	detail_panel.size = Vector2(728, 332)
	detail_panel.texture = _make_ui_panel_texture(Rect2(782.0, 302.0, 704.0, 438.0))
	detail_panel.stretch_mode = TextureRect.STRETCH_SCALE
	detail_panel.modulate = Color(1.0, 1.0, 1.0, 0.94)
	content.add_child(detail_panel)

	list_label = _label(list_panel, "", Vector2(34, 30), 24, Vector2(360, 510))
	title_label = _label(detail_panel, "No songs", Vector2(42, 38), 40, Vector2(620, 56))
	subtitle_label = _label(detail_panel, "", Vector2(42, 96), 23, Vector2(620, 36))
	detail_label = _label(detail_panel, "", Vector2(42, 156), 28, Vector2(620, 42))
	metadata_label = _label(detail_panel, "", Vector2(42, 214), 22, Vector2(620, 78))
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
	_update_selection()


func select_previous_song() -> void:
	if songs.is_empty():
		return
	selected_song_index = (selected_song_index - 1 + songs.size()) % songs.size()
	selected_course_index = 0
	_update_selection()


func select_next_course() -> void:
	var song := selected_song()
	if song == null or song.courses.is_empty():
		return
	selected_course_index = (selected_course_index + 1) % song.courses.size()
	_update_selection()


func select_previous_course() -> void:
	var song := selected_song()
	if song == null or song.courses.is_empty():
		return
	selected_course_index = (selected_course_index - 1 + song.courses.size()) % song.courses.size()
	_update_selection()


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


func _update_selection() -> void:
	build()
	if songs.is_empty():
		list_label.text = ""
		title_label.text = "No songs"
		subtitle_label.text = ""
		detail_label.text = ""
		metadata_label.text = ""
		_stop_preview()
		return

	var lines: Array[String] = []
	for i in range(songs.size()):
		var prefix := "> " if i == selected_song_index else "  "
		var marker := " [Missing audio]" if _song_has_missing_audio(songs[i]) else ""
		lines.append(prefix + songs[i].title + marker)
	list_label.text = "\n".join(lines)

	var song := selected_song()
	var course := selected_course()
	title_label.text = song.title
	subtitle_label.text = song.subtitle
	metadata_label.text = _metadata_text(song)
	if course == null:
		detail_label.text = "No courses"
		_stop_preview()
	elif course.audio_missing:
		detail_label.text = "%s  Level %d  Missing audio: %s" % [course.course, course.level, course.expected_audio_path]
		_stop_preview()
	else:
		detail_label.text = "%s  Level %d" % [course.course, course.level]
		_update_preview(song)


func _label(parent: Node, text: String, label_position: Vector2, font_size: int, label_size: Vector2) -> Label:
	var label := Label.new()
	label.text = text
	label.position = label_position
	label.size = label_size
	label.custom_minimum_size = label_size
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
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


func _make_ui_panel_texture(region: Rect2) -> Texture2D:
	var sheet := _load_png_texture(UI_PANEL_SHEET)
	if sheet == null:
		return null
	var texture := AtlasTexture.new()
	texture.atlas = sheet
	texture.region = region
	return texture


func _song_has_missing_audio(song: SongEntry) -> bool:
	for course in song.courses:
		if course.audio_missing:
			return true
	return false


func _metadata_text(song: SongEntry) -> String:
	var parts: Array[String] = []
	if song.genre != "":
		parts.append("Genre: %s" % song.genre)
	if song.maker != "":
		parts.append("Maker: %s" % song.maker)
	var course_parts: Array[String] = []
	for course in song.courses:
		course_parts.append("%s %d" % [course.course, course.level])
	if not course_parts.is_empty():
		parts.append("Courses: %s" % ", ".join(course_parts))
	return "  |  ".join(parts)


func _update_preview(song: SongEntry) -> void:
	if preview_player == null:
		return
	_stop_preview()
	if song.preview_audio_path == "" or not FileAccess.file_exists(song.preview_audio_path):
		return
	var stream := _load_audio_stream(song.preview_audio_path)
	if stream == null:
		return
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
