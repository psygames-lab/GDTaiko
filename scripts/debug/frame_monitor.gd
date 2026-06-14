extends Control
class_name FrameMonitor

const TARGET_FRAME_TIME_MS := 16.67

var metrics_label: Label

var fps := 0.0
var frame_time_ms := 0.0
var active_notes := 0
var missed_frames := 0


func build() -> void:
	metrics_label = Label.new()
	metrics_label.position = Vector2(8.0, 8.0)
	metrics_label.add_theme_font_size_override("font_size", 16)
	metrics_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(metrics_label)
	_render()


func update_metrics(delta_sec: float, active_note_count: int) -> void:
	if delta_sec <= 0.0:
		frame_time_ms = 0.0
		fps = 0.0
	else:
		frame_time_ms = delta_sec * 1000.0
		fps = 1.0 / delta_sec

	active_notes = active_note_count

	if frame_time_ms > TARGET_FRAME_TIME_MS:
		missed_frames += 1

	_render()


func _render() -> void:
	if metrics_label == null:
		return

	metrics_label.text = "FPS: %.1f\nFrame Time: %.2f ms\nActive Notes: %d\nMissed Frames: %d" % [
		fps,
		frame_time_ms,
		active_notes,
		missed_frames
	]
