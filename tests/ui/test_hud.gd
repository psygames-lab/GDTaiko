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
	_assert(hud.gogo_label != null, "GOGO label should be created")
	_assert(hud.gogo_label.text == "", "GOGO label should default to empty")
	_assert(hud.get("top_band") != null, "HUD should create a top band")
	_assert(hud.get("bottom_band") != null, "HUD should create a bottom band for status text")
	_assert(hud.get("soul_gauge_fill") != null, "HUD should create a soul gauge fill")
	_assert(hud.top_band.size.y <= 92.0, "Top HUD band should stay compact")
	_assert(hud.score_label.position.x >= 760.0, "Score should live in the right HUD area")
	_assert(hud.combo_label.position.x >= 500.0, "Combo should live near the top center")
	_assert(hud.judgment_label.position.y >= 590.0, "Judgment should stay in the bottom-safe band")
	_assert(hud.status_label.position.y >= 630.0, "Status should stay below the control hint")

	hud.update_score(1234, 56)
	_assert(hud.score_label.text == "Score: 1234", "Score text should update")
	_assert(hud.combo_label.text == "Combo: 56", "Combo text should update")
	if hud.has_method("update_gauge"):
		hud.update_gauge(80.0)
	var gauge_fill = hud.get("soul_gauge_fill")
	_assert(gauge_fill != null and gauge_fill.size.x > 500.0, "Soul gauge fill should scale with gauge value")

	hud.show_judgment("Great", 12.7)
	_assert(hud.judgment_label.text == "Great  +13 ms", "Judgment should show capitalized name and ms")
	hud.show_judgment("")
	_assert(hud.judgment_label.text == "F = Don    J = Ka    Space = Start", "Empty judgment should reset controls text")

	hud.set_status("Playing")
	_assert(hud.status_label.text == "Playing", "Status text should update")
	hud.set_gogo(true)
	_assert(hud.gogo_label.text == "GOGO", "GOGO label should show active state")
	hud.set_gogo(false)
	_assert(hud.gogo_label.text == "", "GOGO label should clear inactive state")

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
