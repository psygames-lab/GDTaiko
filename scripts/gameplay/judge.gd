extends RefCounted
class_name Judge

const PERFECT_SEC := 0.045
const GOOD_SEC := 0.095
const BAD_SEC := 0.150


func judge(scheduled_time_sec: float, hit_time_sec: float) -> Dictionary:
	var timing_error_sec := hit_time_sec - scheduled_time_sec
	var abs_error := absf(timing_error_sec)
	var judgment := "miss"
	if abs_error <= PERFECT_SEC:
		judgment = "perfect"
	elif abs_error <= GOOD_SEC:
		judgment = "good"
	elif abs_error <= BAD_SEC:
		judgment = "bad"

	return {
		"judgment": judgment,
		"timing_error_sec": timing_error_sec,
		"timing_error_ms": timing_error_sec * 1000.0,
	}


func is_expired(scheduled_time_sec: float, song_time_sec: float) -> bool:
	return song_time_sec > scheduled_time_sec + BAD_SEC
