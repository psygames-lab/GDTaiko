extends SceneTree

const RollManager := preload("res://scripts/gameplay/roll_manager.gd")

var failed_count := 0


func _init() -> void:
	var manager := RollManager.new()
	var note := {
		"id": "roll_1",
		"time_sec": 1.0,
		"duration_sec": 2.0,
		"kind": "roll_start",
	}

	_assert(manager.is_active(note, 0.99) == false, "roll should be inactive before start")
	_assert(manager.is_active(note, 1.00) == true, "roll should be active at start time")
	_assert(manager.is_active(note, 2.50) == true, "roll should be active during duration")
	_assert(manager.is_active(note, 3.01) == false, "roll should be inactive after duration")

	manager.register_hit(note)
	manager.register_hit(note)
	_assert(manager.hit_count("roll_1") == 2, "register_hit should count per note id")

	if failed_count == 0:
		print("PASS: RollManager")
		quit(0)
	else:
		push_error("FAIL: RollManager tests failed with %d assertion(s)." % failed_count)
		quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed_count += 1
		push_error("ASSERTION FAILED: " + message)
