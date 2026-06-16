extends RefCounted
class_name BalloonManager

var hits_by_note: Dictionary = {}
var cleared: Dictionary = {}


func is_balloon(note: Dictionary) -> bool:
	var kind := String(note.get("kind", ""))
	return kind == "balloon_start" or kind == "special_balloon_start"


func register_hit(note: Dictionary) -> bool:
	var id := String(note.get("id", ""))
	if id == "" or is_cleared(id):
		return false
	var next_hits := int(hits_by_note.get(id, 0)) + 1
	hits_by_note[id] = next_hits
	note["balloon_hits"] = next_hits
	var complete := next_hits >= int(note.get("required_hits", 1))
	if complete:
		cleared[id] = true
	return complete


func remaining(note: Dictionary) -> int:
	var id := String(note.get("id", ""))
	if id == "":
		return max(0, int(note.get("required_hits", 1)))
	return max(0, int(note.get("required_hits", 1)) - int(hits_by_note.get(id, 0)))


func is_cleared(note_id: String) -> bool:
	return bool(cleared.get(note_id, false))


func reset() -> void:
	hits_by_note.clear()
	cleared.clear()
