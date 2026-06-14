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


func reset() -> void:
	score = 0
	combo = 0
	max_combo = 0
	perfects = 0
	goods = 0
	bads = 0
	misses = 0
	roll_hits = 0


func apply_judgment(judgment: String) -> void:
	match judgment:
		"perfect":
			perfects += 1
			combo += 1
			score += 1000
		"good":
			goods += 1
			combo += 1
			score += 600
		"bad":
			bads += 1
			combo = 0
			score += 100
		"miss":
			misses += 1
			combo = 0
		_:
			return
	max_combo = max(max_combo, combo)


func apply_roll_hit() -> void:
	roll_hits += 1
	score += 100
