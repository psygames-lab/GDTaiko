extends Node2D
class_name NoteLane

const HIT_X := 260.0
const SPAWN_X := 1180.0
const NOTE_Y := 180.0
const APPROACH_TIME_SEC := 2.0

var note_nodes: Dictionary = {}
var don_texture: Texture2D
var ka_texture: Texture2D

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
	for child in get_children():
		child.queue_free()
	note_nodes.clear()

func update_notes(notes: Array[Dictionary], song_time_sec: float) -> void:
	for note in notes:
		var id: String = String(note["id"])
		if not note_nodes.has(id):
			continue
		var sprite: Sprite2D = note_nodes[id]
		var scheduled: float = float(note.get("time_sec", 0.0))
		var progress: float = clamp(1.0 - ((scheduled - song_time_sec) / APPROACH_TIME_SEC), 0.0, 1.25)
		sprite.position = Vector2(lerpf(SPAWN_X, HIT_X, progress), NOTE_Y)
		sprite.visible = String(note.get("state", "pending")) == "pending"
