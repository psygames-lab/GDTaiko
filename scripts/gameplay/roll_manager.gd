extends RefCounted
class_name RollManager

var hits_by_note: Dictionary = {}


func is_roll(note: Dictionary) -> bool:
	return String(note.get("kind", "")).contains("roll")


func is_active(note: Dictionary, song_time_sec: float) -> bool:
	var start := float(note.get("time_sec", 0.0))
	var duration := float(note.get("duration_sec", 0.0))
	var end := start + duration
	return song_time_sec >= start and song_time_sec <= end


func register_hit(note: Dictionary) -> void:
	var id := String(note.get("id", ""))
	hits_by_note[id] = int(hits_by_note.get(id, 0)) + 1


func hit_count(note_id: String) -> int:
	return int(hits_by_note.get(note_id, 0))


func reset() -> void:
	hits_by_note.clear()
