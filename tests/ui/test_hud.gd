extends SceneTree

const HUD_SCRIPT := preload("res://scripts/ui/hud.gd")

var failed_count := 0


func _init() -> void:
	var hud := HUD_SCRIPT.new() as CanvasLayer
	hud.build()

	_assert(hud.score_label != null, "Score label should be created")
	_assert(hud.score_label.text == "Score: 0", "Default score text should be Score: 0")
	_assert(hud.combo_label != null, "Combo label should be created")
	_assert(hud.combo_label.text == "Combo: 0", "Default combo text should be Combo: 0")
	_assert(hud.judgment_label != null, "Judgment label should be created")
	_assert(hud.judgment_label.text == "F = Don    J = Ka    Space = Start", "Default judgment text should be controls")
	_assert(hud.status_label != null, "Status label should be created")
	_assert(hud.status_label.text == "Ready", "Default status text should be Ready")

	hud.update_score(1234, 56)
	_assert(hud.score_label.text == "Score: 1234", "Score text should update")
	_assert(hud.combo_label.text == "Combo: 56", "Combo text should update")

	hud.show_judgment("Great", 12.7)
	_assert(hud.judgment_label.text == "Great  +13 ms", "Judgment should show capitalized name and ms")
	hud.show_judgment("")
	_assert(hud.judgment_label.text == "F = Don    J = Ka    Space = Start", "Empty judgment should reset controls text")

	hud.set_status("Playing")
	_assert(hud.status_label.text == "Playing", "Status text should update")

	hud.free()

	if failed_count == 0:
		print("PASS: Hud")
		quit(0)
	else:
		push_error("FAIL: Hud tests failed with %d assertion(s)." % failed_count)
		quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed_count += 1
		push_error("ASSERTION FAILED: " + message)
