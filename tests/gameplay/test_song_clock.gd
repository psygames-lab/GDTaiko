extends SceneTree

const SongClockScript: GDScript = preload("res://scripts/gameplay/song_clock.gd")

var failed_count := 0


func _init() -> void:
	_test_configure_advance_and_reset()
	_test_disables_audio_position_with_null_player()
	_test_multiple_advances_accumulate()

	if failed_count == 0:
		print("PASS: SongClock")
		quit(0)
	else:
		push_error("FAIL: SongClock tests failed with %d assertion(s)." % failed_count)
		quit(1)


func _new_clock() -> Node:
	var clock: Node = SongClockScript.new()
	var root: Node = get_root()
	if root != null:
		root.add_child(clock)
	return clock


func _test_configure_advance_and_reset() -> void:
	var clock: Node = _new_clock()
	clock.configure(null, 0.25)
	clock.advance(1.0)
	_assert(is_equal_approx(clock.time_sec(), 1.25), "configure(null, 0.25) plus 1 second advance should yield 1.25")

	clock.reset()
	_assert(is_equal_approx(clock.time_sec(), 0.25), "reset() should clear fallback time but preserve chart offset")


func _test_disables_audio_position_with_null_player() -> void:
	var clock: Node = _new_clock()
	clock.using_audio_position = false
	clock.configure(null, 0.10)
	clock.advance(1.15)
	_assert(is_equal_approx(clock.time_sec(), 1.25), "when using_audio_position is false and audio is null, fallback time should be used")


func _test_multiple_advances_accumulate() -> void:
	var clock: Node = _new_clock()
	clock.configure(null, 0.0)
	clock.advance(0.2)
	clock.advance(0.3)
	clock.advance(0.5)
	_assert(is_equal_approx(clock.time_sec(), 1.0), "multiple advance calls should accumulate fallback time")


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed_count += 1
		push_error("ASSERTION FAILED: " + message)
