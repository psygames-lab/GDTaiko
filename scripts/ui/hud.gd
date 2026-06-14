extends CanvasLayer
class_name TaikoHud

var score_label: Label
var combo_label: Label
var judgment_label: Label
var status_label: Label
var gogo_label: Label

func build() -> void:
	score_label = _label("Score: 0", Vector2(24, 20), 28)
	combo_label = _label("Combo: 0", Vector2(24, 58), 28)
	gogo_label = _label("", Vector2(24, 96), 24)
	judgment_label = _label("F = Don    J = Ka    Space = Start", Vector2(360, 610), 26)
	status_label = _label("Ready", Vector2(24, 660), 22)

func update_score(score: int, combo: int) -> void:
	score_label.text = "Score: %d" % score
	combo_label.text = "Combo: %d" % combo

func show_judgment(judgment: String, timing_error_ms: float = 0.0) -> void:
	if judgment == "":
		judgment_label.text = "F = Don    J = Ka    Space = Start"
	else:
		judgment_label.text = "%s  %+.0f ms" % [judgment.capitalize(), timing_error_ms]

func set_status(text: String) -> void:
	status_label.text = text

func set_gogo(active: bool) -> void:
	gogo_label.text = "GOGO" if active else ""
	gogo_label.modulate = Color(1.0, 0.85, 0.15) if active else Color.WHITE

func _label(text: String, position: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position
	label.add_theme_font_size_override("font_size", font_size)
	add_child(label)
	return label
