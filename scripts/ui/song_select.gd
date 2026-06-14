extends Control
class_name SongSelect

const SongFolderScanner := preload("res://scripts/song/song_folder_scanner.gd")
const SongEntry := preload("res://scripts/song/song_entry.gd")
const SongCourse := preload("res://scripts/song/song_course.gd")

var songs: Array[SongEntry] = []
var selected_song_index := 0
var selected_course_index := 0
var title_label: Label
var subtitle_label: Label
var detail_label: Label
var list_label: Label


func _ready() -> void:
	build()
	load_song_roots(["res://songs", "user://songs"])


func build() -> void:
	if title_label != null:
		return
	list_label = _label("", Vector2(80, 96), 24)
	title_label = _label("No songs", Vector2(520, 160), 42)
	subtitle_label = _label("", Vector2(520, 216), 24)
	detail_label = _label("", Vector2(520, 270), 28)


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


func _update_selection() -> void:
	build()
	if songs.is_empty():
		list_label.text = ""
		title_label.text = "No songs"
		subtitle_label.text = ""
		detail_label.text = ""
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
	if course == null:
		detail_label.text = "No courses"
	elif course.audio_missing:
		detail_label.text = "%s  Level %d  Missing audio: %s" % [course.course, course.level, course.expected_audio_path]
	else:
		detail_label.text = "%s  Level %d" % [course.course, course.level]


func _label(text: String, label_position: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = label_position
	label.add_theme_font_size_override("font_size", font_size)
	add_child(label)
	return label


func _song_has_missing_audio(song: SongEntry) -> bool:
	for course in song.courses:
		if course.audio_missing:
			return true
	return false
