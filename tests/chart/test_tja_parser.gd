extends SceneTree

const TjaParserScript: GDScript = preload("res://scripts/chart/tja_parser.gd")

var failed_count := 0


func _init() -> void:
	_test_sample_parse()
	_test_notes_before_start_are_ignored()
	_test_end_terminates_parsing()
	_test_measure_accumulates_across_notes_lines()
	_test_measure_command_timing_event()
	_test_invalid_initial_bpm_fallback()
	_test_trailing_text_bpm_is_invalid()
	_test_zero_bpm_uses_default_fallback()
	_test_invalid_measure_argument_ignored()
	_test_trailing_text_measure_is_invalid()
	_test_unsupported_note_character_warning()
	_test_roll_and_balloon_notes()
	_test_bpm_change_timing_event()
	_test_gogo_timing_events()
	_test_scroll_timing_event()
	_test_preserves_all_metadata()
	_test_title_wins_over_titleen()
	_test_titleen_fallback_when_title_missing()
	_test_empty_title_still_wins_over_titleen()
	_test_empty_subtitle_still_wins_over_subtitleen()
	_test_branch_sections_are_separated()
	_test_unsupported_branch_condition_warns_and_defaults_to_normal()
	_test_branch_resume_uses_normal_timing()
	_test_branch_resume_uses_normal_balloon_index()
	_test_branch_internal_timing_command_does_not_mutate_global_state()
	_test_diagnostic_codes_and_line_numbers()
	_test_unsupported_command_diagnostic()
	_test_unterminated_long_note_diagnostic()
	_test_missing_audio_diagnostic()
	_test_branch_lane_diagnostics_are_preserved()
	_test_metadata_has_only_tja_keys()
	_test_absolute_wave_path_is_not_joined_to_source_folder()
	_test_branch_lane_unterminated_long_note_diagnostic()
	_test_parse_courses_text_returns_each_course()
	_test_parse_text_returns_first_course_for_compatibility()
	_test_parse_courses_text_keeps_between_course_metadata_local()

	if failed_count == 0:
		print("PASS: TjaParser")
		quit(0)
	else:
		push_error("FAIL: TjaParser tests failed with %d assertion(s)." % failed_count)
		quit(1)


func _test_sample_parse() -> void:
	var text := """TITLE:Parser Song
SUBTITLE:Unit Test
BPM:120
OFFSET:-0.5
WAVE:parser.ogg
COURSE:Oni
LEVEL:5
#START
1002,
0100,
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text)
	_assert(chart.title == "Parser Song", "Title should parse from metadata")
	_assert(chart.subtitle == "Unit Test", "Subtitle should parse from metadata")
	_assert(chart.wave == "parser.ogg", "Wave should parse from metadata")
	_assert(chart.course == "Oni", "Course should parse from metadata")
	_assert(chart.level == 5, "Level should parse from metadata")
	_assert(chart.bpm == 120.0, "BPM should parse from metadata")
	_assert(chart.offset_sec == -0.5, "OFFSET should parse from metadata")
	_assert(chart.notes.size() == 3, "Notes should include only supported note chars")
	_assert(chart.notes[0]["lane"] == "don", "First note should be don")
	_assert(chart.notes[1]["lane"] == "ka", "Second note should be ka")
	_assert(chart.notes[2]["lane"] == "don", "Third note should be don")
	_assert(is_equal_approx(chart.notes[0]["time_sec"], -0.5), "First note time should include OFFSET")
	_assert(is_equal_approx(chart.notes[1]["time_sec"], 1.0), "Second note time should include slot timing and OFFSET")
	_assert(is_equal_approx(chart.notes[2]["time_sec"], 2.0), "Third note time should include new measure and OFFSET")


func _test_notes_before_start_are_ignored() -> void:
	var text := """1002,
#START
1000,
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text)
	_assert(chart.notes.size() == 1, "Notes before START should be ignored")
	_assert(chart.notes[0]["lane"] == "don", "First parsed note after START should be don")


func _test_unsupported_note_character_warning() -> void:
	var text := """#START
13,
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text)
	_assert(chart.notes.size() == 1, "Unsupported note chars should be ignored but valid notes still parse")
	_assert(chart.warnings.size() == 1, "Unsupported note char should add one warning")
	_assert(chart.warnings[0].find("Unsupported note character") >= 0, "Warning should mention unsupported note character")
	_assert(chart.warnings[0].find("3") >= 0, "Warning should identify unsupported char value")


func _test_roll_and_balloon_notes() -> void:
	var text := """TITLE:Roll Balloon
BPM:120
BALLOON:8
#START
5008,
7008,
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text)
	_assert(chart.notes.size() == 2, "Roll and balloon fixture should create two note starts")
	if chart.notes.size() < 2:
		return
	_assert(chart.notes[0]["kind"] == "roll_start", "5 should create a small roll start")
	_assert(is_equal_approx(chart.notes[0]["duration_sec"], 1.5), "8 should close roll with expected duration")
	_assert(chart.notes[1]["kind"] == "balloon_start", "7 should create a balloon start")
	_assert(chart.notes[1]["required_hits"] == 8, "Balloon note should use BALLOON metadata")


func _test_end_terminates_parsing() -> void:
	var text := """#START
1,
#END
22,
#START
2,
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text)
	_assert(chart.notes.size() == 1, "#END should stop processing all subsequent chart tokens")
	_assert(chart.notes[0]["lane"] == "don", "Only first parsed note should remain")


func _test_measure_accumulates_across_notes_lines() -> void:
	var text := """BPM:120
OFFSET:0
#START
10
02,
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text)
	_assert(chart.notes.size() == 2, "Pending measure characters should combine across note lines")
	_assert(chart.notes[0]["lane"] == "don", "First note in combined measure should parse")
	_assert(chart.notes[1]["lane"] == "ka", "Second note in combined measure should parse")
	_assert(is_equal_approx(chart.notes[0]["time_sec"], 0.0), "First note in combined measure should be at 0.0")
	_assert(is_equal_approx(chart.notes[1]["time_sec"], 1.5), "Second note in combined measure should be at 1.5 seconds for a 4-slot measure")


func _test_measure_command_timing_event() -> void:
	var text := """BPM:120
#START
10,
#MEASURE 2/4
10,
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text)
	_assert(chart.timing_events.size() == 2, "Measure change should add a timing event")
	_assert(chart.timing_events[1]["type"] == "measure", "Second timing event should be measure")
	_assert(is_equal_approx(chart.timing_events[1]["time_sec"], 2.0), "Measure change event should use current chart time plus offset")
	_assert(chart.timing_events[1]["value"] == "2/4", "Measure change value should preserve argument")


func _test_invalid_initial_bpm_fallback() -> void:
	var text := """BPM:abc
#START
1,
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text)
	_assert(chart.bpm == 120.0, "Invalid initial BPM should keep default BPM")
	_assert(chart.timing_events.size() == 1, "Parser should still add a single initial bpm timing event")
	_assert(chart.timing_events[0]["type"] == "bpm", "Initial timing event type should be bpm")
	_assert(is_equal_approx(chart.timing_events[0]["value"], 120.0), "Initial bpm timing event should use fallback BPM")
	_assert(chart.notes.size() == 1, "Invalid BPM chart should still parse notes normally")
	_assert(chart.notes[0]["time_sec"] == 0.0, "Invalid BPM should not break note timing")
	_assert(chart.warnings.size() == 1, "Invalid BPM should append one warning")
	_assert(chart.warnings[0].find("Invalid BPM value") >= 0, "Invalid BPM warning should be recorded")


func _test_trailing_text_bpm_is_invalid() -> void:
	var text := """BPM:120abc
#START
1,
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text)
	_assert(chart.bpm == 120.0, "BPM with trailing text should be invalid and keep fallback BPM")
	_assert(chart.timing_events.size() == 1, "Parser should still add a single initial bpm timing event")
	_assert(chart.timing_events[0]["type"] == "bpm", "Initial timing event type should be bpm")
	_assert(is_equal_approx(chart.timing_events[0]["value"], 120.0), "Initial bpm timing event should use fallback BPM")
	_assert(chart.notes.size() == 1, "Trailing-text BPM chart should still parse notes")
	_assert(chart.notes[0]["time_sec"] == 0.0, "Trailing-text BPM should not break note timing")
	_assert(chart.warnings.size() == 1, "Trailing-text BPM should append one warning")
	_assert(chart.warnings[0].find("Invalid BPM value") >= 0, "Trailing-text BPM warning should be recorded")


func _test_zero_bpm_uses_default_fallback() -> void:
	var text := """BPM:0
#START
1,
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text)
	_assert(chart.bpm == 120.0, "Zero initial BPM should keep default BPM")
	_assert(chart.timing_events.size() == 1, "Parser should still add a single initial bpm timing event")
	_assert(chart.timing_events[0]["type"] == "bpm", "Initial timing event type should be bpm")
	_assert(is_equal_approx(chart.timing_events[0]["value"], 120.0), "Initial bpm timing event should use fallback BPM")
	_assert(chart.notes.size() == 1, "Zero BPM chart should still parse notes normally")
	_assert(chart.notes[0]["time_sec"] == 0.0, "Zero BPM should not break note timing")
	_assert(chart.warnings.size() == 1, "Zero BPM should append one warning")
	_assert(chart.warnings[0].find("Invalid BPM value") >= 0, "Zero BPM warning should be recorded")


func _test_invalid_measure_argument_ignored() -> void:
	var text := """BPM:120
#START
10,
#MEASURE 0/4
10,
#MEASURE 4/-4
10,
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text)
	_assert(chart.timing_events.size() == 1, "Invalid MEASURE commands should not add measure timing events")
	_assert(chart.timing_events[0]["type"] == "bpm", "Only initial bpm event should exist")
	_assert(chart.timing_events[0]["value"] == 120.0, "Initial bpm timing event should be 120")
	_assert(chart.notes.size() == 3, "Notes should still parse across invalid measure commands")
	_assert(chart.warnings.size() == 2, "Each invalid MEASURE should append one warning")
	_assert(chart.warnings[0].find("Invalid MEASURE value '0/4'") >= 0, "First invalid measure warning should mention 0/4")
	_assert(chart.warnings[1].find("Invalid MEASURE value '4/-4'") >= 0, "Second invalid measure warning should mention 4/-4")


func _test_trailing_text_measure_is_invalid() -> void:
	var text := """BPM:120
#START
10,
#MEASURE 4abc/4
10,
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text)
	_assert(chart.timing_events.size() == 1, "Trailing-text MEASURE should not add a measure timing event")
	_assert(chart.warnings.size() == 1, "Trailing-text MEASURE should append one warning")
	_assert(chart.warnings[0].find("Invalid MEASURE value '4abc/4'") >= 0, "Trailing-text MEASURE warning should mention argument")
	_assert(chart.notes.size() == 2, "Notes should still parse with trailing-text MEASURE command")


func _test_bpm_change_timing_event() -> void:
	var text := """BPM:120
OFFSET:-0.5
#START
1000,
#BPMCHANGE 60
1000,
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text)
	_assert(chart.timing_events.size() == 2, "Chart should include initial BPM event and BPMCHANGE event")
	_assert(chart.timing_events[0]["type"] == "bpm", "First timing event should be bpm")
	_assert(is_equal_approx(chart.timing_events[0]["time_sec"], 0.0), "Start BPM event should be at 0.0")
	_assert(is_equal_approx(chart.timing_events[1]["time_sec"], 1.5), "BPMCHANGE event should include OFFSET in timing")
	_assert(chart.timing_events[1]["type"] == "bpm", "BPMCHANGE event should be bpm type")
	_assert(is_equal_approx(chart.timing_events[1]["value"], 60.0), "BPMCHANGE value should be applied")


func _test_gogo_timing_events() -> void:
	var text := """TITLE:Gogo
BPM:120
#START
#GOGOSTART
1000,
#GOGOEND
1000,
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text)
	var found_start := false
	var found_end := false
	for event in chart.timing_events:
		if String(event["type"]) == "gogo" and bool(event["value"]) == true:
			found_start = true
			_assert(is_equal_approx(float(event["time_sec"]), 0.0), "GOGOSTART should use current chart time")
		if String(event["type"]) == "gogo" and bool(event["value"]) == false:
			found_end = true
			_assert(is_equal_approx(float(event["time_sec"]), 2.0), "GOGOEND should use current chart time")
	_assert(found_start, "Parser should add GOGOSTART timing event")
	_assert(found_end, "Parser should add GOGOEND timing event")


func _test_scroll_timing_event() -> void:
	var text := """BPM:120
#START
1000,
#SCROLL 2.5
1000,
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text)
	var found_scroll := false
	for event in chart.timing_events:
		if String(event["type"]) == "scroll":
			found_scroll = true
			_assert(is_equal_approx(float(event["time_sec"]), 2.0), "SCROLL event should use current chart time")
			_assert(is_equal_approx(float(event["value"]), 2.5), "SCROLL event should preserve scroll value")
	_assert(found_scroll, "Parser should add SCROLL timing event")


func _test_preserves_all_metadata() -> void:
	var text := """TITLE:Metadata Song
TITLEEN:Metadata Song EN
DEMOSTART:8.25
GENRE:Original
MAKER:GDTaiko
LYRICFILE:lyrics.vtt
SCOREINIT:300
SCOREDIFF:80
UNKNOWNMETA:kept
#START
1,
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text)
	_assert(chart.metadata["TITLE"] == "Metadata Song", "Metadata dictionary should preserve TITLE")
	_assert(chart.metadata["TITLEEN"] == "Metadata Song EN", "Metadata dictionary should preserve TITLEEN")
	_assert(chart.metadata["DEMOSTART"] == "8.25", "Metadata dictionary should preserve DEMOSTART")
	_assert(chart.metadata["GENRE"] == "Original", "Metadata dictionary should preserve GENRE")
	_assert(chart.metadata["MAKER"] == "GDTaiko", "Metadata dictionary should preserve MAKER")
	_assert(chart.metadata["LYRICFILE"] == "lyrics.vtt", "Metadata dictionary should preserve LYRICFILE")
	_assert(chart.metadata["SCOREINIT"] == "300", "Metadata dictionary should preserve SCOREINIT")
	_assert(chart.metadata["SCOREDIFF"] == "80", "Metadata dictionary should preserve SCOREDIFF")
	_assert(chart.metadata["UNKNOWNMETA"] == "kept", "Metadata dictionary should preserve unknown metadata")


func _test_title_wins_over_titleen() -> void:
	var text := """TITLE:Primary Title
TITLEEN:English Title
#START
1,
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text)
	_assert(chart.title == "Primary Title", "TITLE should win over TITLEEN when both are present")


func _test_titleen_fallback_when_title_missing() -> void:
	var text := """TITLEEN:English Fallback
#START
1,
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text)
	_assert(chart.title == "English Fallback", "TITLEEN should populate title when TITLE is missing")


func _test_empty_title_still_wins_over_titleen() -> void:
	var text := """TITLE:
TITLEEN:English Title
#START
1,
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text)
	_assert(chart.title == "", "Empty TITLE should still win over TITLEEN when TITLE is present")


func _test_empty_subtitle_still_wins_over_subtitleen() -> void:
	var text := """SUBTITLE:
SUBTITLEEN:English Subtitle
#START
1,
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text)
	_assert(chart.subtitle == "", "Empty SUBTITLE should still win over SUBTITLEEN when SUBTITLE is present")


func _test_branch_sections_are_separated() -> void:
	var text := """TITLE:Branch Parser
BPM:120
#START
#BRANCHSTART p,50,90
#N
1000,
#E
2000,
#M
1200,
#BRANCHEND
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text)
	_assert(chart.branch_events.size() == 1, "Parser should add one branch event")
	_assert(chart.notes.size() == 1, "Parser should use normal branch notes as default playable notes")
	if chart.branch_events.is_empty():
		return
	var branch: Dictionary = chart.branch_events[0]
	_assert(branch["type"] == "branch_start", "Branch event type should be branch_start")
	_assert(branch["condition"] == "accuracy", "p branch condition should map to accuracy")
	_assert(is_equal_approx(float(branch["expert_threshold"]), 50.0), "Branch expert threshold should parse")
	_assert(is_equal_approx(float(branch["master_threshold"]), 90.0), "Branch master threshold should parse")
	_assert(branch["normal_notes"].size() == 1, "Normal branch should keep its notes separately")
	_assert(branch["expert_notes"].size() == 1, "Expert branch should keep its notes separately")
	_assert(branch["master_notes"].size() == 2, "Master branch should keep its notes separately")
	_assert(branch["normal_notes"][0]["lane"] == "don", "Normal branch note should parse")
	_assert(branch["expert_notes"][0]["lane"] == "ka", "Expert branch note should parse")
	_assert(branch["master_notes"][0]["lane"] == "don", "Master branch first note should parse")
	_assert(branch["master_notes"][1]["lane"] == "ka", "Master branch second note should parse")


func _test_unsupported_branch_condition_warns_and_defaults_to_normal() -> void:
	var text := """TITLE:Unsupported Branch
BPM:120
#START
#BRANCHSTART x,50,90
#N
1000,
#BRANCHEND
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text)
	_assert(chart.branch_events.size() == 1, "Unsupported branch condition should still create a branch event")
	if not chart.branch_events.is_empty():
		_assert(chart.branch_events[0]["condition"] == "normal", "Unsupported branch condition should default to normal")
	_assert(chart.warnings.size() == 1, "Unsupported branch condition should add one warning")
	if not chart.warnings.is_empty():
		_assert(chart.warnings[0].find("Unsupported BRANCHSTART condition") >= 0, "Warning should identify unsupported branch condition")
	_assert(chart.diagnostics.size() == 1, "Unsupported branch condition should add one diagnostic")
	if not chart.diagnostics.is_empty():
		_assert(chart.diagnostics[0].code == "branch_fallback", "Unsupported branch condition should use branch_fallback code")
		_assert(chart.diagnostics[0].line_number == 4, "Unsupported branch diagnostic should preserve line number")


func _test_branch_resume_uses_normal_timing() -> void:
	var text := """TITLE:Branch Resume Timing
BPM:120
#START
#BRANCHSTART p,50,90
#N
1000,
#E
1000,
1000,
#M
1000,
#BRANCHEND
1000,
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text)
	_assert(chart.notes.size() == 2, "Normal branch default notes plus post-branch note should be playable")
	if chart.notes.size() < 2:
		return
	_assert(is_equal_approx(float(chart.notes[0]["time_sec"]), 0.0), "Normal branch note should start at branch time")
	_assert(is_equal_approx(float(chart.notes[1]["time_sec"]), 2.0), "Post-branch notes should resume after normal branch timing")


func _test_branch_resume_uses_normal_balloon_index() -> void:
	var text := """TITLE:Branch Resume Balloon
BPM:120
BALLOON:3,7
#START
#BRANCHSTART p,50,90
#N
1000,
#E
7008,
#M
1000,
#BRANCHEND
7008,
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text)
	_assert(chart.notes.size() == 2, "Normal branch note and post-branch balloon should be playable")
	if chart.notes.size() < 2:
		return
	_assert(chart.notes[1]["kind"] == "balloon_start", "Post-branch note should be a balloon")
	_assert(chart.notes[1]["required_hits"] == 3, "Post-branch balloon should use normal branch balloon index")


func _test_branch_internal_timing_command_does_not_mutate_global_state() -> void:
	var text := """TITLE:Branch Internal Command
BPM:120
#START
#BRANCHSTART p,50,90
#N
1000,
#E
#BPMCHANGE 60
1000,
#M
1000,
#BRANCHEND
1000,
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text)
	_assert(chart.timing_events.size() == 1, "Branch-internal BPMCHANGE should not add global timing events")
	_assert(chart.warnings.size() == 1, "Branch-internal unsupported timing command should warn once")
	if not chart.warnings.is_empty():
		_assert(chart.warnings[0].find("Ignoring branch-internal command") >= 0, "Warning should mention ignored branch command")
	_assert(chart.notes.size() == 2, "Normal branch note and post-branch note should be playable")
	if chart.notes.size() >= 2:
		_assert(is_equal_approx(float(chart.notes[1]["time_sec"]), 2.0), "Ignored branch BPMCHANGE should not affect post-branch timing")


func _test_diagnostic_codes_and_line_numbers() -> void:
	var text := """BPM:abc
#START
13,
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text)
	_assert(chart.diagnostics.size() == 2, "Invalid BPM and unsupported note should add diagnostics")
	if chart.diagnostics.size() < 2:
		return
	_assert(chart.diagnostics[0].code == "invalid_metadata", "Invalid BPM should use invalid_metadata code")
	_assert(chart.diagnostics[0].line_number == 1, "Invalid BPM diagnostic should preserve line number")
	_assert(chart.diagnostics[1].code == "unsupported_note", "Unsupported note should use unsupported_note code")
	_assert(chart.diagnostics[1].line_number == 3, "Unsupported note diagnostic should preserve note line number")


func _test_unsupported_command_diagnostic() -> void:
	var text := """TITLE:Unsupported Command
#START
#DELAY 1.0
1000,
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text)
	_assert(chart.diagnostics.size() == 1, "Unsupported command should add one diagnostic")
	if chart.diagnostics.is_empty():
		return
	_assert(chart.diagnostics[0].code == "unsupported_command", "Unsupported command should use unsupported_command code")
	_assert(chart.diagnostics[0].line_number == 3, "Unsupported command diagnostic should preserve line number")


func _test_unterminated_long_note_diagnostic() -> void:
	var text := """TITLE:Unterminated Roll
#START
5000,
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text)
	_assert(chart.diagnostics.size() == 1, "Unterminated roll should add one diagnostic")
	if chart.diagnostics.is_empty():
		return
	_assert(chart.diagnostics[0].code == "unterminated_long_note", "Unterminated roll should use unterminated_long_note code")
	_assert(chart.diagnostics[0].line_number == 3, "Unterminated roll diagnostic should preserve start line number")


func _test_missing_audio_diagnostic() -> void:
	var text := """TITLE:Missing Audio
WAVE:missing_audio.ogg
#START
1,
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text, "res://tests/fixtures/tja/missing_audio_probe.tja")
	_assert(chart.diagnostics.size() == 1, "Missing WAVE file should add one diagnostic when source path is known")
	if chart.diagnostics.is_empty():
		return
	_assert(chart.diagnostics[0].code == "missing_audio", "Missing WAVE file should use missing_audio code")
	_assert(chart.diagnostics[0].line_number == 2, "Missing WAVE diagnostic should preserve WAVE line number")


func _test_branch_lane_diagnostics_are_preserved() -> void:
	var text := """TITLE:Branch Unsupported Note
BPM:120
#START
#BRANCHSTART p,50,90
#N
1000,
#E
3000,
#M
1000,
#BRANCHEND
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text)
	var codes: Array[String] = []
	for diagnostic in chart.diagnostics:
		codes.append(String(diagnostic.code))
	_assert(codes.has("unsupported_note"), "Unsupported note inside branch lanes should be preserved on parent chart")


func _test_metadata_has_only_tja_keys() -> void:
	var text := """TITLE:Public Metadata
WAVE:missing_audio.ogg
#START
1,
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text, "res://tests/fixtures/tja/public_metadata_probe.tja")
	for key in chart.metadata:
		_assert(not String(key).begins_with("__line_"), "Public metadata should not expose parser-internal line keys")


func _test_absolute_wave_path_is_not_joined_to_source_folder() -> void:
	var text := """TITLE:Absolute Wave
WAVE:res://tests/fixtures/tja/basic_notes.tja
#START
1,
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text, "res://tests/fixtures/tja/absolute_wave_probe.tja")
	var codes: Array[String] = []
	for diagnostic in chart.diagnostics:
		codes.append(String(diagnostic.code))
	_assert(not codes.has("missing_audio"), "Existing absolute WAVE path should not be joined to source folder")


func _test_branch_lane_unterminated_long_note_diagnostic() -> void:
	var text := """TITLE:Branch Unterminated Roll
BPM:120
#START
#BRANCHSTART p,50,90
#N
1000,
#E
5000,
#M
1000,
#BRANCHEND
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text)
	var codes: Array[String] = []
	for diagnostic in chart.diagnostics:
		codes.append(String(diagnostic.code))
	_assert(codes.has("unterminated_long_note"), "Unterminated long note inside branch lanes should be preserved on parent chart")


func _test_parse_courses_text_returns_each_course() -> void:
	var text := """TITLE:Multi Course
WAVE:multi.ogg
BPM:120
COURSE:Easy
LEVEL:2
#START
1000,
#END

COURSE:Hard
LEVEL:6
#START
1200,
#END
"""

	var charts: Array = TjaParserScript.parse_courses_text(text)
	_assert(charts.size() == 2, "parse_courses_text should return every COURSE block in one TJA")
	if charts.size() < 2:
		return
	_assert(charts[0].title == "Multi Course", "First course should inherit global title")
	_assert(charts[0].wave == "multi.ogg", "First course should inherit global WAVE")
	_assert(charts[0].course == "Easy", "First course should preserve Easy metadata")
	_assert(charts[0].level == 2, "First course should preserve Easy level")
	_assert(charts[0].notes.size() == 1, "Easy course should parse its own notes")
	_assert(charts[1].title == "Multi Course", "Second course should inherit global title")
	_assert(charts[1].wave == "multi.ogg", "Second course should inherit global WAVE")
	_assert(charts[1].course == "Hard", "Second course should preserve Hard metadata")
	_assert(charts[1].level == 6, "Second course should preserve Hard level")
	_assert(charts[1].notes.size() == 2, "Hard course should parse its own notes")


func _test_parse_text_returns_first_course_for_compatibility() -> void:
	var text := """TITLE:Compat Multi
BPM:120
COURSE:Easy
LEVEL:1
#START
1000,
#END

COURSE:Oni
LEVEL:8
#START
2222,
#END
"""

	var chart: RefCounted = TjaParserScript.parse_text(text)
	_assert(chart.course == "Easy", "parse_text should keep returning the first course")
	_assert(chart.level == 1, "parse_text should keep first course metadata")
	_assert(chart.notes.size() == 1, "parse_text should not merge later courses")


func _test_parse_courses_text_keeps_between_course_metadata_local() -> void:
	var text := """TITLE:Local Metadata
WAVE:shared.ogg
BPM:120
COURSE:Easy
LEVEL:1
#START
1000,
#END

WAVE:hard.ogg
COURSE:Hard
LEVEL:6
#START
1000,
#END

COURSE:Oni
LEVEL:8
#START
1000,
#END
"""

	var charts: Array = TjaParserScript.parse_courses_text(text)
	_assert(charts.size() == 3, "parse_courses_text should parse all three courses")
	if charts.size() < 3:
		return
	_assert(charts[0].wave == "shared.ogg", "First course should use global WAVE")
	_assert(charts[1].wave == "hard.ogg", "Second course should use its local WAVE")
	_assert(charts[2].wave == "shared.ogg", "Third course should not inherit second course local WAVE")


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed_count += 1
		push_error("ASSERTION FAILED: " + message)
