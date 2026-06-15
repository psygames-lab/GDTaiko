extends Node2D
class_name NoteLane

const HIT_X := 260.0
const SPAWN_X := 1180.0
const NOTE_Y := 292.0
const APPROACH_TIME_SEC := 2.0
const LANE_HEIGHT := 88.0
const TARGET_SIZE := 88
const TARGET_GLOW_SIZE := 108
const DRUM_X := 96.0
const DRUM_PAD_SIZE := 112
const DRUM_FACE_SIZE := 82
const NOTE_SCALE := 0.58
const DON_FEEDBACK_COLOR := "#ff6a3d"
const KA_FEEDBACK_COLOR := "#55d7ff"
const MISS_FEEDBACK_COLOR := "#7a7a7a"
const DEFAULT_DRUM_PAD_COLOR := "#7b2622"
const DEFAULT_DRUM_FACE_COLOR := "#f3d6a3"
const DEFAULT_HIT_TARGET_COLOR := "#b9bec4"

var active_sprites: Dictionary = {}
var pooled_sprites: Array[Sprite2D] = []
var note_nodes: Dictionary = {}:
	get():
		return active_sprites
	set(value):
		active_sprites = value
var don_texture: Texture2D
var ka_texture: Texture2D
var lane_panel: ColorRect
var lane_border: ColorRect
var lane_text_strip: ColorRect
var lane_background: ColorRect
var gogo_overlay: CanvasItem
var drum_pad: Sprite2D
var drum_face: Sprite2D
var hit_target: Sprite2D
var hit_target_ring: Sprite2D
var hit_target_glow: Sprite2D
var drum_pad_base_color := Color.html(DEFAULT_DRUM_PAD_COLOR)
var drum_face_base_color := Color.html(DEFAULT_DRUM_FACE_COLOR)
var hit_target_base_color := Color.html(DEFAULT_HIT_TARGET_COLOR)


func build_skin() -> void:
	if get_node_or_null("LaneBackground") != null:
		return

	var panel_position := Vector2(HIT_X - 90.0, NOTE_Y - (LANE_HEIGHT * 0.5))
	var panel_size := Vector2(SPAWN_X - HIT_X + 132.0, LANE_HEIGHT)

	lane_border = ColorRect.new()
	lane_border.name = "LaneBorder"
	lane_border.position = panel_position - Vector2(5.0, 5.0)
	lane_border.size = panel_size + Vector2(10.0, 34.0)
	lane_border.color = Color.html("#d1a45f")
	lane_border.z_index = -42
	add_child(lane_border)

	lane_panel = ColorRect.new()
	lane_panel.name = "LanePanel"
	lane_panel.position = panel_position
	lane_panel.size = panel_size + Vector2(0.0, 24.0)
	lane_panel.color = Color.html("#101317")
	lane_panel.z_index = -41
	add_child(lane_panel)

	lane_background = ColorRect.new()
	lane_background.name = "LaneBackground"
	lane_background.position = panel_position
	lane_background.size = panel_size
	lane_background.color = Color(0.04, 0.04, 0.05, 0.78)
	lane_background.z_index = -30
	add_child(lane_background)

	lane_text_strip = ColorRect.new()
	lane_text_strip.name = "LaneTextStrip"
	lane_text_strip.position = Vector2(panel_position.x, panel_position.y + LANE_HEIGHT)
	lane_text_strip.size = Vector2(panel_size.x, 24.0)
	lane_text_strip.color = Color.html("#2f3034")
	lane_text_strip.z_index = -29
	add_child(lane_text_strip)

	gogo_overlay = ColorRect.new()
	gogo_overlay.name = "GogoOverlay"
	gogo_overlay.position = lane_background.position
	gogo_overlay.size = lane_background.size
	gogo_overlay.color = Color(0.96, 0.52, 0.12, 0.22)
	gogo_overlay.visible = false
	gogo_overlay.z_index = -20
	add_child(gogo_overlay)

	drum_pad = Sprite2D.new()
	drum_pad.name = "DrumPad"
	drum_pad.texture = _make_circle_texture(DRUM_PAD_SIZE, 0.47, 0.0)
	drum_pad.position = Vector2(DRUM_X, NOTE_Y)
	drum_pad.modulate = drum_pad_base_color
	drum_pad.z_index = -10
	add_child(drum_pad)

	drum_face = Sprite2D.new()
	drum_face.name = "DrumFace"
	drum_face.texture = _make_circle_texture(DRUM_FACE_SIZE, 0.47, 0.0)
	drum_face.position = drum_pad.position
	drum_face.modulate = drum_face_base_color
	drum_face.z_index = -9
	add_child(drum_face)

	hit_target_glow = Sprite2D.new()
	hit_target_glow.name = "HitTargetGlow"
	hit_target_glow.texture = _make_circle_texture(TARGET_GLOW_SIZE, 0.48, 0.18)
	hit_target_glow.position = Vector2(HIT_X, NOTE_Y)
	hit_target_glow.modulate = Color(hit_target_base_color, 0.45)
	hit_target_glow.visible = false
	hit_target_glow.z_index = -7
	add_child(hit_target_glow)

	hit_target_ring = Sprite2D.new()
	hit_target_ring.name = "HitTargetRing"
	hit_target_ring.texture = _make_circle_texture(TARGET_SIZE, 0.44, 0.31)
	hit_target_ring.position = Vector2(HIT_X, NOTE_Y)
	hit_target_ring.modulate = hit_target_base_color
	hit_target_ring.z_index = -6
	add_child(hit_target_ring)

	hit_target = Sprite2D.new()
	hit_target.name = "HitTarget"
	hit_target.texture = _make_target_texture()
	hit_target.position = Vector2(HIT_X, NOTE_Y)
	hit_target.z_index = -5
	add_child(hit_target)

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
	if lane_panel != null:
		lane_panel.color = theme.lane_panel_color
	if lane_border != null:
		lane_border.color = theme.lane_border_color
	if lane_text_strip != null:
		lane_text_strip.color = theme.lane_text_strip_color
	if drum_pad != null:
		drum_pad.modulate = theme.drum_body_color
		drum_pad_base_color = theme.drum_body_color
	if drum_face != null:
		drum_face.modulate = theme.drum_face_color
		drum_face_base_color = theme.drum_face_color
	if hit_target_ring != null:
		hit_target_ring.modulate = theme.hit_target_color
		hit_target_base_color = theme.hit_target_color
	if hit_target_glow != null:
		hit_target_glow.modulate = Color(hit_target_base_color, 0.45)
	if gogo_overlay != null:
		gogo_overlay.color = Color(theme.gogo_color, 0.22)


func show_input_feedback(lane_name: String) -> void:
	set_meta("last_feedback_lane", lane_name)
	var face_color := drum_face_base_color
	var pad_color := drum_pad_base_color
	if lane_name == "don":
		face_color = Color.html(DON_FEEDBACK_COLOR)
	elif lane_name == "ka":
		pad_color = Color.html(KA_FEEDBACK_COLOR)
	elif lane_name == "miss":
		face_color = Color.html(MISS_FEEDBACK_COLOR)
		pad_color = Color.html(MISS_FEEDBACK_COLOR)
	if drum_pad != null:
		drum_pad.scale = Vector2(1.12, 1.12)
		drum_pad.modulate = pad_color
	if drum_face != null:
		drum_face.scale = Vector2(1.1, 1.1)
		drum_face.modulate = face_color
	if hit_target_glow != null:
		hit_target_glow.visible = true
		hit_target_glow.scale = Vector2(1.12, 1.12)
		hit_target_glow.modulate = Color(hit_target_base_color, 0.45)
	if hit_target_ring != null:
		hit_target_ring.scale = Vector2(1.08, 1.08)
		hit_target_ring.modulate = hit_target_base_color


func configure(don: Texture2D, ka: Texture2D) -> void:
	don_texture = don
	ka_texture = ka

func spawn_notes(notes: Array[Dictionary]) -> void:
	clear_notes()
	for note in notes:
		var sprite: Sprite2D = _acquire_sprite()
		sprite.texture = don_texture if String(note.get("lane", "don")) == "don" else ka_texture
		sprite.scale = Vector2(NOTE_SCALE, NOTE_SCALE)
		sprite.z_index = 2
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
				image.set_pixel(x, y, Color(hit_target_base_color, 0.92))
	return ImageTexture.create_from_image(image)


func _make_circle_texture(size: int, outer_factor: float, inner_factor: float) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center := Vector2(size * 0.5, size * 0.5)
	var outer_radius := size * outer_factor
	var inner_radius := size * inner_factor
	for x in range(size):
		for y in range(size):
			var distance := center.distance_to(Vector2(x, y))
			if distance <= outer_radius and distance >= inner_radius:
				image.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(image)
