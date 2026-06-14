extends SceneTree

const TaikoTheme := preload("res://scripts/theme/taiko_theme.gd")

var failed_count := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_default_theme_loads_release_allowed_assets()
	_test_missing_required_key_fails()

	if failed_count == 0:
		print("PASS: TaikoTheme")
		quit(0)
	else:
		push_error("FAIL: TaikoTheme tests failed with %d assertion(s)." % failed_count)
		quit(1)


func _test_default_theme_loads_release_allowed_assets() -> void:
	var theme = TaikoTheme.load_from_file("res://themes/default/theme.json")
	_assert(theme.is_valid(), "default theme should be valid: %s" % ", ".join(theme.errors))
	_assert(theme.name == "Default", "default theme name should load")
	_assert(theme.note_don_path == "res://assets/notes/note_don.png", "Don note path should use audited original asset")
	_assert(theme.note_ka_path == "res://assets/notes/note_ka.png", "Ka note path should use audited original asset")
	_assert(theme.get_note_don_texture() != null, "Don texture should load")
	_assert(theme.get_note_ka_texture() != null, "Ka texture should load")
	_assert(theme.lane_color == Color.html("#1b1b1b"), "Lane color should parse")
	_assert(theme.gogo_color == Color.html("#f5a623"), "GOGO color should parse")
	_assert(theme.sfx_don_path == "", "No SFX should be configured before approved SFX exists")
	_assert(theme.font_main_path == "", "No font should be configured before approved font import")


func _test_missing_required_key_fails() -> void:
	var invalid_path := "user://invalid_theme.json"
	var file := FileAccess.open(invalid_path, FileAccess.WRITE)
	file.store_string('{"name":"Invalid","note_don":"res://assets/notes/note_don.png"}')
	file.close()

	var theme = TaikoTheme.load_from_file(invalid_path)
	_assert(not theme.is_valid(), "theme missing required keys should be invalid")
	_assert(theme.errors.has("missing required key note_ka"), "missing note_ka should be reported")
	_assert(theme.errors.has("missing required key lane_color"), "missing lane_color should be reported")
	DirAccess.remove_absolute(invalid_path)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed_count += 1
		push_error("ASSERTION FAILED: " + message)
