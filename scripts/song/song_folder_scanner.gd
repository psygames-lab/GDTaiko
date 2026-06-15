extends RefCounted
class_name SongFolderScanner

const TjaParser := preload("res://scripts/chart/tja_parser.gd")
const SongEntry := preload("res://scripts/song/song_entry.gd")
const SongCourse := preload("res://scripts/song/song_course.gd")


static func scan(root_path: String) -> Array[SongEntry]:
	var songs: Array[SongEntry] = []
	var root := DirAccess.open(root_path)
	if root == null:
		return songs

	root.list_dir_begin()
	var folder_name := root.get_next()
	while folder_name != "":
		if root.current_is_dir() and not folder_name.begins_with("."):
			var entry := _scan_song_folder(root_path.path_join(folder_name))
			if entry != null:
				songs.append(entry)
		folder_name = root.get_next()
	root.list_dir_end()

	songs.sort_custom(func(a: SongEntry, b: SongEntry) -> bool: return a.title.naturalnocasecmp_to(b.title) < 0)
	return songs


static func _scan_song_folder(folder_path: String) -> SongEntry:
	var folder := DirAccess.open(folder_path)
	if folder == null:
		return null

	var entry := SongEntry.new()
	entry.folder_path = folder_path
	var tja_files: Array[String] = []
	folder.list_dir_begin()
	var file_name := folder.get_next()
	while file_name != "":
		if not folder.current_is_dir() and file_name.get_extension().to_lower() == "tja":
			tja_files.append(file_name)
		file_name = folder.get_next()
	folder.list_dir_end()
	tja_files.sort_custom(func(a: String, b: String) -> bool: return a.naturalnocasecmp_to(b) < 0)

	for tja_file in tja_files:
		var tja_path := folder_path.path_join(tja_file)
		var charts := TjaParser.parse_courses_file(tja_path)
		for chart_index in range(charts.size()):
			var chart = charts[chart_index]
			if entry.title == "":
				entry.title = chart.title
				entry.subtitle = chart.subtitle
				entry.genre = String(chart.metadata.get("GENRE", ""))
				entry.maker = String(chart.metadata.get("MAKER", ""))
				entry.preview_start_sec = String(chart.metadata.get("DEMOSTART", "0")).to_float()
				if chart.wave != "":
					entry.preview_audio_path = _resolve_wave_path(folder_path, chart.wave)
			var course := SongCourse.new()
			course.course = chart.course
			course.level = chart.level
			course.tja_path = tja_path
			course.course_index = chart_index
			if chart.wave != "":
				course.wave = _resolve_wave_path(folder_path, chart.wave)
				course.expected_audio_path = course.wave
				course.audio_missing = not FileAccess.file_exists(course.wave)
			entry.courses.append(course)

	if entry.courses.is_empty():
		return null
	return entry


static func _resolve_wave_path(folder_path: String, wave_path: String) -> String:
	if wave_path.begins_with("res://") or wave_path.begins_with("user://"):
		return wave_path
	return folder_path.path_join(wave_path)
