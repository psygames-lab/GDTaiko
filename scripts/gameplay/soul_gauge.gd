extends RefCounted
class_name SoulGauge

var value := 0.0
var clear_threshold := 80.0


func reset() -> void:
	value = 0.0


func apply_judgment(judgment: String) -> void:
	match judgment:
		"perfect":
			value += 2.0
		"good":
			value += 1.2
		"bad":
			value -= 1.5
		"miss":
			value -= 3.0
	value = clamp(value, 0.0, 100.0)


func is_clear() -> bool:
	return value >= clear_threshold
