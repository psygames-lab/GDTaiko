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
var errors: Array[String] = []


static func load_from_file(path: String) -> Variant:
	var script: GDScript = load("res://scripts/theme/taiko_theme.gd")
	var theme = script.new()
	theme._load_from_file(path)
	return theme


func is_valid() -> bool:
	return errors.is_empty()


func get_note_don_texture() -> Texture2D:
	return _load_texture(note_don_path)


func get_note_ka_texture() -> Texture2D:
	return _load_texture(note_ka_path)


func _load_from_file(path: String) -> void:
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

	for key in REQUIRED_KEYS:
		if not parsed.has(key) or String(parsed[key]) == "":
			errors.append("missing required key %s" % key)

	name = String(parsed.get("name", ""))
	note_don_path = String(parsed.get("note_don", ""))
	note_ka_path = String(parsed.get("note_ka", ""))
	sfx_don_path = String(parsed.get("sfx_don", ""))
	sfx_ka_path = String(parsed.get("sfx_ka", ""))
	font_main_path = String(parsed.get("font_main", ""))
	lane_color = _parse_color(String(parsed.get("lane_color", "#000000")), "lane_color")
	gogo_color = _parse_color(String(parsed.get("gogo_color", "#ffffff")), "gogo_color")

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
