extends SceneTree

const SongSelect := preload("res://scripts/ui/song_select.gd")
const SessionStateScript := preload("res://scripts/app/session_state.gd")
const SongEntry := preload("res://scripts/song/song_entry.gd")
const SongCourse := preload("res://scripts/song/song_course.gd")

var failed_count := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var packed_scene := preload("res://scenes/SongSelect.tscn") as PackedScene
	var scene := packed_scene.instantiate()
	_assert(scene is SongSelect, "SongSelect scene root should use song_select.gd")
	scene.free()

	var select := SongSelect.new()
	select.build()
	get_root().add_child(select)
	select.songs = [
		_song("Alpha", "res://songs/alpha", "Oni", 7, "alpha_oni.tja", "alpha.ogg"),
		_song("Beta", "res://songs/beta", "Normal", 3, "beta_normal.tja", "beta.ogg"),
	]
	select._update_selection()

	_assert(select.title_label.text == "Alpha", "Song select should show selected title")
	_assert(select.detail_label.text.contains("Oni"), "Song select should show selected course")
	select.select_next_song()
	_assert(select.title_label.text == "Beta", "Down navigation should select next song")
	select.select_previous_song()
	_assert(select.title_label.text == "Alpha", "Up navigation should select previous song")
	var course := SongCourse.new()
	course.course = "Hard"
	course.level = 5
	course.tja_path = "res://songs/alpha/alpha_hard.tja"
	course.wave = "res://songs/alpha/hard.ogg"
	select.songs[0].courses.append(course)
	select.select_next_course()
	_assert(select.selected_course_index == 1, "Right navigation should select next course")
	_assert(select.selected_course().course == "Hard", "Selected course should update")
	var state = get_root().get_node_or_null("SessionState")
	if state == null:
		state = SessionStateScript.new()
		state.name = "SessionState"
		get_root().add_child(state)
	if state != null:
		state.clear_selection()
		_assert(select.apply_selected_course_to_session(), "Song select should write selected course to session")
		_assert(state.selected_tja_path == "res://songs/alpha/alpha_hard.tja", "Launch payload should include selected TJA path")
		_assert(state.selected_audio_path == "res://songs/alpha/hard.ogg", "Launch payload should include selected audio path")
		state.clear_selection()
		if state.get_parent() == get_root():
			state.free()

	select.load_songs("res://songs")
	_assert(select.songs.size() >= 1, "Song select should scan bundled songs folder")
	_assert(select.title_label.text == "GDTaiko Sample", "Song select should show sample song from res://songs")

	var user_root := "user://song_select_import_test"
	_remove_dir_recursive(user_root)
	DirAccess.make_dir_recursive_absolute(user_root + "/local")
	var user_chart := FileAccess.open(user_root + "/local/local.tja", FileAccess.WRITE)
	user_chart.store_string("""TITLE:Local Import
WAVE:local.ogg
COURSE:Oni
LEVEL:4
BPM:120
#START
1000,
#END
""")
	user_chart.close()
	var user_audio := FileAccess.open(user_root + "/local/local.ogg", FileAccess.WRITE)
	user_audio.store_buffer(PackedByteArray())
	user_audio.close()

	select.load_song_roots(["res://songs", user_root])
	_assert(_has_song(select.songs, "GDTaiko Sample"), "Song select should include bundled songs")
	_assert(_has_song(select.songs, "Local Import"), "Song select should include user-local songs")

	var missing_root := "user://song_select_missing_audio_test"
	_remove_dir_recursive(missing_root)
	DirAccess.make_dir_recursive_absolute(missing_root + "/missing")
	var missing_chart := FileAccess.open(missing_root + "/missing/missing.tja", FileAccess.WRITE)
	missing_chart.store_string("""TITLE:Missing Audio
WAVE:missing.ogg
COURSE:Oni
LEVEL:5
BPM:120
#START
1000,
#END
""")
	missing_chart.close()

	select.load_songs(missing_root)
	_assert(select.songs.size() == 1, "Song select should show charts even when audio is missing")
	_assert(select.detail_label.text.contains("Missing audio"), "Song select should mark missing audio")
	_assert(select.detail_label.text.contains("missing.ogg"), "Song select should show expected missing audio path")
	_assert(not select.apply_selected_course_to_session(), "Song select should prevent launching missing audio")
	_remove_dir_recursive(user_root)
	_remove_dir_recursive(missing_root)

	select.free()
	if failed_count == 0:
		print("PASS: SongSelect")
		quit(0)
	else:
		push_error("FAIL: SongSelect tests failed with %d assertion(s)." % failed_count)
		quit(1)


func _song(title: String, folder_path: String, course_name: String, level: int, tja_name: String, wave_name: String) -> SongEntry:
	var song := SongEntry.new()
	song.title = title
	song.folder_path = folder_path
	var course := SongCourse.new()
	course.course = course_name
	course.level = level
	course.tja_path = folder_path.path_join(tja_name)
	course.wave = folder_path.path_join(wave_name)
	song.courses.append(course)
	return song


func _has_song(song_list: Array[SongEntry], title: String) -> bool:
	for song in song_list:
		if song.title == title:
			return true
	return false


func _remove_dir_recursive(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var child := path + "/" + name
		if dir.current_is_dir():
			_remove_dir_recursive(child)
		else:
			DirAccess.remove_absolute(child)
		name = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(path)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed_count += 1
		push_error("ASSERTION FAILED: " + message)
