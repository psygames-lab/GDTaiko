extends CanvasLayer
class_name ResultScreen

const ScoreStore := preload("res://scripts/storage/score_store.gd")

var title_label: Label
var score_label: Label
var combo_label: Label
var counts_label: Label
var gauge_label: Label
var clear_label: Label
var overlay: ColorRect
var panel: ColorRect
var last_result: Dictionary = {}
var score_store := ScoreStore.new()

const VIEWPORT_SIZE := Vector2(1280.0, 720.0)


func build() -> void:
	if title_label != null:
		return
	layer = 20
	overlay = ColorRect.new()
	overlay.name = "ResultOverlay"
	overlay.position = Vector2.ZERO
	overlay.size = VIEWPORT_SIZE
	overlay.color = Color(0.0, 0.0, 0.0, 0.62)
	add_child(overlay)

	panel = ColorRect.new()
	panel.name = "ResultPanel"
	panel.position = Vector2(340.0, 118.0)
	panel.size = Vector2(600.0, 412.0)
	panel.color = Color(0.08, 0.08, 0.09, 0.96)
	add_child(panel)

	title_label = _label("Result", Vector2(390, 150), 44, Vector2(500, 56))
	score_label = _label("Score: 0", Vector2(390, 224), 30, Vector2(500, 40))
	combo_label = _label("Max Combo: 0", Vector2(390, 268), 30, Vector2(500, 40))
	counts_label = _label("Perfect 0  Good 0  Bad 0  Miss 0", Vector2(390, 314), 24, Vector2(500, 34))
	gauge_label = _label("Gauge: 0.0%", Vector2(390, 360), 28, Vector2(500, 38))
	clear_label = _label("Failed", Vector2(390, 420), 36, Vector2(500, 50))
	hide_result()


func show_result(result: Dictionary) -> void:
	build()
	last_result = result.duplicate()
	_save_best_result(result)
	score_label.text = "Score: %d" % int(result.get("score", 0))
	combo_label.text = "Max Combo: %d" % int(result.get("max_combo", 0))
	counts_label.text = "Perfect %d  Good %d  Bad %d  Miss %d" % [
		int(result.get("perfects", 0)),
		int(result.get("goods", 0)),
		int(result.get("bads", 0)),
		int(result.get("misses", 0)),
	]
	gauge_label.text = "Gauge: %.1f%%" % float(result.get("gauge", 0.0))
	clear_label.text = "Clear" if bool(result.get("clear", false)) else "Failed"
	visible = true


func apply_theme(theme: Variant) -> void:
	if panel != null:
		panel.color = theme.result_panel_color


func _save_best_result(result: Dictionary) -> void:
	var song_key := String(result.get("song_key", ""))
	var course := String(result.get("course", ""))
	if song_key == "" or course == "":
		return
	score_store.save_result(song_key, course, result)


func hide_result() -> void:
	visible = false


func _label(text: String, label_position: Vector2, font_size: int, label_size: Vector2 = Vector2.ZERO) -> Label:
	var label := Label.new()
	label.text = text
	label.position = label_position
	if label_size != Vector2.ZERO:
		label.size = label_size
		label.custom_minimum_size = label_size
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_font_size_override("font_size", font_size)
	add_child(label)
	return label
