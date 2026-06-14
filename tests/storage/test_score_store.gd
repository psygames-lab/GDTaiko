extends SceneTree

const ScoreStore := preload("res://scripts/storage/score_store.gd")

var failed_count := 0


func _init() -> void:
	var store := ScoreStore.new()
	store.path = "user://test_scores.json"
	DirAccess.remove_absolute(store.path)

	store.save_result("song_hash", "Oni", {"score": 1000, "max_combo": 5, "clear": true})
	var best := store.best_result("song_hash", "Oni")
	_assert(best["score"] == 1000, "best_result should return saved score")

	store.save_result("song_hash", "Oni", {"score": 900, "max_combo": 9, "clear": true})
	_assert(store.best_result("song_hash", "Oni")["score"] == 1000, "Lower score should not replace best")

	store.save_result("song_hash", "Oni", {"score": 1200, "max_combo": 4, "clear": false})
	_assert(store.best_result("song_hash", "Oni")["score"] == 1200, "Higher score should replace best")
	_assert(store.best_result("missing", "Oni").is_empty(), "Missing score should return empty dictionary")

	DirAccess.remove_absolute(store.path)
	if failed_count == 0:
		print("PASS: ScoreStore")
		quit(0)
	else:
		push_error("FAIL: ScoreStore tests failed with %d assertion(s)." % failed_count)
		quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed_count += 1
		push_error("ASSERTION FAILED: " + message)
