extends SceneTree

const TaikoTheme := preload("res://scripts/theme/taiko_theme.gd")

var failed_count := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_default_theme_loads_release_allowed_assets()
	_test_default_note_textures_have_face_detail()
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
	_assert(theme.lane_panel_color == Color.html("#101317"), "Lane panel color should parse")
	_assert(theme.lane_border_color == Color.html("#d1a45f"), "Lane border color should parse")
	_assert(theme.lane_text_strip_color == Color.html("#2f3034"), "Lane text strip color should parse")
	_assert(theme.drum_body_color == Color.html("#7b2622"), "Drum body color should parse")
	_assert(theme.drum_face_color == Color.html("#f3d6a3"), "Drum face color should parse")
	_assert(theme.hit_target_color == Color.html("#b9bec4"), "Hit target color should parse")
	_assert(theme.sfx_don_path == "res://assets/sfx/don.wav", "Don SFX path should use audited original asset")
	_assert(theme.sfx_ka_path == "res://assets/sfx/ka.wav", "Ka SFX path should use audited original asset")
	_assert(theme.font_main_path == "", "No font should be configured before approved font import")


func _test_default_note_textures_have_face_detail() -> void:
	_assert(_has_dark_face_detail("res://assets/notes/note_don.png"), "Default Don note should include dark face details")
	_assert(_has_dark_face_detail("res://assets/notes/note_ka.png"), "Default Ka note should include dark face details")
	_assert(_has_solid_note_interior("res://assets/notes/note_don.png"), "Default Don note should not have transparent holes inside the face")
	_assert(_has_solid_note_interior("res://assets/notes/note_ka.png"), "Default Ka note should not have transparent holes inside the face")


func _test_user_skin_overrides_default_theme() -> void:
	var skin_dir := "user://skins/default"
	DirAccess.make_dir_recursive_absolute(skin_dir)
	var skin_path := skin_dir + "/skin.json"
	var file := FileAccess.open(skin_path, FileAccess.WRITE)
	file.store_string('{"name":"Local Dev Skin","lane_color":"#123456","gogo_color":"#abcdef","hud_top_band_color":"#222222","gauge_fill_color":"#ffee00","result_panel_color":"#111111","lane_panel_color":"#010203","lane_border_color":"#040506","lane_text_strip_color":"#070809","drum_body_color":"#101112","drum_face_color":"#131415","hit_target_color":"#161718"}')
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
	_assert(theme.lane_panel_color == Color.html("#010203"), "User skin should override lane panel color")
	_assert(theme.lane_border_color == Color.html("#040506"), "User skin should override lane border color")
	_assert(theme.lane_text_strip_color == Color.html("#070809"), "User skin should override lane text strip color")
	_assert(theme.drum_body_color == Color.html("#101112"), "User skin should override drum body color")
	_assert(theme.drum_face_color == Color.html("#131415"), "User skin should override drum face color")
	_assert(theme.hit_target_color == Color.html("#161718"), "User skin should override hit target color")
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


func _has_dark_face_detail(path: String) -> bool:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		return false
	var samples := [
		image.get_pixel(50, 58),
		image.get_pixel(80, 58),
		image.get_pixel(64, 65),
	]
	for color in samples:
		var brightness: float = (color.r + color.g + color.b) / 3.0
		if color.a < 0.8 or brightness > 0.25:
			return false
	return true


func _has_solid_note_interior(path: String) -> bool:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		return false
	var center := Vector2(image.get_width() * 0.5, image.get_height() * 0.5)
	for x in range(image.get_width()):
		for y in range(image.get_height()):
			if center.distance_to(Vector2(x, y)) <= 38.0 and image.get_pixel(x, y).a < 0.98:
				return false
	return true
