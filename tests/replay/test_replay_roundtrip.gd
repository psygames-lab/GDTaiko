extends SceneTree

const ReplayRecorder := preload("res://scripts/replay/replay_recorder.gd")
const ReplayPlayer := preload("res://scripts/replay/replay_player.gd")
const GameplayScene: PackedScene = preload("res://scenes/Gameplay.tscn")
const NoteModel := preload("res://scripts/gameplay/note_model.gd")

var failed_count := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_recorder_save_load_roundtrip()
	_test_player_rejects_mismatched_context()
	_test_player_injects_inputs_by_time()
	_test_gameplay_controller_records_hits()
	_test_replay_input_does_not_record_again()

	if failed_count == 0:
		print("PASS: ReplayRoundtrip")
		quit(0)
	else:
		push_error("FAIL: ReplayRoundtrip tests failed with %d assertion(s)." % failed_count)
		quit(1)


func _test_recorder_save_load_roundtrip() -> void:
	var path := "user://replay_roundtrip_test.json"
	DirAccess.remove_absolute(path)

	var recorder := ReplayRecorder.new()
	recorder.start("chart-a", "Oni", -25)
	recorder.record_input(1.234, NoteModel.DON)
	recorder.record_input(2.5, NoteModel.KA)
	recorder.set_result({"score": 1200, "max_combo": 2})
	_assert(recorder.save(path), "Recorder should save replay")

	var loaded = ReplayRecorder.load_from_file(path)
	_assert(loaded != null, "Recorder should load saved replay")
	if loaded != null:
		_assert(loaded.chart_hash == "chart-a", "Loaded replay should preserve chart hash")
		_assert(loaded.course == "Oni", "Loaded replay should preserve course")
		_assert(loaded.offset_ms == -25, "Loaded replay should preserve offset")
		_assert(loaded.inputs.size() == 2, "Loaded replay should preserve input count")
		_assert(loaded.inputs[0]["lane"] == NoteModel.DON, "Loaded replay should preserve first lane")
		_assert(loaded.inputs[1]["lane"] == NoteModel.KA, "Loaded replay should preserve second lane")
		_assert(loaded.result["score"] == 1200, "Loaded replay should preserve result")

	DirAccess.remove_absolute(path)


func _test_player_injects_inputs_by_time() -> void:
	var recorder := ReplayRecorder.new()
	recorder.start("chart-a", "Oni", 0)
	recorder.record_input(1.0, NoteModel.DON)
	recorder.record_input(2.0, NoteModel.KA)

	var fake_controller := FakeController.new()
	var player := ReplayPlayer.new()
	_assert(player.load_replay(recorder.to_dictionary(), "chart-a", "Oni", 0), "Replay should load for matching context")
	player.update(fake_controller, 0.5)
	_assert(fake_controller.hits.is_empty(), "Replay should not inject future inputs")
	player.update(fake_controller, 1.0)
	_assert(fake_controller.hits == [NoteModel.DON], "Replay should inject due Don input")
	player.update(fake_controller, 2.5)
	_assert(fake_controller.hits == [NoteModel.DON, NoteModel.KA], "Replay should inject remaining inputs")


func _test_player_rejects_mismatched_context() -> void:
	var recorder := ReplayRecorder.new()
	recorder.start("chart-a", "Oni", 12)
	recorder.record_input(1.0, NoteModel.DON)

	var player := ReplayPlayer.new()
	_assert(not player.load_replay(recorder.to_dictionary(), "chart-b", "Oni", 12), "Replay should reject changed chart")
	_assert(player.last_error == "replay chart mismatch", "Replay should expose chart mismatch error")
	_assert(not player.load_replay(recorder.to_dictionary(), "chart-a", "Hard", 12), "Replay should reject wrong course")
	_assert(not player.load_replay(recorder.to_dictionary(), "chart-a", "Oni", 0), "Replay should reject wrong offset")


func _test_gameplay_controller_records_hits() -> void:
	var controller = GameplayScene.instantiate()
	get_root().add_child(controller)
	controller._start_song()
	controller._hit(NoteModel.DON)
	_assert(controller.replay_recorder != null, "Gameplay should create a replay recorder on start")
	_assert(controller.replay_recorder.inputs.size() == 1, "Gameplay should record player hit input")
	_assert(controller.replay_recorder.inputs[0]["lane"] == NoteModel.DON, "Gameplay should record hit lane")
	controller.free()


func _test_replay_input_does_not_record_again() -> void:
	var controller = GameplayScene.instantiate()
	get_root().add_child(controller)
	controller._start_song()
	controller.apply_replay_input(NoteModel.DON)
	_assert(controller.replay_recorder.inputs.is_empty(), "Replay-injected input should not be recorded again")
	controller.free()


class FakeController:
	var hits: Array[String] = []

	func _hit(lane: String) -> void:
		hits.append(lane)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed_count += 1
		push_error("ASSERTION FAILED: " + message)
