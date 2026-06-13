extends SceneTree

const TaikoChartScript: GDScript = preload("res://scripts/chart/taiko_chart.gd")

var failed_count := 0


func _init() -> void:
	var chart: RefCounted = TaikoChartScript.new()
	_test_defaults(chart)
	_test_fields_mutation(chart)
	_test_add_note_and_auto_ids(chart)
	_test_add_timing_event(chart)

	if failed_count == 0:
		print("PASS: TaikoChart")
		quit(0)
	else:
		push_error("FAIL: TaikoChart tests failed with %d assertion(s)." % failed_count)
		quit(1)


func _test_defaults(chart: RefCounted) -> void:
	_assert(chart.title == "", "Default title should be empty")
	_assert(chart.subtitle == "", "Default subtitle should be empty")
	_assert(chart.wave == "", "Default wave should be empty")
	_assert(chart.bpm == 120.0, "Default bpm should be 120.0")
	_assert(chart.offset_sec == 0.0, "Default offset should be 0.0")
	_assert(chart.course == "Oni", "Default course should be Oni")
	_assert(chart.level == 1, "Default level should be 1")
	_assert(chart.notes == [], "Default notes should be empty")
	_assert(chart.timing_events == [], "Default timing_events should be empty")


func _test_fields_mutation(chart: RefCounted) -> void:
	chart.title = "Test Song"
	chart.bpm = 140.0
	chart.offset_sec = -0.125
	_assert(chart.title == "Test Song", "Title assignment should persist")
	_assert(chart.bpm == 140.0, "Bpm assignment should persist")
	_assert(chart.offset_sec == -0.125, "Offset assignment should persist")


func _test_add_note_and_auto_ids(chart: RefCounted) -> void:
	chart.add_note(1.25, "don", "don", 0, 2)
	var first_note: Dictionary = chart.notes[0]
	_assert(first_note["id"] == "note_0001", "First note should use note_0001")
	_assert(first_note["time_sec"] == 1.25, "First note time should be stored")
	_assert(first_note["lane"] == "don", "First note lane should be don")
	_assert(first_note["kind"] == "don", "First note kind should be don")
	_assert(first_note["measure_index"] == 0, "First note measure_index should be 0")
	_assert(first_note["subdivision_index"] == 2, "First note subdivision_index should be 2")
	_assert(first_note["state"] == "pending", "First note state should be pending")

	chart.add_note(2.0, "ka", "ka", 0, 3)
	var second_note: Dictionary = chart.notes[1]
	_assert(second_note["id"] == "note_0002", "Second note should use note_0002")
	chart.add_note(2.0, "roll", "roll_big_start", 1, 0, {"duration_sec": 1.5, "required_hits": 0})
	chart.add_note(4.0, "balloon", "balloon_start", 2, 0, {"duration_sec": 2.0, "required_hits": 8})
	_assert(chart.notes[2]["kind"] == "roll_big_start", "Advanced roll note kind should be roll_big_start")
	_assert(is_equal_approx(chart.notes[2]["duration_sec"], 1.5), "Roll note should include duration_sec")
	_assert(chart.notes[3]["required_hits"] == 8, "Balloon note should include required_hits")


func _test_add_timing_event(chart: RefCounted) -> void:
	chart.add_timing_event(0.0, "bpm", 150.0)
	var event: Dictionary = chart.timing_events[0]
	_assert(event["time_sec"] == 0.0, "Timing event time should be 0.0")
	_assert(event["type"] == "bpm", "Timing event type should be bpm")
	_assert(event["value"] == 150.0, "Timing event value should be 150.0")
	chart.add_timing_event(2.0, "gogo", true)
	var gogo_event: Dictionary = chart.timing_events[1]
	_assert(gogo_event["time_sec"] == 2.0, "Boolean timing event time should be 2.0")
	_assert(gogo_event["type"] == "gogo", "Boolean timing event type should be gogo")
	_assert(gogo_event["value"] == true, "Boolean timing event value should be true")


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed_count += 1
		push_error("ASSERTION FAILED: " + message)
