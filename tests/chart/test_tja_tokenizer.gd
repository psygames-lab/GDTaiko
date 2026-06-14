extends SceneTree

const TjaTokenizerScript: GDScript = preload("res://scripts/chart/tja_tokenizer.gd")

var failed_count := 0


func _init() -> void:
	_test_sample_tokenization()
	_test_inline_comments_are_stripped()
	_test_metadata_key_uppercase()
	_test_metadata_url_value_keeps_double_slash()
	_test_note_line_stays_notes()
	_test_empty_key_colon_is_not_metadata()
	_test_tab_whitespace_command_argument()

	if failed_count == 0:
		print("PASS: TjaTokenizer")
		quit(0)
	else:
		push_error("FAIL: TjaTokenizer tests failed with %d assertion(s)." % failed_count)
		quit(1)


func _test_sample_tokenization() -> void:
	var text := "TITLE:Test Song\nBPM:150\n// comment\n#START\n0012,\n#BPMCHANGE 180\n1000,\n#END\n"
	var tokens: Array[Dictionary] = TjaTokenizerScript.tokenize(text)
	var expected := [
		{"kind": "metadata", "key": "TITLE", "value": "Test Song", "line_number": 1},
		{"kind": "metadata", "key": "BPM", "value": "150", "line_number": 2},
		{"kind": "command", "command": "START", "argument": "", "line_number": 4},
		{"kind": "notes", "text": "0012,", "line_number": 5},
		{"kind": "command", "command": "BPMCHANGE", "argument": "180", "line_number": 6},
		{"kind": "notes", "text": "1000,", "line_number": 7},
		{"kind": "command", "command": "END", "argument": "", "line_number": 8},
	]

	_assert(tokens.size() == expected.size(), "Sample tokenize should produce expected number of tokens")
	for i in range(min(tokens.size(), expected.size())):
		_assert(tokens[i] == expected[i], "Sample token %d should match expected value: %s" % [i, expected[i]])


func _test_inline_comments_are_stripped() -> void:
	var text := "BPM:150 // comment"
	var tokens: Array[Dictionary] = TjaTokenizerScript.tokenize(text)

	_assert(tokens.size() == 1, "Inline comment line should tokenize to a single metadata token")
	_assert(tokens[0] == {"kind": "metadata", "key": "BPM", "value": "150", "line_number": 1}, "BPM inline comments should be stripped and value preserved")


func _test_metadata_key_uppercase() -> void:
	var text := "title:Lowercase Key"
	var tokens: Array[Dictionary] = TjaTokenizerScript.tokenize(text)

	_assert(tokens.size() == 1, "Single metadata line should still tokenize")
	_assert(tokens[0]["key"] == "TITLE", "Metadata key should be uppercased")


func _test_metadata_url_value_keeps_double_slash() -> void:
	var text := "WAVE:res://tests/fixtures/tja/basic_notes.tja"
	var tokens: Array[Dictionary] = TjaTokenizerScript.tokenize(text)

	_assert(tokens.size() == 1, "Resource URL metadata should tokenize to one token")
	_assert(tokens[0]["value"] == "res://tests/fixtures/tja/basic_notes.tja", "Resource URL metadata should keep double slash")


func _test_note_line_stays_notes() -> void:
	var text := "0012,"
	var tokens: Array[Dictionary] = TjaTokenizerScript.tokenize(text)

	_assert(tokens.size() == 1, "A pure note line should produce one token")
	_assert(tokens[0] == {"kind": "notes", "text": "0012,", "line_number": 1}, "Note line should be tokenized as notes")


func _test_empty_key_colon_is_not_metadata() -> void:
	var text := ":value"
	var tokens: Array[Dictionary] = TjaTokenizerScript.tokenize(text)

	_assert(tokens.size() == 1, "Empty-key colon line should be a single token")
	_assert(tokens[0]["kind"] == "notes", "Empty-key colon line should not be metadata")


func _test_tab_whitespace_command_argument() -> void:
	var text := "#BPMCHANGE\t180"
	var tokens: Array[Dictionary] = TjaTokenizerScript.tokenize(text)

	_assert(tokens.size() == 1, "Tab-separated command line should produce one token")
	_assert(tokens[0]["command"] == "BPMCHANGE", "Tab-separated command should parse command token")
	_assert(tokens[0]["argument"] == "180", "Tab-separated command should parse argument token")


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed_count += 1
		push_error("ASSERTION FAILED: " + message)
