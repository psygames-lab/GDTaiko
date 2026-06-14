extends SceneTree

const NoteLaneScript: GDScript = preload("res://scripts/gameplay/note_lane.gd")
const NoteModelScript: GDScript = preload("res://scripts/gameplay/note_model.gd")

var failed_count := 0


func _init() -> void:
	_test_pool_sprites()

	if failed_count == 0:
		print("PASS: NotePool")
		quit(0)
	else:
		push_error("FAIL: NotePool tests failed with %d assertion(s)." % failed_count)
		quit(1)


func _test_pool_sprites() -> void:
	var lane: Node2D = _new_lane()
	var first_batch: Array[Dictionary] = _new_notes(100, 0)
	lane.spawn_notes(first_batch)
	_assert(lane.get_child_count() == 100, "Spawning 100 notes should create 100 sprites")
	var first_instance_ids: Array[int] = []
	for note in first_batch:
		var sprite := lane.note_nodes[note["id"]] as Sprite2D
		_assert(sprite != null, "spawned sprite should be retrievable by id")
		first_instance_ids.append(sprite.get_instance_id())

	lane.clear_notes()
	var pooled: Variant = lane.get("pooled_sprites")
	_assert(pooled != null and pooled is Array, "cleared sprites should be tracked in pooled_sprites")
	_assert((pooled as Array).size() == 100, "Clearing should return 100 sprites to pool")
	for value in (pooled as Array):
		var pooled_sprite := value as Sprite2D
		_assert(not pooled_sprite.visible, "pooled notes should be hidden")

	var second_batch: Array[Dictionary] = _new_notes(100, 100)
	lane.spawn_notes(second_batch)
	_assert(lane.note_nodes.size() == 100, "Second spawn should fill active sprites back to 100")

	var reused_count := 0
	for note in second_batch:
		var sprite := lane.note_nodes[note["id"]] as Sprite2D
		_assert(sprite != null, "repurposed sprite should be retrievable by id")
		if first_instance_ids.has(sprite.get_instance_id()):
			reused_count += 1
	_assert(reused_count == 100, "Second spawn should reuse pooled note sprites")
	lane.queue_free()


func _new_lane() -> Node2D:
	var lane: Node2D = NoteLaneScript.new()
	lane.configure(_make_texture(Color.RED), _make_texture(Color.BLUE))
	return lane


func _new_notes(count: int, start_id: int) -> Array[Dictionary]:
	var notes: Array[Dictionary] = []
	for i in range(count):
		notes.append({
			"id": "note_%d" % (start_id + i),
			"lane": NoteModelScript.DON if i % 2 == 0 else NoteModelScript.KA,
			"time_sec": float(i),
			"state": NoteModelScript.PENDING,
		})
	return notes


func _make_texture(color: Color) -> Texture2D:
	var image: Image = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed_count += 1
		push_error("ASSERTION FAILED: " + message)
