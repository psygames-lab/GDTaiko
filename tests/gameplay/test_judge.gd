extends SceneTree

const JudgeScript: GDScript = preload("res://scripts/gameplay/judge.gd")

var failed_count := 0


func _init() -> void:
	_test_perfect_threshold()
	_test_good_threshold()
	_test_bad_threshold()
	_test_miss_threshold()
	_test_early_hit_symmetry()
	_test_timing_error_signs()
	_test_expired()

	if failed_count == 0:
		print("PASS: Judge")
		quit(0)
	else:
		push_error("FAIL: Judge tests failed with %d assertion(s)." % failed_count)
		quit(1)


func _test_perfect_threshold() -> void:
	var judge: RefCounted = JudgeScript.new()

	_assert(judge.judge(1.000, 1.020)["judgment"] == "perfect", "Late hit within perfect window should be perfect")
	_assert(judge.judge(1.000, 1.045)["judgment"] == "perfect", "Boundary at PERFECT_SEC should stay perfect")
	_assert(
		is_equal_approx(judge.judge(1.000, 1.045)["timing_error_sec"], 0.045),
		"Boundary at PERFECT_SEC should be perfect"
	)


func _test_good_threshold() -> void:
	var judge: RefCounted = JudgeScript.new()

	_assert(judge.judge(1.000, 1.080)["judgment"] == "good", "Late hit within good window should be good")
	_assert(judge.judge(1.000, 1.095)["judgment"] == "good", "Boundary at GOOD_SEC should stay good")
	_assert(
		is_equal_approx(judge.judge(1.000, 1.095)["timing_error_sec"], 0.095),
		"Boundary at GOOD_SEC should be good"
	)


func _test_bad_threshold() -> void:
	var judge: RefCounted = JudgeScript.new()

	_assert(judge.judge(1.000, 1.140)["judgment"] == "bad", "Late hit within bad window should be bad")
	_assert(judge.judge(1.000, 1.150)["judgment"] == "bad", "Boundary at BAD_SEC should stay bad")
	_assert(
		is_equal_approx(judge.judge(1.000, 1.150)["timing_error_sec"], 0.150),
		"Boundary at BAD_SEC should be bad"
	)


func _test_miss_threshold() -> void:
	var judge: RefCounted = JudgeScript.new()

	_assert(judge.judge(1.000, 1.220)["judgment"] == "miss", "Late hit outside bad window should be miss")


func _test_early_hit_symmetry() -> void:
	var judge: RefCounted = JudgeScript.new()

	var result: Dictionary = judge.judge(1.000, 0.960)
	_assert(result["judgment"] == "perfect", "Early hit within perfect window should be perfect")
	_assert(
		is_equal_approx(result["timing_error_sec"], -0.040),
		"Early timing_error_sec should keep negative sign"
	)
	_assert(
		is_equal_approx(result["timing_error_ms"], -40.0),
		"Early timing_error_ms should keep negative sign"
	)


func _test_timing_error_signs() -> void:
	var judge: RefCounted = JudgeScript.new()

	var late_result: Dictionary = judge.judge(1.000, 1.020)
	_assert(
		is_equal_approx(late_result["timing_error_sec"], 0.020),
		"Late timing_error_sec should be positive"
	)
	_assert(
		is_equal_approx(late_result["timing_error_ms"], 20.0),
		"Late timing_error_ms should be positive"
	)


func _test_expired() -> void:
	var judge: RefCounted = JudgeScript.new()

	_assert(judge.is_expired(1.000, 1.180), "Late miss beyond BAD_SEC should expire")
	_assert(not judge.is_expired(1.000, 1.100), "Within BAD_SEC should not expire")
	_assert(not judge.is_expired(1.000, 1.150), "Exact BAD_SEC should not expire")


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed_count += 1
		push_error("ASSERTION FAILED: " + message)
