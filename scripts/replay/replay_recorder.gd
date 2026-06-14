extends RefCounted
class_name ReplayRecorder

const VERSION := 1

var version := VERSION
var chart_hash := ""
var course := ""
var offset_ms := 0
var input_offset_ms := 0
var inputs: Array[Dictionary] = []
var result: Dictionary = {}


static func load_from_file(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return null
	var script: GDScript = load("res://scripts/replay/replay_recorder.gd")
	var recorder: RefCounted = script.new()
	recorder.load_from_dictionary(parsed)
	return recorder


func start(new_chart_hash: String, new_course: String, new_offset_ms: int, new_input_offset_ms: int = 0) -> void:
	version = VERSION
	chart_hash = new_chart_hash
	course = new_course
	offset_ms = new_offset_ms
	input_offset_ms = new_input_offset_ms
	inputs.clear()
	result.clear()


func record_input(time_sec: float, lane: String) -> void:
	inputs.append({
		"time_sec": time_sec,
		"lane": lane,
	})


func set_result(new_result: Dictionary) -> void:
	result = new_result.duplicate(true)


func save(path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(to_dictionary(), "\t"))
	return true


func load_from_dictionary(data: Dictionary) -> void:
	version = int(data.get("version", VERSION))
	chart_hash = String(data.get("chart_hash", ""))
	course = String(data.get("course", ""))
	offset_ms = int(data.get("offset_ms", 0))
	input_offset_ms = int(data.get("input_offset_ms", 0))
	inputs.clear()
	for input in data.get("inputs", []):
		if input is Dictionary:
			inputs.append({
				"time_sec": float(input.get("time_sec", 0.0)),
				"lane": String(input.get("lane", "")),
			})
	result = Dictionary(data.get("result", {})).duplicate(true)


func to_dictionary() -> Dictionary:
	return {
		"version": version,
		"chart_hash": chart_hash,
		"course": course,
		"offset_ms": offset_ms,
		"input_offset_ms": input_offset_ms,
		"inputs": inputs.duplicate(true),
		"result": result.duplicate(true),
	}
