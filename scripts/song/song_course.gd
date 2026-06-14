extends RefCounted
class_name SongCourse

var course: String = ""
var level: int = 0
var tja_path: String = ""
var wave: String = ""
var audio_missing: bool = false
var expected_audio_path: String = ""


func can_launch() -> bool:
	return not audio_missing
