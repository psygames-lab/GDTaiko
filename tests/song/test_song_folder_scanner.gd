extends SceneTree

const SongFolderScanner := preload("res://scripts/song/song_folder_scanner.gd")

var failed_count := 0


func _init() -> void:
	var root := "user://scan_test_phase31"
	_remove_dir_recursive(root)
	DirAccess.make_dir_recursive_absolute(root + "/sample")
	DirAccess.make_dir_recursive_absolute(root + "/alpha")
	var chart := FileAccess.open(root + "/sample/sample.tja", FileAccess.WRITE)
	chart.store_string("""TITLE:Scanner Song
SUBTITLE:Fixture
WAVE:sample.ogg
DEMOSTART:1.5
GENRE:Pop
MAKER:Fixture Maker
COURSE:Oni
LEVEL:7
BPM:120
#START
1000,
#END
""")
	chart.close()
	var hard_chart := FileAccess.open(root + "/sample/z_hard.tja", FileAccess.WRITE)
	hard_chart.store_string("""TITLE:Scanner Song
WAVE:hard.ogg
COURSE:Hard
LEVEL:5
BPM:120
#START
1000,
#END
""")
	hard_chart.close()
	var audio := FileAccess.open(root + "/sample/sample.ogg", FileAccess.WRITE)
	audio.store_buffer(PackedByteArray())
	audio.close()
	var alpha_chart := FileAccess.open(root + "/alpha/alpha.tja", FileAccess.WRITE)
	alpha_chart.store_string("""TITLE:Alpha Song
WAVE:alpha.ogg
COURSE:Normal
LEVEL:3
BPM:120
#START
1000,
#END
""")
	alpha_chart.close()

	var songs := SongFolderScanner.scan(root)
	_assert(songs.size() == 2, "Scanner should return one song entry per child folder")
	if songs.size() == 2:
		_assert(songs[0].title == "Alpha Song", "Scanner should sort songs by title")
		_assert(songs[1].title == "Scanner Song", "Scanner should read TITLE metadata")
		_assert(songs[1].genre == "Pop", "Scanner should read GENRE metadata")
		_assert(songs[1].maker == "Fixture Maker", "Scanner should read MAKER metadata")
		_assert(is_equal_approx(songs[1].preview_start_sec, 1.5), "Scanner should read DEMOSTART metadata")
		_assert(songs[1].courses.size() == 2, "Scanner should add one course per TJA")
		_assert(songs[1].courses[0].course == "Oni", "Scanner should preserve COURSE metadata")
		_assert(songs[1].courses[1].course == "Hard", "Scanner should parse multiple courses deterministically")
		_assert(songs[1].courses[0].wave.ends_with("/sample/sample.ogg"), "Scanner should resolve WAVE relative to folder")
		_assert(songs[1].courses[1].wave.ends_with("/sample/hard.ogg"), "Scanner should resolve each course WAVE relative to folder")
		_assert(not songs[1].courses[0].audio_missing, "Scanner should mark existing audio as available")
		_assert(songs[1].courses[1].audio_missing, "Scanner should mark missing audio")
		_assert(songs[1].courses[1].expected_audio_path.ends_with("/sample/hard.ogg"), "Scanner should record expected missing audio path")
		_assert(songs[1].preview_audio_path.ends_with("/sample/sample.ogg"), "Scanner should use WAVE for preview audio")

	_remove_dir_recursive(root)

	if failed_count == 0:
		print("PASS: SongFolderScanner")
		quit(0)
	else:
		push_error("FAIL: SongFolderScanner tests failed with %d assertion(s)." % failed_count)
		quit(1)


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
