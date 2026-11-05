extends SceneTree

const Gameplay := preload("res://scripts/gameplay/gameplay_controller.gd")
const Bridge := preload("res://scripts/telemetry/psygodot_bridge.gd")
const WARMUP_SEC := 2.0
const MEASURE_SEC := 10.0
const STEP_SEC := 1.0 / 120.0
const TOTAL_STEPS := 1440

var controller: Node
var bridge: Node
var enabled := false
var output_path := "res://output/telemetry_benchmark/run.json"
var started_usec := 0
var previous_usec := 0
var step_index := 0
var input_index := 0
var inputs: Array = []
var frames_ms: Array = []
var input_calls_usec: Array = []
var judgment_trace: Array = []
var ready_to_run := false


func _init() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument == "--capture":
			enabled = true
		elif argument.begins_with("--output="):
			output_path = argument.trim_prefix("--output=")
	call_deferred("_setup")


func _setup() -> void:
	controller = Gameplay.new()
	root.add_child(controller)
	controller.set_process(false)
	controller.set_process_unhandled_input(false)
	controller.game_config.input_offset_ms = 0
	controller.game_config.chart_offset_ms = 0
	controller.chart.notes.clear()
	controller.chart.timing_events.clear()
	controller.current_chart_path = "original_generated_benchmark"
	for index in range(140):
		var at := 0.5 + float(index) / 10.0
		var lane := "don" if index % 2 == 0 else "ka"
		controller.chart.notes.append({
			"id": "bench_%03d" % index, "time_sec": at, "lane": lane,
			"kind": lane, "state": "pending",
		})
		# Deliberate misses and three judgment offsets exercise score and effects.
		if index % 7 != 0:
			var offset := [0.0, 0.035, 0.085][index % 3] as float
			inputs.append({"time": at + offset, "lane": lane})
	controller._build_timing_map()
	controller.clock.using_audio_position = false
	controller.clock.chart_offset_sec = 0.0
	if enabled:
		bridge = Bridge.new()
		root.add_child(bridge)
		bridge.attach(controller, {
			"output_dir": output_path.get_base_dir().path_join("events"),
			"study_id": "rendered_benchmark", "capture_input": false,
		})
	controller._start_song()
	# Retain the real renderer, UI, sprites, effects and original sample audio.
	# Deterministic clock/input advancement separates judging from machine speed.
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	started_usec = Time.get_ticks_usec()
	previous_usec = started_usec
	ready_to_run = true


func _process(_delta: float) -> bool:
	if not ready_to_run:
		return false
	var now := Time.get_ticks_usec()
	var elapsed := float(now - started_usec) / 1000000.0
	if elapsed >= WARMUP_SEC and elapsed < WARMUP_SEC + MEASURE_SEC:
		frames_ms.append(float(now - previous_usec) / 1000.0)
	previous_usec = now
	var target_step := mini(TOTAL_STEPS, int(elapsed / STEP_SEC))
	while step_index < target_step:
		step_index += 1
		var song_time := step_index * STEP_SEC
		while input_index < inputs.size() and float(inputs[input_index]["time"]) <= song_time:
			var input: Dictionary = inputs[input_index]
			var before := Time.get_ticks_usec()
			controller.apply_replay_input(input["lane"], input["time"])
			var cost := Time.get_ticks_usec() - before
			if song_time >= WARMUP_SEC:
				input_calls_usec.append(cost)
			input_index += 1
		controller._process(STEP_SEC)
		judgment_trace.append(controller._build_result_payload())
	if step_index == TOTAL_STEPS:
		ready_to_run = false
		call_deferred("_finish")
	return false


func _finish() -> void:
	controller._end_song_event("benchmark_end")
	var statistics := {}
	if enabled:
		bridge.shutdown()
		statistics = bridge.get_statistics()
	var report := {
		"capture": enabled,
		"engine": Engine.get_version_info()["string"],
		"renderer": RenderingServer.get_current_rendering_method(),
		"gpu": RenderingServer.get_video_adapter_name(),
		"display": DisplayServer.get_name(),
		"window_size": "1280x720", "vsync": false, "max_fps": 0,
		"warmup_sec": WARMUP_SEC, "measured_sec": MEASURE_SEC,
		"simulation_steps": step_index, "inputs": input_index,
		"frame_ms": _distribution(frames_ms),
		"input_call_usec": _distribution(input_calls_usec),
		"frames_over_16_67_ms": _count_over(frames_ms, 16.67),
		"frames_over_33_33_ms": _count_over(frames_ms, 33.33),
		"recording": statistics,
		"result": controller._build_result_payload(),
		"notes": controller.chart.notes,
		"judgment_trace": judgment_trace,
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_path.get_base_dir()))
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("BENCHMARK ", JSON.stringify({"capture": enabled, "frame_ms": report["frame_ms"], "recording": statistics, "output": output_path}))
	controller.free()
	if bridge != null:
		bridge.free()
	quit(0 if not enabled or statistics["complete"] else 1)


func _distribution(values: Array) -> Dictionary:
	values.sort()
	var total := 0.0
	for value in values:
		total += value
	return {
		"count": values.size(), "mean": total / values.size(),
		"p50": values[int((values.size() - 1) * 0.50)],
		"p95": values[int((values.size() - 1) * 0.95)],
		"p99": values[int((values.size() - 1) * 0.99)],
		"max": values.back(),
	}


func _count_over(values: Array, threshold: float) -> int:
	var count := 0
	for value in values:
		if value > threshold:
			count += 1
	return count
