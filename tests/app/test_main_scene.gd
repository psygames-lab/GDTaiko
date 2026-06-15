extends SceneTree

var failed_count := 0


func _init() -> void:
	var packed_scene := preload("res://scenes/Main.tscn") as PackedScene
	var scene: Node = packed_scene.instantiate()

	_assert(scene != null, "Main scene should instantiate")
	_assert(scene.name == "Main", "Instantiated scene name should be Main")
	_assert(scene.get_script() != null, "Main node should have main.gd attached")
	scene._ready()
	_assert(scene.get_node_or_null("MenuPanel/MainMenu/PlayButton") != null, "Main menu should show a Play button")
	_assert(scene.get_node_or_null("MenuPanel/MainMenu/OptionsButton") != null, "Main menu should show an Options button")
	_assert(scene.get_node_or_null("MenuPanel") is TextureRect, "Main menu should use the generated UI panel texture")
	_assert(scene.get_node_or_null("BackgroundDim") is ColorRect, "Main menu should dim the busy background behind UI")
	var panel := scene.get_node_or_null("MenuPanel") as Control
	_assert(panel != null and panel.size.x <= 560.0, "Main menu panel should stay compact")
	_assert(panel != null and panel.position.x >= 340.0, "Main menu panel should be centered with safe margins")
	var menu := scene.get_node_or_null("MenuPanel/MainMenu") as VBoxContainer
	_assert(menu != null, "Main menu controls should live inside the menu panel")
	_assert(menu != null and menu.position.x >= 48.0, "Main menu content should have panel padding")
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
