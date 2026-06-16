extends SceneTree

const TjaParserScript: GDScript = preload("res://scripts/chart/tja_parser.gd")

const FIXTURE_DIR := "res://tests/fixtures/tja"
const FIXTURE_NAMES := [
	"basic_notes",
	"bpm_changes",
	"scroll_changes",
	"measure_changes",
	"standard_notes",
	"roll_balloon",
	"gogo",
	"branch_basic",
	"metadata_variants",
	"unsupported_commands",
]

var failed_count := 0


func _init() -> void:
	_test_all_compatibility_fixtures_match_expected_sidecars()

	if failed_count == 0:
		print("PASS: TjaCompatibility")
		quit(0)
	else:
		push_error("FAIL: TjaCompatibility tests failed with %d assertion(s)." % failed_count)
		quit(1)


func _test_all_compatibility_fixtures_match_expected_sidecars() -> void:
	for fixture_name in FIXTURE_NAMES:
		var fixture_path := "%s/%s.tja" % [FIXTURE_DIR, fixture_name]
		var expected_path := "%s/%s.expected.json" % [FIXTURE_DIR, fixture_name]
		_assert(FileAccess.file_exists(fixture_path), "Fixture should exist: %s" % fixture_path)
		_assert(FileAccess.file_exists(expected_path), "Expected sidecar should exist: %s" % expected_path)
		if not FileAccess.file_exists(fixture_path) or not FileAccess.file_exists(expected_path):
			continue

		var expected := _load_expected(expected_path)
		var chart: RefCounted = TjaParserScript.parse_file(fixture_path)
		_assert(chart.title == String(expected.get("title", "")), "%s title should match sidecar" % fixture_name)
		_assert(chart.notes.size() == int(expected.get("note_count", -1)), "%s note count should match sidecar" % fixture_name)
		_assert(chart.timing_events.size() == int(expected.get("timing_event_count", -1)), "%s timing event count should match sidecar" % fixture_name)
		if expected.has("branch_event_count"):
			_assert(chart.branch_events.size() == int(expected["branch_event_count"]), "%s branch event count should match sidecar" % fixture_name)
		if expected.has("diagnostic_codes"):
			_assert(_diagnostic_codes(chart.diagnostics) == _string_array(expected["diagnostic_codes"]), "%s diagnostic codes should match sidecar" % fixture_name)
		_assert(_string_array(chart.warnings) == _string_array(expected.get("warnings", [])), "%s warnings should match sidecar" % fixture_name)
		if expected.has("metadata"):
			_assert(chart.metadata == expected["metadata"], "%s metadata should match sidecar" % fixture_name)


func _load_expected(path: String) -> Dictionary:
	var parse_result: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parse_result) != TYPE_DICTIONARY:
		_assert(false, "Expected sidecar should parse as a dictionary: %s" % path)
		return {}
	return parse_result


func _string_array(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(String(value))
	return result


func _diagnostic_codes(diagnostics: Array) -> Array[String]:
	var result: Array[String] = []
	for diagnostic in diagnostics:
		result.append(String(diagnostic.code))
	return result


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed_count += 1
		push_error("ASSERTION FAILED: " + message)
