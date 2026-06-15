extends Node2D
class_name NoteLane

const HIT_X := 260.0
const SPAWN_X := 1180.0
const NOTE_Y := 292.0
const APPROACH_TIME_SEC := 2.0
const LANE_HEIGHT := 88.0
const TARGET_SIZE := 88

var active_sprites: Dictionary = {}
var pooled_sprites: Array[Sprite2D] = []
var note_nodes: Dictionary = {}:
	get():
		return active_sprites
	set(value):
		active_sprites = value
var don_texture: Texture2D
var ka_texture: Texture2D
var lane_background: ColorRect
var gogo_overlay: CanvasItem


func build_skin() -> void:
	if get_node_or_null("LaneBackground") != null:
		return

	lane_background = ColorRect.new()
	lane_background.name = "LaneBackground"
	lane_background.position = Vector2(HIT_X - 90.0, NOTE_Y - (LANE_HEIGHT * 0.5))
	lane_background.size = Vector2(SPAWN_X - HIT_X + 132.0, LANE_HEIGHT)
	lane_background.color = Color(0.04, 0.04, 0.05, 0.78)
	lane_background.z_index = -30
	add_child(lane_background)

	gogo_overlay = ColorRect.new()
	gogo_overlay.name = "GogoOverlay"
	gogo_overlay.position = lane_background.position
	gogo_overlay.size = lane_background.size
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
	timing_line.position = Vector2(HIT_X - 2.0, NOTE_Y - 62.0)
	timing_line.size = Vector2(4.0, 124.0)
	timing_line.color = Color(1.0, 1.0, 1.0, 0.85)
	timing_line.z_index = -4
	add_child(timing_line)


func set_gogo(enabled: bool) -> void:
	if gogo_overlay == null:
		return
	gogo_overlay.visible = enabled


func apply_theme(theme: Variant) -> void:
	if lane_background != null:
		lane_background.color = theme.lane_color
	if gogo_overlay != null:
		gogo_overlay.color = Color(theme.gogo_color, 0.22)

func configure(don: Texture2D, ka: Texture2D) -> void:
	don_texture = don
	ka_texture = ka

func spawn_notes(notes: Array[Dictionary]) -> void:
	clear_notes()
	for note in notes:
		var sprite: Sprite2D = _acquire_sprite()
		sprite.texture = don_texture if String(note.get("lane", "don")) == "don" else ka_texture
		sprite.position = Vector2(SPAWN_X, NOTE_Y)
		sprite.visible = true
		if sprite.get_parent() != self:
			add_child(sprite)
		active_sprites[String(note["id"])] = sprite

func clear_notes() -> void:
	for sprite in active_sprites.values():
		if is_instance_valid(sprite):
			(sprite as Sprite2D).visible = false
			pooled_sprites.append(sprite)
	active_sprites.clear()

func update_notes(notes: Array[Dictionary], song_time_sec: float, timing_map: Variant = null) -> void:
	for note in notes:
		var id: String = String(note["id"])
		if not active_sprites.has(id):
			continue
		var sprite: Sprite2D = active_sprites[id]
		var scheduled: float = float(note.get("time_sec", 0.0))
		var scroll := 1.0
		if timing_map != null:
			scroll = float(timing_map.scroll_at(scheduled))
		var progress: float = clamp(1.0 - ((scheduled - song_time_sec) / (APPROACH_TIME_SEC / max(0.1, scroll))), 0.0, 1.25)
		sprite.position = Vector2(lerpf(SPAWN_X, HIT_X, progress), NOTE_Y)
		sprite.visible = String(note.get("state", "pending")) == "pending"


func _acquire_sprite() -> Sprite2D:
	if pooled_sprites.is_empty():
		return Sprite2D.new()
	var sprite: Sprite2D = pooled_sprites.pop_back()
	if is_instance_valid(sprite):
		return sprite
	return Sprite2D.new()

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
