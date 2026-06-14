extends SceneTree

const HitEffectsScript := preload("res://scripts/gameplay/hit_effects.gd")

var failed_count := 0


func _init() -> void:
	_test_spawns_hit_and_miss_effects()

	if failed_count == 0:
		print("PASS: HitEffects")
		quit(0)
	else:
		push_error("FAIL: HitEffects tests failed with %d assertion(s)." % failed_count)
		quit(1)


func _test_spawns_hit_and_miss_effects() -> void:
	var hit_effects := HitEffectsScript.new() as Node2D
	get_root().add_child(hit_effects)

	_assert(hit_effects.effects.is_empty(), "HitEffects should start with no active effects")

	hit_effects.spawn_hit(Vector2(10, 20), "perfect")
	hit_effects.spawn_miss(Vector2(30, 40))

	var hit_node := _find_effect(hit_effects.effects, "hit", "perfect")
	var miss_node := _find_effect(hit_effects.effects, "miss", "miss")

	_assert(hit_effects.get_child_count() == 2, "HitEffects should add one child per spawn")
	_assert(hit_effects.effects.size() == 2, "Effect tracker should contain both spawned effects")
	_assert(hit_node != null, "Hit effect should be tracked with hit metadata")
	_assert(miss_node != null, "Miss effect should be tracked with miss metadata")
	if hit_node != null:
		_assert(hit_node.visible, "Hit effect node should be visible")
		_assert(hit_node.get_meta("judgment") == "perfect", "Hit effect should store the judgment")
		_assert(hit_node.get_meta("effect_type") == "hit", "Hit effect should store hit effect type")

	var hit_sprite := _sprite_from_effect(hit_node)
	var miss_sprite := _sprite_from_effect(miss_node)

	_assert(hit_sprite != null, "Hit effect should contain a Sprite2D")
	_assert(miss_sprite != null, "Miss effect should contain a Sprite2D")
	if hit_sprite != null and miss_sprite != null:
		_assert(hit_sprite.modulate != miss_sprite.modulate, "Hit and miss effects should use distinct colors")

	hit_effects.queue_free()


func _find_effect(effects: Array, kind: String, judgment: String) -> Node:
	for effect in effects:
		if effect.get_meta("effect_type", "") == kind and effect.get_meta("judgment", "") == judgment:
			return effect
	return null


func _sprite_from_effect(effect: Node) -> Sprite2D:
	if effect == null:
		return null
	if effect.get_child_count() == 0:
		return null
	return effect.get_child(0) as Sprite2D


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed_count += 1
		push_error("ASSERTION FAILED: " + message)
