extends SceneTree

const NoteModelScript: GDScript = preload("res://scripts/gameplay/note_model.gd")
const NoteLaneScript: GDScript = preload("res://scripts/gameplay/note_lane.gd")
const TimingMap := preload("res://scripts/chart/timing_map.gd")
const TaikoTheme := preload("res://scripts/theme/taiko_theme.gd")

var failed_count := 0


func _init() -> void:
	_test_model_constants()
	_test_spawn_notes()
	_test_update_notes_position()
	_test_update_notes_uses_scroll()
	_test_update_notes_visibility()
	_test_unknown_id_ignored()
	_test_clear_notes()
	_test_build_skin_elements()
	_test_gogo_overlay_visibility()
	_test_theme_applies_to_lane_skin()
	_test_input_feedback_updates_skin_state()

	if failed_count == 0:
		print("PASS: NoteLane")
		quit(0)
	else:
		push_error("FAIL: NoteLane tests failed with %d assertion(s)." % failed_count)
		quit(1)


func _new_lane() -> Node2D:
	var lane: Node2D = NoteLaneScript.new()
	lane.configure(_make_texture(Color.RED), _make_texture(Color.BLUE))
	return lane


func _make_texture(color: Color) -> Texture2D:
	var image: Image = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


func _new_notes() -> Array[Dictionary]:
	return [
		{"id": "don_a", "lane": NoteModelScript.DON, "time_sec": 2.5, "state": NoteModelScript.PENDING},
		{"id": "ka_a", "lane": NoteModelScript.KA, "time_sec": 3.0, "state": NoteModelScript.PENDING},
	]


func _test_model_constants() -> void:
	_assert(NoteModelScript.DON == "don", "NoteModel.DON should be \"don\"")
	_assert(NoteModelScript.KA == "ka", "NoteModel.KA should be \"ka\"")
	_assert(NoteModelScript.PENDING == "pending", "NoteModel.PENDING should be \"pending\"")
	_assert(NoteModelScript.HIT == "hit", "NoteModel.HIT should be \"hit\"")
	_assert(NoteModelScript.MISSED == "missed", "NoteModel.MISSED should be \"missed\"")


func _test_spawn_notes() -> void:
	var lane: Node2D = _new_lane()
	var notes: Array[Dictionary] = _new_notes()
	var don_texture: Texture2D = _make_texture(Color.RED)
	var ka_texture: Texture2D = _make_texture(Color.BLUE)
	lane.configure(don_texture, ka_texture)
	lane.spawn_notes(notes)

	_assert(lane.get_child_count() == 2, "spawn_notes should add one sprite per note")
	_assert(lane.note_nodes.has("don_a"), "note_nodes should include don note id")
	_assert(lane.note_nodes.has("ka_a"), "note_nodes should include ka note id")
	_assert(
		(lane.note_nodes["don_a"] as Sprite2D).texture == don_texture,
		"don lane note should use don texture"
	)
	_assert(
		(lane.note_nodes["ka_a"] as Sprite2D).texture == ka_texture,
		"ka lane note should use ka texture"
	)
	_assert(
		(lane.note_nodes["don_a"] as Sprite2D).position == Vector2(NoteLaneScript.SPAWN_X, NoteLaneScript.NOTE_Y),
		"spawned note should start at SPAWN_X"
	)
	_assert(
		(lane.note_nodes["ka_a"] as Sprite2D).position == Vector2(NoteLaneScript.SPAWN_X, NoteLaneScript.NOTE_Y),
		"second spawned note should also start at SPAWN_X"
	)
	_assert(
		is_equal_approx((lane.note_nodes["don_a"] as Sprite2D).scale.x, NoteLaneScript.NOTE_SCALE),
		"spawned note should use the lane note scale"
	)
	lane.queue_free()


func _test_update_notes_position() -> void:
	var lane: Node2D = _new_lane()
	lane.spawn_notes(_new_notes())

	var notes: Array[Dictionary] = _new_notes()
	lane.update_notes(notes, 0.5)
	_assert(
		is_equal_approx((lane.note_nodes["don_a"] as Sprite2D).position.x, NoteLaneScript.SPAWN_X),
		"note at 2.0s away should remain at spawn x"
	)

	notes[0]["time_sec"] = 0.5
	notes[1]["time_sec"] = 0.5
	lane.update_notes(notes, 0.5)
	_assert(
		is_equal_approx((lane.note_nodes["don_a"] as Sprite2D).position.x, NoteLaneScript.HIT_X),
		"note at matching time should be at hit x"
	)

	notes[0]["time_sec"] = 0.5
	notes[0]["state"] = NoteModelScript.PENDING
	lane.update_notes(notes, 1.0)
	var after_x: float = NoteLaneScript.SPAWN_X + (NoteLaneScript.HIT_X - NoteLaneScript.SPAWN_X) * 1.25
	_assert(
		is_equal_approx((lane.note_nodes["don_a"] as Sprite2D).position.x, after_x),
		"late note should pass beyond hit x"
	)
	_assert(
		is_equal_approx((lane.note_nodes["don_a"] as Sprite2D).position.y, NoteLaneScript.NOTE_Y),
		"note y should stay fixed"
	)
	lane.queue_free()


func _test_update_notes_uses_scroll() -> void:
	var lane: Node2D = _new_lane()
	lane.spawn_notes(_new_notes())

	var notes: Array[Dictionary] = _new_notes()
	lane.update_notes(notes, 2.0)
	var default_x := (lane.note_nodes["don_a"] as Sprite2D).position.x

	var map := TimingMap.new()
	map.add_event(0.0, "scroll", 2.0)
	lane.update_notes(notes, 2.0, map)
	_assert(
		(lane.note_nodes["don_a"] as Sprite2D).position.x > default_x,
		"scroll 2.0 should keep a not-yet-due note closer to spawn than default scroll"
	)
	lane.queue_free()


func _test_update_notes_visibility() -> void:
	var lane: Node2D = _new_lane()
	var notes: Array[Dictionary] = [
		{"id": "don_a", "lane": NoteModelScript.DON, "time_sec": 1.0, "state": NoteModelScript.PENDING},
		{"id": "ka_a", "lane": NoteModelScript.KA, "time_sec": 1.0, "state": NoteModelScript.HIT},
	]
	lane.spawn_notes(notes)

	lane.update_notes(notes, 1.0)
	_assert(
		(lane.note_nodes["don_a"] as Sprite2D).visible,
		"pending notes should remain visible"
	)
	_assert(
		not (lane.note_nodes["ka_a"] as Sprite2D).visible,
		"non-pending notes should be hidden"
	)
	lane.queue_free()


func _test_unknown_id_ignored() -> void:
	var lane: Node2D = _new_lane()
	lane.spawn_notes(_new_notes())

	var stale_count: int = lane.note_nodes.size()
	var update_batch: Array[Dictionary] = [
		{"id": "missing", "lane": NoteModelScript.DON, "time_sec": 2.5, "state": NoteModelScript.PENDING},
	]
	var stale_don_x: float = (lane.note_nodes["don_a"] as Sprite2D).position.x
	lane.update_notes(update_batch, 2.5)
	_assert(lane.note_nodes.size() == stale_count, "unknown note ids should be ignored in update_notes")
	_assert(
		is_equal_approx((lane.note_nodes["don_a"] as Sprite2D).position.x, stale_don_x),
		"known notes should keep position when unknown ids are provided"
	)

	lane.queue_free()


func _test_clear_notes() -> void:
	var lane: Node2D = _new_lane()
	lane.spawn_notes(_new_notes())
	_assert(lane.note_nodes.size() == 2, "notes should be tracked before clear_notes")
	_assert(lane.get_child_count() == 2, "sprites should exist before clear_notes")

	lane.clear_notes()
	_assert(lane.note_nodes.size() == 0, "note_nodes should be empty after clear_notes")
	for child in lane.get_children():
		if child is Sprite2D:
			_assert(not child.visible, "existing note sprites should be hidden after clear_notes")
	lane.queue_free()


func _test_build_skin_elements() -> void:
	var lane: Node2D = _new_lane()
	lane.build_skin()

	_assert(lane.get_node_or_null("LaneBackground") != null, "Lane skin should include a background band")
	_assert(lane.get_node_or_null("LanePanel") != null, "Lane skin should include a themed panel")
	_assert(lane.get_node_or_null("LaneBorder") != null, "Lane skin should include a panel border")
	_assert(lane.get_node_or_null("LaneTextStrip") != null, "Lane skin should include a bottom text strip")
	_assert(lane.get_node_or_null("DrumPad") != null, "Lane skin should include a left drum pad")
	_assert(lane.get_node_or_null("DrumFace") != null, "Lane skin should include a drum face")
	_assert(lane.get_node_or_null("HitTarget") != null, "Lane skin should include a hit target")
	_assert(lane.get_node_or_null("HitTargetRing") != null, "Lane skin should include a target ring")
	_assert(lane.get_node_or_null("HitTargetGlow") != null, "Lane skin should include a target glow")
	_assert(lane.get_node_or_null("TimingLine") != null, "Lane skin should include a timing line")
	_assert(lane.get_node_or_null("GogoOverlay") != null, "Lane skin should include a GOGO overlay")
	_assert(NoteLaneScript.NOTE_Y >= 260.0 and NoteLaneScript.NOTE_Y <= 320.0, "Note lane should sit in the upper gameplay band")
	var lane_background := lane.get_node("LaneBackground") as ColorRect
	_assert(lane_background.size.y <= 92.0, "Lane background should not dominate the stage")
	var drum_pad := lane.get_node("DrumPad") as Sprite2D
	var target_glow := lane.get_node("HitTargetGlow") as Sprite2D
	var drum_right := drum_pad.position.x + (drum_pad.texture.get_width() * drum_pad.scale.x * 0.5)
	var target_left := target_glow.position.x - (target_glow.texture.get_width() * target_glow.scale.x * 0.5)
	_assert(drum_right + 18.0 <= target_left, "Drum pad should not overlap the judgment target area")
	_assert(lane.get_child_count() >= 9, "Building skin before notes should add themed skin nodes")
	lane.queue_free()


func _test_gogo_overlay_visibility() -> void:
	var lane: Node2D = _new_lane()
	lane.build_skin()
	var overlay := lane.get_node("GogoOverlay") as CanvasItem

	_assert(not overlay.visible, "GOGO overlay should start hidden")
	lane.set_gogo(true)
	_assert(overlay.visible, "GOGO overlay should show when enabled")
	lane.set_gogo(false)
	_assert(not overlay.visible, "GOGO overlay should hide when disabled")
	lane.queue_free()


func _test_theme_applies_to_lane_skin() -> void:
	var lane: Node2D = _new_lane()
	lane.build_skin()
	var theme = TaikoTheme.new()
	theme.lane_color = Color.html("#111111")
	theme.gogo_color = Color.html("#222222")
	theme.lane_panel_color = Color.html("#010203")
	theme.lane_border_color = Color.html("#040506")
	theme.lane_text_strip_color = Color.html("#070809")
	theme.drum_body_color = Color.html("#101112")
	theme.drum_face_color = Color.html("#131415")
	theme.hit_target_color = Color.html("#161718")
	lane.apply_theme(theme)

	_assert((lane.get_node("LanePanel") as ColorRect).color == Color.html("#010203"), "Theme should apply lane panel color")
	_assert((lane.get_node("LaneBorder") as ColorRect).color == Color.html("#040506"), "Theme should apply lane border color")
	_assert((lane.get_node("LaneTextStrip") as ColorRect).color == Color.html("#070809"), "Theme should apply text strip color")
	_assert((lane.get_node("DrumPad") as Sprite2D).modulate == Color.html("#101112"), "Theme should apply drum body color")
	_assert((lane.get_node("DrumFace") as Sprite2D).modulate == Color.html("#131415"), "Theme should apply drum face color")
	_assert((lane.get_node("HitTargetRing") as Sprite2D).modulate == Color.html("#161718"), "Theme should apply hit target color")
	lane.queue_free()


func _test_input_feedback_updates_skin_state() -> void:
	var lane: Node2D = _new_lane()
	lane.build_skin()

	lane.show_input_feedback(NoteModelScript.DON)
	_assert(lane.get_meta("last_feedback_lane", "") == NoteModelScript.DON, "Don feedback should record feedback lane")
	_assert((lane.get_node("DrumPad") as Sprite2D).scale.x > 1.0, "Don feedback should pulse drum pad")
	_assert((lane.get_node("DrumFace") as Sprite2D).modulate == Color.html("#ff6a3d"), "Don feedback should tint drum face red")
	_assert((lane.get_node("HitTargetGlow") as CanvasItem).visible, "Don feedback should show target glow")

	lane.show_input_feedback(NoteModelScript.KA)
	_assert((lane.get_node("DrumFace") as Sprite2D).modulate == Color.html("#55d7ff"), "Ka feedback should tint drum face blue")

	lane.show_input_feedback("miss")
	_assert(lane.get_meta("last_feedback_lane", "") == "miss", "Miss feedback should record miss state")
	_assert((lane.get_node("HitTargetGlow") as CanvasItem).visible, "Miss feedback should still show target glow")
	lane.queue_free()


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed_count += 1
		push_error("ASSERTION FAILED: " + message)
