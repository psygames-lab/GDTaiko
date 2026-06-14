extends RefCounted
class_name TimingMap

var events: Array[Dictionary] = []


func add_event(time_sec: float, event_type: String, value: Variant) -> void:
	events.append({
		"time_sec": time_sec,
		"type": event_type,
		"value": value,
	})
	events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["time_sec"]) < float(b["time_sec"]))


func value_at(event_type: String, song_time_sec: float, default_value: Variant) -> Variant:
	var current: Variant = default_value
	for event in events:
		if float(event["time_sec"]) > song_time_sec:
			break
		if String(event["type"]) == event_type:
			current = event["value"]
	return current


func bpm_at(song_time_sec: float) -> float:
	return float(value_at("bpm", song_time_sec, 120.0))


func scroll_at(song_time_sec: float) -> float:
	return float(value_at("scroll", song_time_sec, 1.0))
