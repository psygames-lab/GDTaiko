extends SceneTree

const NoteModelScript: GDScript = preload("res://scripts/gameplay/note_model.gd")
const NoteLaneScript: GDScript = preload("res://scripts/gameplay/note_lane.gd")
const TimingMap := preload("res://scripts/chart/timing_map.gd")

var failed_count := 0


func _init() -> void:
	_test_model_constants()
	_test_spawn_notes()
	_test_update_notes_position()
	_test_update_notes_uses_scroll()
	_test_update_notes_visibility()
	_test_unknown_id_ignored()
	_test_clear_notes()

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
		_assert(child.is_queued_for_deletion(), "existing sprites should be marked for deletion after clear_notes")
	lane.queue_free()


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed_count += 1
		push_error("ASSERTION FAILED: " + message)
