extends CanvasLayer
class_name TaikoHud

var score_label: Label
var combo_label: Label
var judgment_label: Label
var status_label: Label
var gogo_label: Label
var top_band: ColorRect
var soul_gauge_background: ColorRect
var soul_gauge_fill: ColorRect

const VIEWPORT_SIZE := Vector2(1280.0, 720.0)
const GAUGE_MAX_WIDTH := 680.0

func build() -> void:
	if score_label != null:
		return
	top_band = ColorRect.new()
	top_band.name = "TopBand"
	top_band.position = Vector2(0.0, 0.0)
	top_band.size = Vector2(VIEWPORT_SIZE.x, 112.0)
	top_band.color = Color(0.08, 0.08, 0.09, 0.92)
	add_child(top_band)

	soul_gauge_background = ColorRect.new()
	soul_gauge_background.name = "SoulGaugeBackground"
	soul_gauge_background.position = Vector2(300.0, 26.0)
	soul_gauge_background.size = Vector2(GAUGE_MAX_WIDTH, 26.0)
	soul_gauge_background.color = Color(0.18, 0.16, 0.12, 1.0)
	add_child(soul_gauge_background)

	soul_gauge_fill = ColorRect.new()
	soul_gauge_fill.name = "SoulGaugeFill"
	soul_gauge_fill.position = soul_gauge_background.position
	soul_gauge_fill.size = Vector2(0.0, soul_gauge_background.size.y)
	soul_gauge_fill.color = Color(1.0, 0.65, 0.12, 1.0)
	add_child(soul_gauge_fill)

	combo_label = _label("Combo: 0", Vector2(520, 58), 32, Vector2(240, 40))
	score_label = _label("Score: 0", Vector2(840, 58), 30, Vector2(320, 40))
	gogo_label = _label("", Vector2(180, 32), 30, Vector2(96, 40))
	judgment_label = _label("F = Don    J = Ka    Space = Start", Vector2(380, 586), 28, Vector2(560, 48))
	status_label = _label("Ready", Vector2(32, 642), 24, Vector2(420, 36))

func update_score(score: int, combo: int) -> void:
	score_label.text = "Score: %d" % score
	combo_label.text = "Combo: %d" % combo

func update_gauge(value: float) -> void:
	var normalized := clampf(value / 100.0, 0.0, 1.0)
	soul_gauge_fill.size = Vector2(GAUGE_MAX_WIDTH * normalized, soul_gauge_background.size.y)

func apply_theme(theme: Variant) -> void:
	if top_band != null:
		top_band.color = theme.hud_top_band_color
	if soul_gauge_fill != null:
		soul_gauge_fill.color = theme.gauge_fill_color

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

func _label(text: String, position: Vector2, font_size: int, label_size: Vector2 = Vector2.ZERO) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position
	if label_size != Vector2.ZERO:
		label.size = label_size
		label.custom_minimum_size = label_size
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_font_size_override("font_size", font_size)
	add_child(label)
	return label
