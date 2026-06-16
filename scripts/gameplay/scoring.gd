extends RefCounted
class_name Scoring

var score := 0
var combo := 0
var max_combo := 0
var perfects := 0
var goods := 0
var bads := 0
var misses := 0
var roll_hits := 0
var balloons_cleared := 0
var gogo_active := false


func reset() -> void:
	score = 0
	combo = 0
	max_combo = 0
	perfects = 0
	goods = 0
	bads = 0
	misses = 0
	roll_hits = 0
	balloons_cleared = 0
	gogo_active = false


func apply_judgment(judgment: String, note_kind: String = "") -> void:
	match judgment:
		"perfect":
			perfects += 1
			combo += 1
			score += _apply_multiplier(1000 * _note_score_multiplier(note_kind))
		"good":
			goods += 1
			combo += 1
			score += _apply_multiplier(600 * _note_score_multiplier(note_kind))
		"bad":
			bads += 1
			combo = 0
			score += _apply_multiplier(100 * _note_score_multiplier(note_kind))
		"miss":
			misses += 1
			combo = 0
		_:
			return
	max_combo = max(max_combo, combo)


func apply_roll_hit() -> void:
	roll_hits += 1
	score += 100


func apply_balloon_clear() -> void:
	balloons_cleared += 1
	score += 5000


func set_gogo(active: bool) -> void:
	gogo_active = active


func _apply_multiplier(points: int) -> int:
	if gogo_active:
		return int(round(float(points) * 1.2))
	return points


func _note_score_multiplier(note_kind: String) -> int:
	if note_kind == "big_don" or note_kind == "big_ka":
		return 2
	return 1
