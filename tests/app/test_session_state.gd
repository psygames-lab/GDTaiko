extends SceneTree

const SessionState := preload("res://scripts/app/session_state.gd")

var failed_count := 0


func _init() -> void:
	var state := SessionState.new()
	_assert(state.selected_tja_path == "", "Selected TJA path should default empty")
	_assert(state.selected_audio_path == "", "Selected audio path should default empty")
	state.selected_tja_path = "res://songs/sample/sample.tja"
	state.selected_audio_path = "res://songs/sample/sample.ogg"
	state.clear_selection()
	_assert(state.selected_tja_path == "", "clear_selection should clear selected TJA path")
	_assert(state.selected_audio_path == "", "clear_selection should clear selected audio path")
	state.free()

	if failed_count == 0:
		print("PASS: SessionState")
		quit(0)
	else:
		push_error("FAIL: SessionState tests failed with %d assertion(s)." % failed_count)
		quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed_count += 1
		push_error("ASSERTION FAILED: " + message)
