extends RefCounted
class_name ReplayPlayer

var inputs: Array[Dictionary] = []
var next_input_index := 0


func load_replay(data: Dictionary) -> void:
	inputs.clear()
	for input in data.get("inputs", []):
		if input is Dictionary:
			inputs.append({
				"time_sec": float(input.get("time_sec", 0.0)),
				"lane": String(input.get("lane", "")),
			})
	inputs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["time_sec"]) < float(b["time_sec"]))
	next_input_index = 0


func reset() -> void:
	next_input_index = 0


func update(controller: Variant, song_time_sec: float) -> void:
	while next_input_index < inputs.size() and float(inputs[next_input_index]["time_sec"]) <= song_time_sec:
		controller._hit(String(inputs[next_input_index]["lane"]))
		next_input_index += 1
