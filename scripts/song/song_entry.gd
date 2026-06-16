extends RefCounted
class_name SongEntry

const SongCourse := preload("res://scripts/song/song_course.gd")

var title: String = ""
var subtitle: String = ""
var genre: String = ""
var maker: String = ""
var folder_path: String = ""
var preview_audio_path: String = ""
var preview_start_sec: float = 0.0
var cover_path: String = ""
var courses: Array[SongCourse] = []


func best_course(course_name: String) -> SongCourse:
	for course in courses:
		if course.course.to_lower() == course_name.to_lower():
			return course
	return null
