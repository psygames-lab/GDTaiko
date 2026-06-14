extends SceneTree

const TimingMap := preload("res://scripts/chart/timing_map.gd")

var failed_count := 0


func _init() -> void:
	var map := TimingMap.new()
	map.add_event(0.0, "scroll", 1.0)
	map.add_event(2.0, "scroll", 2.0)
	_assert(is_equal_approx(map.scroll_at(1.0), 1.0), "scroll before change should be 1.0")
	_assert(is_equal_approx(map.scroll_at(2.5), 2.0), "scroll after change should be 2.0")

	map.add_event(0.0, "bpm", 120.0)
	map.add_event(4.0, "bpm", 180.0)
	_assert(is_equal_approx(map.bpm_at(3.0), 120.0), "bpm before change should be 120")
	_assert(is_equal_approx(map.bpm_at(4.0), 180.0), "bpm at change should be 180")

	if failed_count == 0:
		print("PASS: TimingMap")
		quit(0)
	else:
		push_error("FAIL: TimingMap tests failed with %d assertion(s)." % failed_count)
		quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed_count += 1
		push_error("ASSERTION FAILED: " + message)
