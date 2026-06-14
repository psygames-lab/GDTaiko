extends SceneTree

const TaikoTheme := preload("res://scripts/theme/taiko_theme.gd")

var failed_count := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_default_theme_loads_release_allowed_assets()
	_test_user_skin_overrides_default_theme()
	_test_user_skin_loads_user_png_texture()
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
	_assert(theme.hud_top_band_color == Color.html("#141417"), "HUD top band color should parse")
	_assert(theme.gauge_fill_color == Color.html("#ff9f1c"), "Gauge fill color should parse")
	_assert(theme.result_panel_color == Color.html("#141417"), "Result panel color should parse")
	_assert(theme.sfx_don_path == "", "No SFX should be configured before approved SFX exists")
	_assert(theme.font_main_path == "", "No font should be configured before approved font import")


func _test_user_skin_overrides_default_theme() -> void:
	var skin_dir := "user://skins/default"
	DirAccess.make_dir_recursive_absolute(skin_dir)
	var skin_path := skin_dir + "/skin.json"
	var file := FileAccess.open(skin_path, FileAccess.WRITE)
	file.store_string('{"name":"Local Dev Skin","lane_color":"#123456","gogo_color":"#abcdef","hud_top_band_color":"#222222","gauge_fill_color":"#ffee00","result_panel_color":"#111111"}')
	file.close()

	var theme = TaikoTheme.load_active("res://themes/default/theme.json", skin_path)
	_assert(theme.is_valid(), "active theme should stay valid with partial user override: %s" % ", ".join(theme.errors))
	_assert(theme.name == "Local Dev Skin", "User skin should override name")
	_assert(theme.note_don_path == "res://assets/notes/note_don.png", "User skin should inherit missing Don texture")
	_assert(theme.lane_color == Color.html("#123456"), "User skin should override lane color")
	_assert(theme.gogo_color == Color.html("#abcdef"), "User skin should override GOGO color")
	_assert(theme.hud_top_band_color == Color.html("#222222"), "User skin should override HUD color")
	_assert(theme.gauge_fill_color == Color.html("#ffee00"), "User skin should override gauge color")
	_assert(theme.result_panel_color == Color.html("#111111"), "User skin should override result panel color")
	DirAccess.remove_absolute(skin_path)


func _test_user_skin_loads_user_png_texture() -> void:
	var skin_dir := "user://skins/default"
	DirAccess.make_dir_recursive_absolute(skin_dir)
	var texture_path := skin_dir + "/note_don.png"
	var image := Image.create(6, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.25, 0.5, 0.75, 1.0))
	var error := image.save_png(texture_path)
	_assert(error == OK, "test skin PNG should be written")

	var skin_path := skin_dir + "/skin.json"
	var file := FileAccess.open(skin_path, FileAccess.WRITE)
	file.store_string('{"note_don":"%s"}' % texture_path)
	file.close()

	var theme = TaikoTheme.load_active("res://themes/default/theme.json", skin_path)
	var texture: Texture2D = theme.get_note_don_texture()
	_assert(texture != null, "user skin PNG should load as a texture")
	_assert(texture != null and texture.get_width() == 6, "user skin PNG width should be preserved")
	_assert(texture != null and texture.get_height() == 4, "user skin PNG height should be preserved")
	DirAccess.remove_absolute(skin_path)
	DirAccess.remove_absolute(texture_path)


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
