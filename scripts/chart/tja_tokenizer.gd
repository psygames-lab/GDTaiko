extends RefCounted
class_name TjaTokenizer


static func tokenize(text: String) -> Array[Dictionary]:
	var tokens: Array[Dictionary] = []
	var lines := text.split("\n")

	for line_index in range(lines.size()):
		var raw_line := String(lines[line_index])
		var line_number := line_index + 1
		var line := raw_line.strip_edges()

		if line == "":
			continue

		var comment_index := _comment_index(line)
		if comment_index == 0:
			continue
		if comment_index > 0:
			line = line.substr(0, comment_index).strip_edges()
			if line == "":
				continue

		if line.begins_with("#"):
			var command_line := line.substr(1)
			var separator_index := -1
			for i in range(command_line.length()):
				if command_line[i] == " " or command_line[i] == "\t":
					separator_index = i
					break
			if separator_index == -1:
				tokens.append({
					"kind": "command",
					"command": command_line.strip_edges().to_upper(),
					"argument": "",
					"line_number": line_number,
				})
			else:
				tokens.append({
					"kind": "command",
					"command": command_line.substr(0, separator_index).strip_edges().to_upper(),
					"argument": command_line.substr(separator_index + 1).strip_edges(),
					"line_number": line_number,
				})
			continue

		var separator_index := line.find(":")
		if separator_index > 0 and not _looks_like_note_line(line):
			var key := line.substr(0, separator_index).strip_edges().to_upper()
			var value := line.substr(separator_index + 1).strip_edges()
			tokens.append({
				"kind": "metadata",
				"key": key,
				"value": value,
				"line_number": line_number,
			})
			continue

		tokens.append({"kind": "notes", "text": line, "line_number": line_number})

	return tokens


static func _looks_like_note_line(line: String) -> bool:
	var has_comma := false

	for i in range(line.length()):
		match line[i]:
			"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", ",":
				pass
			_:
				return false

		if line[i] == ",":
			has_comma = true

	return has_comma


static func _comment_index(line: String) -> int:
	var index := line.find("//")
	while index >= 0:
		if index == 0 or line[index - 1] == " " or line[index - 1] == "\t":
			return index
		index = line.find("//", index + 2)
	return -1
