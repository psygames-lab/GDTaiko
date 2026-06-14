extends RefCounted
class_name TjaParser

const TaikoChart := preload("res://scripts/chart/taiko_chart.gd")
const TjaTokenizer := preload("res://scripts/chart/tja_tokenizer.gd")
const ParseDiagnostic := preload("res://scripts/chart/parse_diagnostic.gd")


static func parse_file(path: String) -> TaikoChart:
	return parse_text(FileAccess.get_file_as_string(path), path)


static func parse_text(text: String, source_path: String = "") -> TaikoChart:
	var chart := TaikoChart.new()
	var in_chart := false
	var current_time := 0.0
	var current_bpm := chart.bpm
	var measure_index := 0
	var measure_numerator := 4.0
	var measure_denominator := 4.0
	var pending_measure_text := ""
	var active_long_note: Dictionary = {}
	var balloon_index := 0
	var active_branch: Dictionary = {}
	var active_branch_lane := ""
	var metadata_line_numbers := {}

	for token in TjaTokenizer.tokenize(text):
		var kind := String(token["kind"])
		match kind:
			"metadata":
				if not in_chart:
					_apply_metadata(chart, token, metadata_line_numbers)
					current_bpm = chart.bpm
			"command":
				var command := String(token["command"])
				var argument := String(token.get("argument", ""))
				var line_number := int(token.get("line_number", 0))
				if command == "START":
					in_chart = true
					current_time = 0.0
					current_bpm = chart.bpm
					measure_numerator = 4.0
					measure_denominator = 4.0
					measure_index = 0
					pending_measure_text = ""
					active_long_note.clear()
					balloon_index = 0
					active_branch.clear()
					active_branch_lane = ""
					chart.add_timing_event(0.0, "bpm", current_bpm)
				elif command == "END":
					break
				elif in_chart and not active_branch.is_empty() and not _is_branch_control_command(command):
					_add_diagnostic(
						chart,
						line_number,
						"unsupported_command",
						"Ignoring branch-internal command '#%s'; branch-local timing commands are not supported yet" % command
					)
				elif in_chart and command == "BRANCHSTART":
					active_branch = _new_branch_event(chart, argument, current_time, measure_index, balloon_index, line_number)
					active_branch_lane = "normal"
				elif in_chart and command == "N":
					if not active_branch.is_empty():
						active_branch_lane = "normal"
				elif in_chart and command == "E":
					if not active_branch.is_empty():
						active_branch_lane = "expert"
				elif in_chart and command == "M":
					if not active_branch.is_empty():
						active_branch_lane = "master"
				elif in_chart and command == "BRANCHEND":
					if not active_branch.is_empty():
						var result := _finish_branch(chart, active_branch)
						current_time = result["time_sec"]
						measure_index = result["measure_index"]
						balloon_index = result["balloon_index"]
						pending_measure_text = ""
						active_long_note.clear()
						active_branch.clear()
						active_branch_lane = ""
				elif in_chart and command == "BPMCHANGE":
					var next_bpm := _to_positive_float(argument)
					if next_bpm > 0.0:
						current_bpm = next_bpm
						chart.add_timing_event(current_time + chart.offset_sec, "bpm", current_bpm)
				elif in_chart and command == "GOGOSTART":
					chart.add_timing_event(current_time + chart.offset_sec, "gogo", true)
				elif in_chart and command == "GOGOEND":
					chart.add_timing_event(current_time + chart.offset_sec, "gogo", false)
				elif in_chart and command == "SCROLL":
					chart.add_timing_event(current_time + chart.offset_sec, "scroll", argument.to_float())
				elif in_chart and command == "MEASURE":
					var parts := argument.split("/")
					if parts.size() == 2:
						var measure_numer := _to_positive_float(parts[0])
						var measure_denom := _to_positive_float(parts[1])
						if measure_numer > 0.0 and measure_denom > 0.0:
							measure_numerator = measure_numer
							measure_denominator = measure_denom
							chart.add_timing_event(current_time + chart.offset_sec, "measure", argument)
						else:
							_add_diagnostic(chart, line_number, "invalid_metadata", "Invalid MEASURE value '%s'; ignoring" % argument)
					else:
						_add_diagnostic(chart, line_number, "invalid_metadata", "Invalid MEASURE value '%s'; ignoring" % argument)
				elif in_chart:
					_add_diagnostic(chart, line_number, "unsupported_command", "Unsupported command '#%s' at line %d; ignoring" % [command, line_number])
			"notes":
				if in_chart:
					var line_number := int(token.get("line_number", 0))
					if active_branch.is_empty():
						var result := _parse_notes_line(
							chart,
							String(token["text"]),
							current_time,
							current_bpm,
							measure_numerator,
							measure_denominator,
							measure_index,
							pending_measure_text,
							active_long_note,
							balloon_index,
							line_number
						)
						current_time = result["time_sec"]
						measure_index = result["measure_index"]
						pending_measure_text = result["pending_measure_text"]
						balloon_index = result["balloon_index"]
					else:
						_parse_branch_notes_line(
							active_branch,
							active_branch_lane,
							String(token["text"]),
							current_bpm,
							measure_numerator,
							measure_denominator,
							line_number
						)

	if active_long_note.has("index"):
		_add_diagnostic(
			chart,
			int(active_long_note.get("line_number", 0)),
			"unterminated_long_note",
			"Unterminated long note starting at line %d" % int(active_long_note.get("line_number", 0))
		)
	_add_missing_audio_diagnostic(chart, source_path, metadata_line_numbers)
	chart.sort_notes()
	return chart


static func _apply_metadata(chart: TaikoChart, token: Dictionary, metadata_line_numbers: Dictionary) -> void:
	var key := String(token["key"])
	var value := String(token["value"])
	var line_number := int(token.get("line_number", 0))
	var has_title := chart.metadata.has("TITLE")
	var has_subtitle := chart.metadata.has("SUBTITLE")
	chart.metadata[key] = value
	metadata_line_numbers[key] = line_number

	match key:
		"TITLE":
			chart.title = value
		"TITLEEN":
			if not has_title:
				chart.title = value
		"SUBTITLE":
			chart.subtitle = value
		"SUBTITLEEN":
			if not has_subtitle:
				chart.subtitle = value
		"BPM":
			var parsed_bpm := _to_positive_float(value)
			if parsed_bpm > 0.0:
				chart.bpm = parsed_bpm
			else:
				_add_diagnostic(chart, line_number, "invalid_metadata", "Invalid BPM value '%s'; using default %f" % [value, chart.bpm])
		"OFFSET":
			chart.offset_sec = value.to_float()
		"WAVE":
			chart.wave = value
		"COURSE":
			chart.course = value
		"LEVEL":
			chart.level = int(value)
		"BALLOON":
			chart.balloon_counts.clear()
			for part in value.split(","):
				var trimmed := part.strip_edges()
				if trimmed != "":
					chart.balloon_counts.append(int(trimmed))


static func _parse_notes_line(
	chart: TaikoChart,
	line: String,
	start_time: float,
	bpm: float,
	measure_numerator: float,
	measure_denominator: float,
	measure_index: int,
	pending_measure_text: String,
	active_long_note: Dictionary,
	balloon_index: int,
	line_number: int
) -> Dictionary:
	var current_time := start_time
	var measure_text := pending_measure_text

	for character in line:
		var value := String(character)
		if value == ",":
			var result := _parse_measure(
				chart,
				measure_text,
				current_time,
				bpm,
				measure_numerator,
				measure_denominator,
				measure_index,
				active_long_note,
				balloon_index,
				line_number
			)
			current_time = result["time_sec"]
			measure_index += 1
			balloon_index = result["balloon_index"]
			measure_text = ""
		else:
			measure_text += value

	return {
		"time_sec": current_time,
		"measure_index": measure_index,
		"pending_measure_text": measure_text,
		"balloon_index": balloon_index
	}


static func _parse_measure(
	chart: TaikoChart,
	measure_text: String,
	start_time: float,
	bpm: float,
	measure_numerator: float,
	measure_denominator: float,
	measure_index: int,
	active_long_note: Dictionary,
	balloon_index: int,
	line_number: int
) -> Dictionary:
	var slots := measure_text.length()
	if slots <= 0:
		return {
			"time_sec": start_time,
			"balloon_index": balloon_index
		}

	var beat_count := measure_numerator * (4.0 / measure_denominator)
	var measure_duration := beat_count * 60.0 / bpm
	var slot_duration := measure_duration / float(slots)

	for slot in range(slots):
		var note := measure_text[slot]
		var note_time := start_time + (slot_duration * float(slot)) + chart.offset_sec

		if note == "0":
			continue
		elif note == "1":
			chart.add_note(note_time, "don", "don", measure_index, slot)
		elif note == "2":
			chart.add_note(note_time, "ka", "ka", measure_index, slot)
		elif note == "5":
			var note_index := chart.notes.size()
			active_long_note.clear()
			chart.add_note(note_time, "roll", "roll_start", measure_index, slot, {"duration_sec": 0.0})
			active_long_note["index"] = note_index
			active_long_note["line_number"] = line_number
		elif note == "6":
			var note_index := chart.notes.size()
			active_long_note.clear()
			chart.add_note(note_time, "roll", "roll_big_start", measure_index, slot, {"duration_sec": 0.0})
			active_long_note["index"] = note_index
			active_long_note["line_number"] = line_number
		elif note == "7":
			var note_index := chart.notes.size()
			var required_hits := 0
			if balloon_index < chart.balloon_counts.size():
				required_hits = chart.balloon_counts[balloon_index]
			balloon_index += 1
			active_long_note.clear()
			chart.add_note(note_time, "balloon", "balloon_start", measure_index, slot, {
				"duration_sec": 0.0,
				"required_hits": required_hits
			})
			active_long_note["index"] = note_index
			active_long_note["line_number"] = line_number
		elif note == "8":
			if active_long_note.has("index"):
				var start_index := int(active_long_note["index"])
				if start_index >= 0 and start_index < chart.notes.size():
					chart.notes[start_index]["duration_sec"] = note_time - float(chart.notes[start_index]["time_sec"])
				active_long_note.clear()
		else:
			_add_diagnostic(chart, line_number, "unsupported_note", "Unsupported note character '%s' in measure %d" % [note, measure_index])

	return {
		"time_sec": start_time + measure_duration,
		"balloon_index": balloon_index
	}


static func _to_positive_float(value: String) -> float:
	if not value.is_valid_float():
		return 0.0
	return value.to_float()


static func _new_branch_event(
	chart: TaikoChart,
	argument: String,
	current_time: float,
	measure_index: int,
	balloon_index: int,
	line_number: int
) -> Dictionary:
	var condition := "normal"
	var expert_threshold := 0.0
	var master_threshold := 0.0
	var parts := argument.split(",", false)
	if parts.size() >= 1:
		condition = _branch_condition(String(parts[0]).strip_edges())
	if parts.size() >= 2:
		expert_threshold = String(parts[1]).strip_edges().to_float()
	if parts.size() >= 3:
		master_threshold = String(parts[2]).strip_edges().to_float()
	if condition == "":
		_add_diagnostic(chart, line_number, "branch_fallback", "Unsupported BRANCHSTART condition '%s'; using normal" % argument)
		condition = "normal"

	return {
		"time_sec": current_time + chart.offset_sec,
		"type": "branch_start",
		"condition": condition,
		"expert_threshold": expert_threshold,
		"master_threshold": master_threshold,
		"normal_notes": [],
		"expert_notes": [],
		"master_notes": [],
		"lane_states": {
			"normal": _new_branch_lane_state(chart, current_time, measure_index, balloon_index),
			"expert": _new_branch_lane_state(chart, current_time, measure_index, balloon_index),
			"master": _new_branch_lane_state(chart, current_time, measure_index, balloon_index),
		},
	}


static func _branch_condition(raw_condition: String) -> String:
	match raw_condition.to_lower():
		"p", "accuracy":
			return "accuracy"
		"s", "score":
			return "score"
		"r", "roll":
			return "roll"
		"", "n", "normal":
			return "normal"
	return ""


static func _new_branch_lane_state(
	chart: TaikoChart,
	current_time: float,
	measure_index: int,
	balloon_index: int
) -> Dictionary:
	var branch_chart := TaikoChart.new()
	branch_chart.offset_sec = chart.offset_sec
	branch_chart.balloon_counts.assign(chart.balloon_counts)
	return {
		"chart": branch_chart,
		"time_sec": current_time,
		"measure_index": measure_index,
		"pending_measure_text": "",
		"active_long_note": {},
		"balloon_index": balloon_index,
	}


static func _parse_branch_notes_line(
	active_branch: Dictionary,
	lane_name: String,
	line: String,
	current_bpm: float,
	measure_numerator: float,
	measure_denominator: float,
	line_number: int
) -> void:
	var lane_states: Dictionary = active_branch["lane_states"]
	var state: Dictionary = lane_states.get(lane_name, lane_states["normal"])
	var result := _parse_notes_line(
		state["chart"],
		line,
		float(state["time_sec"]),
		current_bpm,
		measure_numerator,
		measure_denominator,
		int(state["measure_index"]),
		String(state["pending_measure_text"]),
		state["active_long_note"],
		int(state["balloon_index"]),
		line_number
	)
	state["time_sec"] = result["time_sec"]
	state["measure_index"] = result["measure_index"]
	state["pending_measure_text"] = result["pending_measure_text"]
	state["balloon_index"] = result["balloon_index"]


static func _finish_branch(chart: TaikoChart, active_branch: Dictionary) -> Dictionary:
	var lane_states: Dictionary = active_branch["lane_states"]
	var normal_state: Dictionary = lane_states["normal"]
	var expert_state: Dictionary = lane_states["expert"]
	var master_state: Dictionary = lane_states["master"]
	var normal_chart: TaikoChart = normal_state["chart"]
	var expert_chart: TaikoChart = expert_state["chart"]
	var master_chart: TaikoChart = master_state["chart"]

	_finalize_branch_lane_long_note(normal_chart, normal_state)
	_finalize_branch_lane_long_note(expert_chart, expert_state)
	_finalize_branch_lane_long_note(master_chart, master_state)
	active_branch["normal_notes"] = _duplicate_notes(normal_chart.notes)
	active_branch["expert_notes"] = _duplicate_notes(expert_chart.notes)
	active_branch["master_notes"] = _duplicate_notes(master_chart.notes)
	active_branch.erase("lane_states")
	_merge_branch_diagnostics(chart, [normal_chart, expert_chart, master_chart])
	chart.branch_events.append(active_branch.duplicate(true))
	_append_notes_to_chart(chart, normal_chart.notes)

	return {
		"time_sec": normal_state["time_sec"],
		"measure_index": normal_state["measure_index"],
		"balloon_index": normal_state["balloon_index"],
	}


static func _duplicate_notes(notes: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for note in notes:
		result.append(note.duplicate(true))
	return result


static func _append_notes_to_chart(chart: TaikoChart, notes: Array[Dictionary]) -> void:
	for note in notes:
		var extra := note.duplicate(true)
		extra.erase("id")
		extra.erase("time_sec")
		extra.erase("lane")
		extra.erase("kind")
		extra.erase("measure_index")
		extra.erase("subdivision_index")
		extra.erase("state")
		chart.add_note(
			float(note["time_sec"]),
			String(note["lane"]),
			String(note["kind"]),
			int(note["measure_index"]),
			int(note["subdivision_index"]),
			extra
		)


static func _is_branch_control_command(command: String) -> bool:
	return command == "N" or command == "E" or command == "M" or command == "BRANCHEND"


static func _add_diagnostic(chart: TaikoChart, line_number: int, code: String, message: String, severity: String = "warning") -> void:
	chart.diagnostics.append(ParseDiagnostic.new(line_number, severity, code, message))
	chart.warnings.append(message)


static func _merge_branch_diagnostics(chart: TaikoChart, branch_charts: Array) -> void:
	for branch_chart: TaikoChart in branch_charts:
		for diagnostic in branch_chart.diagnostics:
			chart.diagnostics.append(diagnostic)
		for warning in branch_chart.warnings:
			chart.warnings.append(warning)


static func _add_missing_audio_diagnostic(chart: TaikoChart, source_path: String, metadata_line_numbers: Dictionary) -> void:
	if source_path == "" or chart.wave == "":
		return
	var audio_path := chart.wave
	if not _is_absolute_wave_path(chart.wave):
		audio_path = source_path.get_base_dir().path_join(chart.wave)
	if FileAccess.file_exists(audio_path) or ResourceLoader.exists(audio_path):
		return
	var line_number := 0
	if metadata_line_numbers.has("WAVE"):
		line_number = int(metadata_line_numbers["WAVE"])
	_add_diagnostic(chart, line_number, "missing_audio", "Missing audio file '%s'" % audio_path)


static func _finalize_branch_lane_long_note(branch_chart: TaikoChart, lane_state: Dictionary) -> void:
	var active_long_note: Dictionary = lane_state["active_long_note"]
	if not active_long_note.has("index"):
		return
	var line_number := int(active_long_note.get("line_number", 0))
	_add_diagnostic(
		branch_chart,
		line_number,
		"unterminated_long_note",
		"Unterminated long note starting at line %d" % line_number
	)


static func _is_absolute_wave_path(path: String) -> bool:
	return path.begins_with("res://") or path.begins_with("user://") or path.is_absolute_path()
