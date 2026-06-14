extends SceneTree

const SongEntryScript: GDScript = preload("res://scripts/song/song_entry.gd")
const SongCourseScript: GDScript = preload("res://scripts/song/song_course.gd")

var failed_count := 0


func _init() -> void:
	var song: RefCounted = SongEntryScript.new()
	var course: RefCounted = SongCourseScript.new()
	course.course = "Oni"
	course.level = 7
	course.tja_path = "res://tests/song/oni.tja"
	song.courses.append(course)

	var oni_course = song.best_course("Oni")
	_assert(oni_course != null, "Best course lookup should return a SongCourse for Oni")
	if oni_course != null:
		_assert(oni_course.level == 7, "Best course lookup should return Oni course with level 7")

	if failed_count == 0:
		print("PASS: SongEntry")
		quit(0)
	else:
		push_error("FAIL: SongEntry tests failed with %d assertion(s)." % failed_count)
		quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed_count += 1
		push_error("ASSERTION FAILED: " + message)
