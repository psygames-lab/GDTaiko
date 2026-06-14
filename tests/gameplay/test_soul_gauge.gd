extends SceneTree

const SoulGauge := preload("res://scripts/gameplay/soul_gauge.gd")

var failed_count := 0


func _init() -> void:
	var gauge := SoulGauge.new()
	gauge.apply_judgment("perfect")
	gauge.apply_judgment("good")
	_assert(gauge.value > 0.0, "Perfect and good judgments should raise the gauge")
	gauge.apply_judgment("miss")
	_assert(gauge.value < 4.0, "Miss judgment should reduce the gauge")
	gauge.value = 80.0
	_assert(gauge.is_clear(), "Gauge at clear threshold should clear")
	gauge.value = 79.9
	_assert(not gauge.is_clear(), "Gauge below clear threshold should not clear")

	if failed_count == 0:
		print("PASS: SoulGauge")
		quit(0)
	else:
		push_error("FAIL: SoulGauge tests failed with %d assertion(s)." % failed_count)
		quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed_count += 1
		push_error("ASSERTION FAILED: " + message)
