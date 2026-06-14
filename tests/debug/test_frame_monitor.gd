extends SceneTree

const FrameMonitorScript: GDScript = preload("res://scripts/debug/frame_monitor.gd")

var failed_count := 0


func _init() -> void:
	var monitor: Control = FrameMonitorScript.new() as Control
	monitor.build()
	monitor.update_metrics(1.0 / 120.0, 12)

	_assert(monitor.frame_time_ms > 0.0, "frame_time_ms should be initialized from delta time")
	_assert(is_equal_approx(monitor.fps, 120.0), "FPS should be derived from delta time")
	_assert(monitor.active_notes == 12, "active notes should match input")
	_assert(monitor.missed_frames == 0, "missed_frames should start at zero")
	_assert(monitor.metrics_label != null, "metrics_label should be created")
	_assert(monitor.metrics_label.text.find("FPS: 120.0") != -1, "metrics label should include FPS")
	_assert(monitor.metrics_label.text.find("Missed Frames: 0") != -1, "metrics label should include missed frame count")

	monitor.update_metrics(0.020, 7)
	_assert(monitor.missed_frames == 1, "update_metrics should count frames over 16.67 ms")
	_assert(monitor.metrics_label.text.find("Missed Frames: 1") != -1, "metrics label should update missed frame count")

	monitor.free()

	if failed_count == 0:
		print("PASS: FrameMonitor")
		quit(0)
	else:
		push_error("FAIL: FrameMonitor tests failed with %d assertion(s)." % failed_count)
		quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed_count += 1
		push_error("ASSERTION FAILED: " + message)
