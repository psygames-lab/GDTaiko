extends Node2D
class_name HitEffects

const _TEXTURE_SIZE := 28
const _BASE_SCALE := Vector2(0.55, 0.55)
const _TARGET_SCALE := Vector2(0.95, 0.95)
const _BIG_BASE_SCALE := Vector2(0.74, 0.74)
const _BIG_TARGET_SCALE := Vector2(1.18, 1.18)
const _EFFECT_DURATION := 0.20

var circle_texture: Texture2D
var effects: Array[Node2D] = []


func spawn_hit(position: Vector2, judgment: String, note_kind: String = "") -> void:
	_spawn_effect(position, "hit", judgment, _judgment_color(judgment), note_kind)


func spawn_miss(position: Vector2) -> void:
	_spawn_effect(position, "miss", "miss", Color.FIREBRICK)


func _spawn_effect(position: Vector2, kind: String, judgment: String, color: Color, note_kind: String = "") -> void:
	if circle_texture == null:
		circle_texture = _make_circle_texture()

	var effect := Node2D.new()
	effect.name = "Effect_%s" % judgment
	effect.position = position
	effect.visible = true
	effect.scale = _BIG_BASE_SCALE if _is_big_note_kind(note_kind) else _BASE_SCALE
	effect.set_meta("effect_type", kind)
	effect.set_meta("judgment", judgment)
	effect.set_meta("note_kind", note_kind)

	var sprite := Sprite2D.new()
	sprite.texture = circle_texture
	sprite.modulate = Color(color.r, color.g, color.b, 1.0)
	effect.add_child(sprite)

	add_child(effect)
	effects.append(effect)

	var tween := create_tween()
	var target_scale := _BIG_TARGET_SCALE if _is_big_note_kind(note_kind) else _TARGET_SCALE
	tween.parallel().tween_property(effect, "scale", target_scale, _EFFECT_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "modulate", Color(color.r, color.g, color.b, 0.0), _EFFECT_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_remove_effect.bind(effect))


func _remove_effect(effect: Node) -> void:
	if effects.has(effect):
		effects.erase(effect)
	if is_instance_valid(effect):
		effect.queue_free()


func _judgment_color(judgment: String) -> Color:
	match judgment.to_lower():
		"perfect":
			return Color.FOREST_GREEN
		"good":
			return Color.GOLD
		"bad":
			return Color(0.0, 0.62, 1.0)
		_:
			return Color.WHITE


func _is_big_note_kind(note_kind: String) -> bool:
	return note_kind == "big_don" or note_kind == "big_ka"


func _make_circle_texture() -> Texture2D:
	var image := Image.create(_TEXTURE_SIZE, _TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center := Vector2(_TEXTURE_SIZE * 0.5, _TEXTURE_SIZE * 0.5)
	var radius := (_TEXTURE_SIZE * 0.45)

	for x in range(_TEXTURE_SIZE):
		for y in range(_TEXTURE_SIZE):
			if center.distance_to(Vector2(x + 0.5, y + 0.5)) <= radius:
				image.set_pixel(x, y, Color.WHITE)

	return ImageTexture.create_from_image(image)
