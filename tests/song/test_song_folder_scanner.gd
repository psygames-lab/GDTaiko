extends SceneTree

const SongFolderScanner := preload("res://scripts/song/song_folder_scanner.gd")

var failed_count := 0


func _init() -> void:
	var root := "user://scan_test_phase31"
	_remove_dir_recursive(root)
	DirAccess.make_dir_recursive_absolute(root + "/sample")
	DirAccess.make_dir_recursive_absolute(root + "/alpha")
	DirAccess.make_dir_recursive_absolute(root + "/multi")
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
	var cover := FileAccess.open(root + "/sample/cover.png", FileAccess.WRITE)
	cover.store_buffer(FileAccess.get_file_as_bytes("res://assets/notes/note_don.png"))
	cover.close()
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
	var multi_chart := FileAccess.open(root + "/multi/multi.tja", FileAccess.WRITE)
	multi_chart.store_string("""TITLE:Multi Course Song
WAVE:multi.ogg
BPM:120
COURSE:Easy
LEVEL:2
#START
1000,
#END

COURSE:Hard
LEVEL:6
#START
1200,
#END
""")
	multi_chart.close()
	var multi_audio := FileAccess.open(root + "/multi/multi.ogg", FileAccess.WRITE)
	multi_audio.store_buffer(PackedByteArray())
	multi_audio.close()

	var songs := SongFolderScanner.scan(root)
	_assert(songs.size() == 3, "Scanner should return one song entry per child folder")
	if songs.size() == 3:
		_assert(songs[0].title == "Alpha Song", "Scanner should sort songs by title")
		_assert(songs[1].title == "Multi Course Song", "Scanner should include multi-course TJA folders")
		_assert(songs[1].courses.size() == 2, "Scanner should add one course per COURSE block")
		_assert(songs[1].courses[0].course == "Easy", "Scanner should preserve first embedded COURSE metadata")
		_assert(songs[1].courses[1].course == "Hard", "Scanner should preserve second embedded COURSE metadata")
		_assert(songs[1].courses[0].course_index == 0, "Scanner should record first embedded course index")
		_assert(songs[1].courses[1].course_index == 1, "Scanner should record second embedded course index")
		_assert(songs[1].courses[0].level == 2, "Scanner should preserve first embedded LEVEL metadata")
		_assert(songs[1].courses[1].level == 6, "Scanner should preserve second embedded LEVEL metadata")
		_assert(songs[1].courses[0].tja_path.ends_with("/multi/multi.tja"), "Embedded courses should share the same TJA path")
		_assert(songs[1].courses[1].wave.ends_with("/multi/multi.ogg"), "Embedded courses should share the resolved WAVE path")
		_assert(not songs[1].courses[1].audio_missing, "Scanner should mark shared embedded audio as available")
		_assert(songs[2].title == "Scanner Song", "Scanner should read TITLE metadata")
		_assert(songs[2].genre == "Pop", "Scanner should read GENRE metadata")
		_assert(songs[2].maker == "Fixture Maker", "Scanner should read MAKER metadata")
		_assert(is_equal_approx(songs[2].preview_start_sec, 1.5), "Scanner should read DEMOSTART metadata")
		_assert(songs[2].courses.size() == 2, "Scanner should add one course per TJA")
		_assert(songs[2].courses[0].course == "Oni", "Scanner should preserve COURSE metadata")
		_assert(songs[2].courses[1].course == "Hard", "Scanner should parse multiple TJA files deterministically")
		_assert(songs[2].courses[0].wave.ends_with("/sample/sample.ogg"), "Scanner should resolve WAVE relative to folder")
		_assert(songs[2].courses[1].wave.ends_with("/sample/hard.ogg"), "Scanner should resolve each course WAVE relative to folder")
		_assert(not songs[2].courses[0].audio_missing, "Scanner should mark existing audio as available")
		_assert(songs[2].courses[1].audio_missing, "Scanner should mark missing audio")
		_assert(songs[2].courses[1].expected_audio_path.ends_with("/sample/hard.ogg"), "Scanner should record expected missing audio path")
		_assert(songs[2].preview_audio_path.ends_with("/sample/sample.ogg"), "Scanner should use WAVE for preview audio")
		_assert(songs[2].cover_path.ends_with("/sample/cover.png"), "Scanner should detect a cover image in the song folder")

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
