extends RefCounted
class_name ReplayPlayer

var inputs: Array[Dictionary] = []
var next_input_index := 0
var version := 0
var chart_hash := ""
var course := ""
var offset_ms := 0
var last_error := ""


func load_replay(data: Dictionary, expected_chart_hash: String = "", expected_course: String = "", expected_offset_ms: int = -2147483648) -> bool:
	version = int(data.get("version", 0))
	chart_hash = String(data.get("chart_hash", ""))
	course = String(data.get("course", ""))
	offset_ms = int(data.get("offset_ms", 0))
	last_error = ""

	if version != 1:
		last_error = "unsupported replay version"
		return false
	if expected_chart_hash != "" and chart_hash != expected_chart_hash:
		last_error = "replay chart mismatch"
		return false
	if expected_course != "" and course != expected_course:
		last_error = "replay course mismatch"
		return false
	if expected_offset_ms != -2147483648 and offset_ms != expected_offset_ms:
		last_error = "replay offset mismatch"
		return false

	inputs.clear()
	for input in data.get("inputs", []):
		if input is Dictionary:
			inputs.append({
				"time_sec": float(input.get("time_sec", 0.0)),
				"lane": String(input.get("lane", "")),
			})
	inputs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["time_sec"]) < float(b["time_sec"]))
	next_input_index = 0
	return true


func reset() -> void:
	next_input_index = 0


func update(controller: Variant, song_time_sec: float) -> void:
	while next_input_index < inputs.size() and float(inputs[next_input_index]["time_sec"]) <= song_time_sec:
		var lane := String(inputs[next_input_index]["lane"])
		if controller.has_method("apply_replay_input"):
			controller.apply_replay_input(lane)
		else:
			controller._hit(lane)
		next_input_index += 1
