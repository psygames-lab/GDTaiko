extends RefCounted
class_name TaikoTheme

const REQUIRED_KEYS := [
	"name",
	"note_don",
	"note_ka",
	"lane_color",
	"gogo_color",
]

var name := ""
var note_don_path := ""
var note_ka_path := ""
var sfx_don_path := ""
var sfx_ka_path := ""
var font_main_path := ""
var lane_color := Color.BLACK
var gogo_color := Color.ORANGE
var hud_top_band_color := Color.html("#141417")
var gauge_fill_color := Color.html("#ff9f1c")
var result_panel_color := Color.html("#141417")
var lane_panel_color := Color.html("#101317")
var lane_border_color := Color.html("#d1a45f")
var lane_text_strip_color := Color.html("#2f3034")
var drum_body_color := Color.html("#3f444a")
var drum_face_color := Color.html("#f3d6a3")
var hit_target_color := Color.html("#b9bec4")
var errors: Array[String] = []


static func load_from_file(path: String) -> Variant:
	var script: GDScript = load("res://scripts/theme/taiko_theme.gd")
	var theme = script.new()
	theme._load_from_file(path, true)
	return theme


static func load_active(default_path: String = "res://themes/default/theme.json", user_path: String = "user://skins/default/skin.json") -> Variant:
	var theme = load_from_file(default_path)
	if FileAccess.file_exists(user_path):
		theme._load_from_file(user_path, false)
	return theme


func is_valid() -> bool:
	return errors.is_empty()


func get_note_don_texture() -> Texture2D:
	return _load_texture(note_don_path)


func get_note_ka_texture() -> Texture2D:
	return _load_texture(note_ka_path)


func _load_from_file(path: String, require_required_keys: bool) -> void:
	if not FileAccess.file_exists(path):
		errors.append("theme file not found %s" % path)
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("theme file not readable %s" % path)
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		errors.append("theme json must be an object")
		return

	if require_required_keys:
		for key in REQUIRED_KEYS:
			if not parsed.has(key) or String(parsed[key]) == "":
				errors.append("missing required key %s" % key)

	if parsed.has("name"):
		name = String(parsed["name"])
	if parsed.has("note_don"):
		note_don_path = String(parsed["note_don"])
	if parsed.has("note_ka"):
		note_ka_path = String(parsed["note_ka"])
	if parsed.has("sfx_don"):
		sfx_don_path = String(parsed["sfx_don"])
	if parsed.has("sfx_ka"):
		sfx_ka_path = String(parsed["sfx_ka"])
	if parsed.has("font_main"):
		font_main_path = String(parsed["font_main"])
	if parsed.has("lane_color"):
		lane_color = _parse_color(String(parsed["lane_color"]), "lane_color")
	if parsed.has("gogo_color"):
		gogo_color = _parse_color(String(parsed["gogo_color"]), "gogo_color")
	if parsed.has("hud_top_band_color"):
		hud_top_band_color = _parse_color(String(parsed["hud_top_band_color"]), "hud_top_band_color")
	if parsed.has("gauge_fill_color"):
		gauge_fill_color = _parse_color(String(parsed["gauge_fill_color"]), "gauge_fill_color")
	if parsed.has("result_panel_color"):
		result_panel_color = _parse_color(String(parsed["result_panel_color"]), "result_panel_color")
	if parsed.has("lane_panel_color"):
		lane_panel_color = _parse_color(String(parsed["lane_panel_color"]), "lane_panel_color")
	if parsed.has("lane_border_color"):
		lane_border_color = _parse_color(String(parsed["lane_border_color"]), "lane_border_color")
	if parsed.has("lane_text_strip_color"):
		lane_text_strip_color = _parse_color(String(parsed["lane_text_strip_color"]), "lane_text_strip_color")
	if parsed.has("drum_body_color"):
		drum_body_color = _parse_color(String(parsed["drum_body_color"]), "drum_body_color")
	if parsed.has("drum_face_color"):
		drum_face_color = _parse_color(String(parsed["drum_face_color"]), "drum_face_color")
	if parsed.has("hit_target_color"):
		hit_target_color = _parse_color(String(parsed["hit_target_color"]), "hit_target_color")

	_validate_resource_exists(note_don_path, "note_don")
	_validate_resource_exists(note_ka_path, "note_ka")


func _parse_color(value: String, key: String) -> Color:
	if not Color.html_is_valid(value):
		errors.append("invalid color %s" % key)
		return Color.WHITE
	return Color.html(value)


func _validate_resource_exists(path: String, key: String) -> void:
	if path == "":
		return
	if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
		errors.append("missing resource %s %s" % [key, path])


func _load_texture(path: String) -> Texture2D:
	if path == "":
		return null
	if ResourceLoader.exists(path):
		var resource := load(path)
		if resource is Texture2D:
			return resource
	if FileAccess.file_exists(path):
		var image := Image.new()
		var error := image.load(path)
		if error == OK:
			return ImageTexture.create_from_image(image)
		errors.append("invalid texture %s" % path)
	return _fallback_texture_for(path)


func _fallback_texture_for(path: String) -> Texture2D:
	var file_name := path.get_file().to_lower()
	var color := Color.BLACK
	if file_name.find("don") != -1:
		color = Color.RED
	elif file_name.find("ka") != -1:
		color = Color.DEEP_SKY_BLUE
	var image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)
