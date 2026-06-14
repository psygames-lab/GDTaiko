extends Control
class_name ResultScreen

const ScoreStore := preload("res://scripts/storage/score_store.gd")

var title_label: Label
var score_label: Label
var combo_label: Label
var counts_label: Label
var gauge_label: Label
var clear_label: Label
var last_result: Dictionary = {}
var score_store := ScoreStore.new()


func build() -> void:
	if title_label != null:
		return
	title_label = _label("Result", Vector2(460, 140), 42)
	score_label = _label("Score: 0", Vector2(460, 210), 30)
	combo_label = _label("Max Combo: 0", Vector2(460, 250), 30)
	counts_label = _label("Perfect 0  Good 0  Bad 0  Miss 0", Vector2(460, 290), 24)
	gauge_label = _label("Gauge: 0.0%", Vector2(460, 330), 28)
	clear_label = _label("Failed", Vector2(460, 376), 34)
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


func _save_best_result(result: Dictionary) -> void:
	var song_key := String(result.get("song_key", ""))
	var course := String(result.get("course", ""))
	if song_key == "" or course == "":
		return
	score_store.save_result(song_key, course, result)


func hide_result() -> void:
	visible = false


func _label(text: String, label_position: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = label_position
	label.add_theme_font_size_override("font_size", font_size)
	add_child(label)
	return label
