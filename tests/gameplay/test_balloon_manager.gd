extends SceneTree

const BalloonManager := preload("res://scripts/gameplay/balloon_manager.gd")

var failed_count := 0


func _init() -> void:
	var manager := BalloonManager.new()
	var note := {"id": "balloon_1", "required_hits": 3}
	_assert(manager.is_balloon({"kind": "balloon_start"}), "balloon_start should be treated as balloon")
	_assert(manager.is_balloon({"kind": "special_balloon_start"}), "special_balloon_start should reuse balloon hit handling")
	_assert(manager.remaining(note) == 3, "balloon should start with required hit count remaining")
	_assert(manager.register_hit(note) == false, "first hit should not clear balloon")
	_assert(note["balloon_hits"] == 1, "balloon note should store hit count for visual inflation")
	_assert(manager.remaining(note) == 2, "first hit should decrement remaining count")
	_assert(manager.register_hit(note) == false, "second hit should not clear balloon")
	_assert(note["balloon_hits"] == 2, "balloon note should update visual hit count on each hit")
	_assert(manager.register_hit(note) == true, "third hit should clear balloon")
	_assert(note["balloon_hits"] == 3, "cleared balloon should store final hit count")
	_assert(manager.remaining(note) == 0, "cleared balloon should have zero remaining")
	_assert(manager.is_cleared("balloon_1"), "cleared balloon should be tracked by id")
	_assert(manager.register_hit(note) == false, "already-cleared balloon should not clear repeatedly")

	var idless_note := {"required_hits": 2}
	_assert(manager.register_hit(idless_note) == false, "id-less balloon hit should not mutate shared empty id state")
	_assert(manager.remaining(idless_note) == 2, "id-less balloon should keep independent required count")
	_assert(manager.is_cleared("") == false, "empty id should not be marked cleared")

	if failed_count == 0:
		print("PASS: BalloonManager")
		quit(0)
	else:
		push_error("FAIL: BalloonManager tests failed with %d assertion(s)." % failed_count)
		quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed_count += 1
		push_error("ASSERTION FAILED: " + message)
