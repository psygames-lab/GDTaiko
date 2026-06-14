extends RefCounted
class_name TaikoChart

var title: String = ""
var subtitle: String = ""
var wave: String = ""
var bpm: float = 120.0
var offset_sec: float = 0.0
var course: String = "Oni"
var level: int = 1
var balloon_counts: Array[int] = []
var metadata: Dictionary = {}
var notes: Array[Dictionary] = []
var branch_events: Array[Dictionary] = []
var timing_events: Array[Dictionary] = []
var warnings: Array[String] = []

var _next_note_index: int = 1


func add_note(
	time_sec: float,
	lane: String,
	kind: String,
	measure_index: int,
	subdivision_index: int,
	extra: Dictionary = {}
) -> void:
	var note_id := "note_%04d" % _next_note_index
	_next_note_index += 1
	var note := {
		"id": note_id,
		"time_sec": time_sec,
		"lane": lane,
		"kind": kind,
		"measure_index": measure_index,
		"subdivision_index": subdivision_index,
		"state": "pending",
	}
	for key in extra:
		note[key] = extra[key]
	notes.append(note)


func add_timing_event(time_sec: float, event_type: String, value: Variant) -> void:
	timing_events.append({
		"time_sec": time_sec,
		"type": event_type,
		"value": value
	})


func sort_notes() -> void:
	notes.sort_custom(_compare_notes)


func _compare_notes(a: Dictionary, b: Dictionary) -> bool:
	if a["time_sec"] < b["time_sec"]:
		return true
	if a["time_sec"] > b["time_sec"]:
		return false
	if a["measure_index"] < b["measure_index"]:
		return true
	if a["measure_index"] > b["measure_index"]:
		return false
	return a["subdivision_index"] < b["subdivision_index"]
