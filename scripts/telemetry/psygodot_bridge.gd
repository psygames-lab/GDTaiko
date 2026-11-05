extends Node

const Gameplay := preload("res://scripts/gameplay/gameplay_controller.gd")
const Runtime := preload("res://addons/psygodot/psych_runtime.gd")

var runtime: Node
var config := {
	"game_name": "gdtaiko",
	"study_id": "gdtaiko",
	"participant_label": "local",
	"output_dir": "user://psygodot",
	"capture_input": false,
}


func _ready() -> void:
	if OS.get_cmdline_user_args().has("--psygodot"):
		get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node is Gameplay:
		attach(node)


func attach(controller: Node, session_config: Dictionary = {}) -> void:
	config.merge(session_config, true)
	if runtime == null:
		runtime = Runtime.new()
		add_child(runtime)
	controller.game_event.connect(_on_game_event)


func _on_game_event(tag: String, payload: Dictionary, timestamp_usec: int) -> void:
	if tag == "song_start":
		var session_config := config.duplicate(true)
		session_config["metadata"] = payload
		runtime.start_session(session_config)
		# The chart is stored once in the manifest, not repeated in the event stream.
		# Session creation precedes the first row; retain the original observation
		# separately because it was captured before the session clock started.
		runtime.log_event("gameplay", tag, {"observed_timestamp_usec": timestamp_usec})
	else:
		runtime.log_event("gameplay", tag, payload, timestamp_usec)
		if tag == "song_end":
			runtime.end_session(String(payload["reason"]))


func get_statistics() -> Dictionary:
	return runtime.get_statistics() if runtime != null else {}


func shutdown() -> void:
	if runtime != null:
		runtime.shutdown()


func _exit_tree() -> void:
	shutdown()
