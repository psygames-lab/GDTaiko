extends SceneTree

const ResultScreen := preload("res://scripts/ui/result_screen.gd")
const ScoreStore := preload("res://scripts/storage/score_store.gd")

var failed_count := 0


func _init() -> void:
	var screen := ResultScreen.new()
	screen.build()
	_assert(not screen.visible, "Result screen should start hidden")

	screen.show_result({
		"score": 1234,
		"max_combo": 56,
		"perfects": 7,
		"goods": 8,
		"bads": 1,
		"misses": 2,
		"gauge": 80.0,
		"clear": true,
	})
	_assert(screen.visible, "Result screen should show after result payload")
	_assert(screen.score_label.text == "Score: 1234", "Score label should show payload score")
	_assert(screen.combo_label.text == "Max Combo: 56", "Combo label should show payload max combo")
	_assert(screen.counts_label.text == "Perfect 7  Good 8  Bad 1  Miss 2", "Counts label should show judgment totals")
	_assert(screen.gauge_label.text == "Gauge: 80.0%", "Gauge label should show payload gauge")
	_assert(screen.clear_label.text == "Clear", "Clear label should show clear result")

	var store := ScoreStore.new()
	store.path = "user://test_result_screen_scores.json"
	DirAccess.remove_absolute(store.path)
	screen.score_store = store
	screen.show_result({
		"song_key": "song_hash",
		"course": "Oni",
		"score": 2000,
		"max_combo": 10,
		"clear": true,
	})
	screen.show_result({
		"song_key": "song_hash",
		"course": "Oni",
		"score": 1000,
		"max_combo": 20,
		"clear": true,
	})
	_assert(store.best_result("song_hash", "Oni")["score"] == 2000, "Result screen should persist only best score")
	DirAccess.remove_absolute(store.path)

	screen.hide_result()
	_assert(not screen.visible, "Result screen should hide on request")
	screen.free()

	if failed_count == 0:
		print("PASS: ResultScreen")
		quit(0)
	else:
		push_error("FAIL: ResultScreen tests failed with %d assertion(s)." % failed_count)
		quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed_count += 1
		push_error("ASSERTION FAILED: " + message)
