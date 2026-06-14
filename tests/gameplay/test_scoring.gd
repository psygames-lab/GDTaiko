extends SceneTree

const ScoringScript: GDScript = preload("res://scripts/gameplay/scoring.gd")

var failed_count := 0


func _init() -> void:
	_test_judgment_progression()
	_test_reset()
	_test_unknown_judgment_noop()
	_test_roll_hit()
	_test_reset_clears_roll_hits()
	_test_balloon_clear()
	_test_reset_clears_balloon_count()

	if failed_count == 0:
		print("PASS: Scoring")
		quit(0)
	else:
		push_error("FAIL: Scoring tests failed with %d assertion(s)." % failed_count)
		quit(1)


func _test_judgment_progression() -> void:
	var scoring: RefCounted = ScoringScript.new()

	scoring.apply_judgment("perfect")
	scoring.apply_judgment("good")
	_assert(scoring.combo == 2, "Perfect then good should yield combo 2")
	_assert(scoring.max_combo == 2, "max_combo should track peak combo")
	_assert(scoring.score == 1600, "Perfect and good should yield score 1600")
	_assert(scoring.perfects == 1, "Perfect count should be 1")
	_assert(scoring.goods == 1, "Good count should be 1")

	scoring.apply_judgment("bad")
	_assert(scoring.combo == 0, "Bad should reset combo to 0")
	_assert(scoring.score == 1700, "Bad should add 100 points")
	_assert(scoring.bads == 1, "Bad count should be 1")
	_assert(scoring.max_combo == 2, "max_combo should remain 2 after bad")

	scoring.apply_judgment("miss")
	_assert(scoring.combo == 0, "Miss should keep combo at 0")
	_assert(scoring.score == 1700, "Miss should not change score")
	_assert(scoring.misses == 1, "Miss count should be 1")


func _test_reset() -> void:
	var scoring: RefCounted = ScoringScript.new()
	scoring.apply_judgment("perfect")
	scoring.apply_judgment("bad")
	scoring.apply_judgment("miss")
	scoring.reset()

	_assert(scoring.score == 0, "reset() should clear score")
	_assert(scoring.combo == 0, "reset() should clear combo")
	_assert(scoring.max_combo == 0, "reset() should clear max_combo")
	_assert(scoring.perfects == 0, "reset() should clear perfect count")
	_assert(scoring.goods == 0, "reset() should clear good count")
	_assert(scoring.bads == 0, "reset() should clear bad count")
	_assert(scoring.misses == 0, "reset() should clear miss count")


func _test_unknown_judgment_noop() -> void:
	var scoring: RefCounted = ScoringScript.new()
	scoring.apply_judgment("perfect")
	scoring.apply_judgment("super")
	_assert(scoring.score == 1000, "Unknown judgment should not change score")
	_assert(scoring.combo == 1, "Unknown judgment should not change combo")
	_assert(scoring.perfects == 1, "Unknown judgment should not change perfect count")
	_assert(scoring.goods == 0, "Unknown judgment should not change good count")
	_assert(scoring.bads == 0, "Unknown judgment should not change bad count")
	_assert(scoring.misses == 0, "Unknown judgment should not change miss count")

	scoring.combo = 3
	scoring.max_combo = 1
	scoring.apply_judgment("super")
	_assert(scoring.combo == 3, "Unknown judgment should not overwrite externally modified combo")
	_assert(scoring.max_combo == 1, "Unknown judgment should not update max_combo")


func _test_roll_hit() -> void:
	var scoring: RefCounted = ScoringScript.new()
	scoring.apply_roll_hit()
	_assert(scoring.roll_hits == 1, "apply_roll_hit() should increment roll_hits")
	_assert(scoring.score == 100, "apply_roll_hit() should award 100 points")
	_assert(scoring.combo == 0, "apply_roll_hit() should not change combo")


func _test_reset_clears_roll_hits() -> void:
	var scoring: RefCounted = ScoringScript.new()
	scoring.apply_roll_hit()
	scoring.apply_roll_hit()
	scoring.reset()
	_assert(scoring.roll_hits == 0, "reset() should clear roll_hits")


func _test_balloon_clear() -> void:
	var scoring: RefCounted = ScoringScript.new()
	if not scoring.has_method("apply_balloon_clear"):
		_assert(false, "Scoring should expose apply_balloon_clear()")
		return
	scoring.apply_balloon_clear()
	_assert(scoring.balloons_cleared == 1, "apply_balloon_clear() should increment balloons_cleared")
	_assert(scoring.score == 5000, "apply_balloon_clear() should award 5000 points")


func _test_reset_clears_balloon_count() -> void:
	var scoring: RefCounted = ScoringScript.new()
	if not scoring.has_method("apply_balloon_clear"):
		_assert(false, "Scoring should expose apply_balloon_clear() before reset test")
		return
	scoring.apply_balloon_clear()
	scoring.reset()
	_assert(scoring.balloons_cleared == 0, "reset() should clear balloons_cleared")


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed_count += 1
		push_error("ASSERTION FAILED: " + message)
