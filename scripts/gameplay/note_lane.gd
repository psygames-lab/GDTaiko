extends Node2D
class_name NoteLane

const HIT_X := 260.0
const SPAWN_X := 1180.0
const NOTE_Y := 180.0
const APPROACH_TIME_SEC := 2.0
const LANE_HEIGHT := 96.0
const TARGET_SIZE := 96

var note_nodes: Dictionary = {}
var don_texture: Texture2D
var ka_texture: Texture2D
var gogo_overlay: CanvasItem


func build_skin() -> void:
	if get_node_or_null("LaneBackground") != null:
		return

	var background := ColorRect.new()
	background.name = "LaneBackground"
	background.position = Vector2(HIT_X - 96.0, NOTE_Y - (LANE_HEIGHT * 0.5))
	background.size = Vector2(SPAWN_X - HIT_X + 160.0, LANE_HEIGHT)
	background.color = Color.html("#1b1b1b")
	background.z_index = -30
	add_child(background)

	gogo_overlay = ColorRect.new()
	gogo_overlay.name = "GogoOverlay"
	gogo_overlay.position = background.position
	gogo_overlay.size = background.size
	gogo_overlay.color = Color(0.96, 0.52, 0.12, 0.22)
	gogo_overlay.visible = false
	gogo_overlay.z_index = -20
	add_child(gogo_overlay)

	var target := Sprite2D.new()
	target.name = "HitTarget"
	target.texture = _make_target_texture()
	target.position = Vector2(HIT_X, NOTE_Y)
	target.z_index = -5
	add_child(target)

	var timing_line := ColorRect.new()
	timing_line.name = "TimingLine"
	timing_line.position = Vector2(HIT_X - 2.0, NOTE_Y - 72.0)
	timing_line.size = Vector2(4.0, 144.0)
	timing_line.color = Color(1.0, 1.0, 1.0, 0.85)
	timing_line.z_index = -4
	add_child(timing_line)


func set_gogo(enabled: bool) -> void:
	if gogo_overlay == null:
		return
	gogo_overlay.visible = enabled

func configure(don: Texture2D, ka: Texture2D) -> void:
	don_texture = don
	ka_texture = ka

func spawn_notes(notes: Array[Dictionary]) -> void:
	clear_notes()
	for note in notes:
		var sprite: Sprite2D = Sprite2D.new()
		sprite.texture = don_texture if String(note.get("lane", "don")) == "don" else ka_texture
		sprite.position = Vector2(SPAWN_X, NOTE_Y)
		add_child(sprite)
		note_nodes[String(note["id"])] = sprite

func clear_notes() -> void:
	for sprite in note_nodes.values():
		if is_instance_valid(sprite):
			(sprite as Node).queue_free()
	note_nodes.clear()

func update_notes(notes: Array[Dictionary], song_time_sec: float, timing_map: Variant = null) -> void:
	for note in notes:
		var id: String = String(note["id"])
		if not note_nodes.has(id):
			continue
		var sprite: Sprite2D = note_nodes[id]
		var scheduled: float = float(note.get("time_sec", 0.0))
		var scroll := 1.0
		if timing_map != null:
			scroll = float(timing_map.scroll_at(scheduled))
		var progress: float = clamp(1.0 - ((scheduled - song_time_sec) / (APPROACH_TIME_SEC / max(0.1, scroll))), 0.0, 1.25)
		sprite.position = Vector2(lerpf(SPAWN_X, HIT_X, progress), NOTE_Y)
		sprite.visible = String(note.get("state", "pending")) == "pending"


func _make_target_texture() -> Texture2D:
	var image := Image.create(TARGET_SIZE, TARGET_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center := Vector2(TARGET_SIZE * 0.5, TARGET_SIZE * 0.5)
	var outer_radius := TARGET_SIZE * 0.42
	var inner_radius := TARGET_SIZE * 0.31
	for x in range(TARGET_SIZE):
		for y in range(TARGET_SIZE):
			var distance := center.distance_to(Vector2(x, y))
			if distance <= outer_radius and distance >= inner_radius:
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, 0.9))
	return ImageTexture.create_from_image(image)
