extends SceneTree

var failed_count := 0


func _init() -> void:
	var packed_scene := preload("res://scenes/Main.tscn") as PackedScene
	var scene: Node = packed_scene.instantiate()

	_assert(scene != null, "Main scene should instantiate")
	_assert(scene.name == "Main", "Instantiated scene name should be Main")
	_assert(scene.get_script() != null, "Main node should have main.gd attached")
	scene.free()

	if failed_count == 0:
		print("PASS: MainScene")
		quit(0)
	else:
		push_error("FAIL: MainScene tests failed with %d assertion(s)." % failed_count)
		quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed_count += 1
		push_error("ASSERTION FAILED: " + message)
