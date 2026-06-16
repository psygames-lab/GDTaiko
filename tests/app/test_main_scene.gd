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
	_assert(scene.get_node_or_null("MenuPanel") is Panel, "Main menu should use a native themed panel")
	_assert(scene.get_node_or_null("BackgroundDim") is ColorRect, "Main menu should dim the busy background behind UI")
	var background := scene.get_node_or_null("Background") as TextureRect
	_assert(background != null and background.stretch_mode == TextureRect.STRETCH_SCALE, "Main menu background should scale the full image without cropping")
	_assert(background != null and background.expand_mode == TextureRect.EXPAND_IGNORE_SIZE, "Main menu background should ignore texture minimum size")
	_assert(background != null and background.size == Vector2(1280, 720), "Main menu background should fill the 1280x720 viewport")
	var panel := scene.get_node_or_null("MenuPanel") as Control
	_assert(panel != null and panel.size.x <= 560.0, "Main menu panel should stay compact")
	_assert(panel != null and panel.position.x >= 340.0, "Main menu panel should be centered with safe margins")
	_assert(panel != null and panel.modulate.a <= 0.9, "Main menu panel should blend with the background instead of sitting as an opaque card")
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
