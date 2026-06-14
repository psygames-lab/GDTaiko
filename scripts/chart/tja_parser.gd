extends RefCounted
class_name TjaParser

const TaikoChart := preload("res://scripts/chart/taiko_chart.gd")
const TjaTokenizer := preload("res://scripts/chart/tja_tokenizer.gd")


static func parse_file(path: String) -> TaikoChart:
	return parse_text(FileAccess.get_file_as_string(path))


static func parse_text(text: String) -> TaikoChart:
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

	for token in TjaTokenizer.tokenize(text):
		var kind := String(token["kind"])
		match kind:
			"metadata":
				if not in_chart:
					_apply_metadata(chart, token)
					current_bpm = chart.bpm
			"command":
				var command := String(token["command"])
				var argument := String(token.get("argument", ""))
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
					chart.add_timing_event(0.0, "bpm", current_bpm)
				elif command == "END":
					break
				elif in_chart and command == "BPMCHANGE":
					var next_bpm := _to_positive_float(argument)
					if next_bpm > 0.0:
						current_bpm = next_bpm
						chart.add_timing_event(current_time + chart.offset_sec, "bpm", current_bpm)
				elif in_chart and command == "GOGOSTART":
					chart.add_timing_event(current_time + chart.offset_sec, "gogo", true)
				elif in_chart and command == "GOGOEND":
					chart.add_timing_event(current_time + chart.offset_sec, "gogo", false)
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
							chart.warnings.append("Invalid MEASURE value '%s'; ignoring" % argument)
					else:
						chart.warnings.append("Invalid MEASURE value '%s'; ignoring" % argument)
			"notes":
				if in_chart:
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
						balloon_index
					)
					current_time = result["time_sec"]
					measure_index = result["measure_index"]
					pending_measure_text = result["pending_measure_text"]
					balloon_index = result["balloon_index"]

	chart.sort_notes()
	return chart


static func _apply_metadata(chart: TaikoChart, token: Dictionary) -> void:
	var key := String(token["key"])
	var value := String(token["value"])
	match key:
		"TITLE":
			chart.title = value
		"SUBTITLE":
			chart.subtitle = value
		"BPM":
			var parsed_bpm := _to_positive_float(value)
			if parsed_bpm > 0.0:
				chart.bpm = parsed_bpm
			else:
				chart.warnings.append("Invalid BPM value '%s'; using default %f" % [value, chart.bpm])
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
	balloon_index: int
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
				balloon_index
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
	balloon_index: int
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
		elif note == "6":
			var note_index := chart.notes.size()
			active_long_note.clear()
			chart.add_note(note_time, "roll", "roll_big_start", measure_index, slot, {"duration_sec": 0.0})
			active_long_note["index"] = note_index
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
		elif note == "8":
			if active_long_note.has("index"):
				var start_index := int(active_long_note["index"])
				if start_index >= 0 and start_index < chart.notes.size():
					chart.notes[start_index]["duration_sec"] = note_time - float(chart.notes[start_index]["time_sec"])
				active_long_note.clear()
		else:
			chart.warnings.append("Unsupported note character '%s' in measure %d" % [note, measure_index])

	return {
		"time_sec": start_time + measure_duration,
		"balloon_index": balloon_index
	}


static func _to_positive_float(value: String) -> float:
	if not value.is_valid_float():
		return 0.0
	return value.to_float()
