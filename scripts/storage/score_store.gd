extends RefCounted
class_name ScoreStore

var path := "user://scores.json"


func save_result(song_key: String, course: String, result: Dictionary) -> void:
	var data := _load_data()
	if not data.has(song_key):
		data[song_key] = {}
	var song_scores: Dictionary = data[song_key]
	var current: Dictionary = song_scores.get(course, {})
	if current.is_empty() or int(result.get("score", 0)) > int(current.get("score", 0)):
		var stored := result.duplicate()
		if not stored.has("played_at"):
			stored["played_at"] = Time.get_datetime_string_from_system(false, true)
		song_scores[course] = stored
		data[song_key] = song_scores
		_save_data(data)


func best_result(song_key: String, course: String) -> Dictionary:
	var data := _load_data()
	if not data.has(song_key):
		return {}
	var song_scores: Dictionary = data[song_key]
	return song_scores.get(course, {}).duplicate()


func _load_data() -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	return {}


func _save_data(data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
