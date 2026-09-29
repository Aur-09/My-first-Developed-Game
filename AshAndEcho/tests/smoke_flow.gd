extends SceneTree

const MAIN_SCENE := "res://scenes/main.tscn"
const GameUIScript = preload("res://scripts/game_ui.gd")
const MINIMUM_REACHABLE_TILES := 12

var failures := 0
var main_node: Node
var ui: GameUIScript


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load(MAIN_SCENE) as PackedScene
	_check(packed != null, "main scene resource loads")
	if packed == null:
		quit(1)
		return
	main_node = packed.instantiate()
	root.add_child(main_node)
	await process_frame
	await process_frame
	ui = main_node.game_ui

	_check(main_node.visible, "main scene root is editor-visible")
	_check(main_node.get_node("Arena").visible, "first arena is visible when opening main scene")
	_check(main_node.get_node("Lurna").visible, "fighters are visible when opening main scene")
	_check(main_node.mode == 0, "initial state is home")
	_check(ui.menu_title.text == "AUR09", "home screen uses the Aur09 title")
	_check(_has_mesh(main_node.get_node("Arena/FixedDeck")), "authored arena deck is present")
	_check(_has_mesh(main_node.get_node("Arena/TileGrid/Tile_0_0")), "authored floor tile is visible in scene")
	_check(_has_mesh(main_node.get_node("Lurna/CharacterModel/Face")), "authored human face is present")
	_check(_has_mesh(main_node.get_node("Lurna/CharacterModel/LeftEye")), "fighter eye geometry is present")
	_check(main_node.get_node("Lurna").fighter_name == "Lurna", "Lurna identity is preserved")
	_check(main_node.get_node("Nofia").fighter_name == "Nofia", "Nofia identity is preserved")
	_check(ui.find_child("PortraitLurna", true, false) != null, "home introduces Lurna with an original portrait")
	_check(ui.find_child("PortraitNofia", true, false) != null, "home introduces Nofia with an original portrait")
	var concept := ui.find_child("ProvidedConceptReference", true, false)
	_check(concept is TextureRect and concept.visible and (concept as TextureRect).texture != null, "title shows the supplied concept image as a moodboard")
	_check(ui.concept_caption.text.contains("NOT CANONICAL CHARACTER NAMES"), "moodboard is not treated as the canonical character roster")
	_check(not (concept as TextureRect).texture.resource_path.contains("sister"), "opening image is the supplied no-text concept")
	var lurna_sprite := main_node.get_node("Lurna/CharacterModel/SpritePlane") as MeshInstance3D
	var nofia_sprite := main_node.get_node("Nofia/CharacterModel/SpritePlane") as MeshInstance3D
	var lurna_material := lurna_sprite.material_override as ShaderMaterial
	var nofia_material := nofia_sprite.material_override as ShaderMaterial
	var lurna_texture := lurna_material.get_shader_parameter("albedo_tex") as Texture2D
	var nofia_texture := nofia_material.get_shader_parameter("albedo_tex") as Texture2D
	_check(lurna_texture != null and nofia_texture != null and lurna_texture.resource_path != nofia_texture.resource_path, "Lurna and Nofia use distinct crew artwork")
	_check(main_node.world_environment.environment == main_node.arena.stage_environment, "Ash Yard starts with its own stage environment")
	var floodline_scene := load("res://scenes/arenas/floodline.tscn") as PackedScene
	var floodline_preview := floodline_scene.instantiate() as BreakableArena
	_check(floodline_preview.visible, "Floodline scene opens visible on its own")
	_check(_has_mesh(floodline_preview.get_node("RiverSurface")), "Floodline has an authored river water plane")
	_check(_has_mesh(floodline_preview.get_node("RiverBridgeDeck")), "Floodline has a bridge over the river")
	_check(floodline_preview.stage_environment.background_mode == Environment.BG_SKY, "Floodline has a distinct procedural sky")
	_check(
		floodline_preview.get_node("StageWorldEnvironment").environment == floodline_preview.stage_environment,
		"Floodline scene carries its own editor preview environment"
	)
	floodline_preview.free()
	var house_scene := load("res://scenes/locations/old_home.tscn") as PackedScene
	var house_preview := house_scene.instantiate() as StoryLocation
	_check(house_preview.visible, "old-home scene opens visible on its own")
	_check(house_preview.get_node("StageWorldEnvironment").environment == house_preview.stage_environment, "old-home editor preview has its own environment")
	house_preview.free()
	var forest_scene := load("res://scenes/locations/emberwood.tscn") as PackedScene
	var forest_preview := forest_scene.instantiate() as StoryLocation
	_check(forest_preview.visible, "Emberwood scene opens visible on its own")
	_check(forest_preview.get_node("StageWorldEnvironment").environment == forest_preview.stage_environment, "Emberwood editor preview has its own environment")
	_check(forest_preview.find_children("Burning*", "Node3D", true, false).size() == 3, "Emberwood contains three authored persistent fire sources")
	_check(_has_mesh(forest_preview.get_node("BurningHearth/OuterFlame")), "fire sources have authored flame geometry")
	_check(forest_preview.get_node("BurningHearth/FireLight") is OmniLight3D, "fire sources include visible illumination")
	forest_preview.free()

	_send_key(KEY_ENTER)
	await process_frame
	await process_frame
	_check(main_node.mode == 1, "Begin opens instructions")
	_check(ui.button_named("BACK") != null, "instructions have a Back button")
	_send_key(KEY_DOWN)
	var focused_button := ui.get_viewport().gui_get_focus_owner() as Button
	_check(focused_button != null and focused_button.text == "BACK", "keyboard Down moves menu focus")
	_send_key(KEY_UP)
	focused_button = ui.get_viewport().gui_get_focus_owner() as Button
	_check(focused_button != null and focused_button.text == "START THE TUTORIAL", "keyboard Up restores the primary action")
	var dpad_down := InputEventJoypadButton.new()
	dpad_down.button_index = JOY_BUTTON_DPAD_DOWN
	dpad_down.pressed = true
	ui._input(dpad_down)
	focused_button = ui.get_viewport().gui_get_focus_owner() as Button
	_check(focused_button != null and focused_button.text == "BACK", "controller D-pad Down moves menu focus")
	var dpad_up := InputEventJoypadButton.new()
	dpad_up.button_index = JOY_BUTTON_DPAD_UP
	dpad_up.pressed = true
	ui._input(dpad_up)
	focused_button = ui.get_viewport().gui_get_focus_owner() as Button
	_check(focused_button != null and focused_button.text == "START THE TUTORIAL", "controller D-pad Up restores the primary action")
	var joy_a := InputEventJoypadButton.new()
	joy_a.button_index = JOY_BUTTON_A
	joy_a.pressed = true
	ui._input(joy_a)
	_check(main_node.mode == 2, "controller A activates the focused tutorial action")
	_check(main_node.mode == 2 and ui.tutorial_step == 0, "instructions open tutorial step one")
	_check(ui.button_named("BACK") != null, "first tutorial step has a persistent Back button")
	_check(ui.find_child("PortraitLurna", true, false).is_visible_in_tree(), "tutorial retains the Lurna portrait")
	await _click(ui.button_named("BACK"))
	_check(main_node.mode == 1, "tutorial Back returns to instructions")
	await _click(ui.button_named("BACK"))
	_check(main_node.mode == 0, "instructions Back returns to title")
	_send_key(KEY_ENTER)
	await process_frame
	await process_frame
	_check(main_node.mode == 1, "keyboard can reopen instructions after using Back")
	await _click(ui.button_named("START THE TUTORIAL"))
	for step in range(ui.TUTORIAL_STEPS.size()):
		_check(ui.button_named("BACK") != null, "tutorial step %d has a Back button" % (step + 1))
		if step < ui.TUTORIAL_STEPS.size() - 1:
			await _click(ui.button_named("CONTINUE"))
			_check(ui.tutorial_step == step + 1, "tutorial advances to step %d" % (step + 2))
	if ui.tutorial_step > 0:
		await _click(ui.button_named("BACK"))
		_check(ui.tutorial_step == ui.TUTORIAL_STEPS.size() - 2, "tutorial Back returns one step")
		await _click(ui.button_named("CONTINUE"))
		_check(ui.tutorial_step == ui.TUTORIAL_STEPS.size() - 1, "tutorial can advance again after using Back")
		await _click(ui.button_named("CONTINUE TO STORY"))
	_check(main_node.mode == 5, "tutorial completes into the story introduction")
	_check(ui.menu_body.text.contains("Lurna") and ui.menu_body.text.contains("Nofia"), "story introduction uses the renamed leads")
	_check(ui.button_named("BACK TO TUTORIAL") != null, "story introduction has a persistent Back button")
	_check(ui.find_child("PortraitNofia", true, false).is_visible_in_tree(), "story introduction shows Nofia's portrait")
	await _click(ui.button_named("BACK TO TUTORIAL"))
	_check(main_node.mode == 2 and ui.tutorial_step == ui.TUTORIAL_STEPS.size() - 1, "intro Back returns to the final tutorial step")
	await _click(ui.button_named("CONTINUE TO STORY"))
	await _click(ui.button_named("ENTER THE OLD HOUSE"))
	_check(main_node.mode == 7, "story introduction enters explorable old home")
	_check(main_node.old_home.visible and not main_node.arena.visible, "old-home story stage replaces combat arena")
	_check(main_node.world_environment.environment == main_node.old_home.stage_environment, "old-home stage environment is active")
	_check(ui.story_back_button.is_visible_in_tree(), "exploration keeps a persistent Back to Title button")
	await _click(ui.story_back_button)
	_check(main_node.mode == 0 and not main_node.old_home.visible, "story Back returns to title and closes the location")

	await _begin_skip_flow()
	_check(main_node.mode == 3 and main_node.round_number == 1, "house and forest exploration progress into round one")
	_check(main_node.arena.visible and not main_node.second_arena.visible, "round one selects Ash Yard")
	_check(main_node.arena.is_processing() and not main_node.second_arena.is_processing(), "only active arena processes collapses")

	_test_arena_traversal()
	_test_player_attack()
	var combat_back := ui.find_child("CombatBackButton", true, false) as Button
	_check(combat_back != null and combat_back.is_visible_in_tree(), "combat has a persistent pause/back control")
	await _click(combat_back)
	_check(main_node.mode == 6 and Engine.time_scale == 0.0, "pause freezes combat")
	_check(ui.button_named("BACK TO THE FIGHT") != null, "pause screen has a return-to-fight button")
	await _click(ui.button_named("BACK TO THE FIGHT"))
	_check(main_node.mode == 3 and Engine.time_scale == 1.0, "resume restores the fight")
	_send_key(KEY_ESCAPE)
	_check(main_node.mode == 6, "Escape opens the pause/back screen")
	await _click(ui.button_named("BACK TO TITLE"))
	_check(main_node.mode == 0, "pause Back returns to title")

	await _begin_skip_flow()
	_check(main_node.mode == 3 and main_node.round_number == 1, "tutorial Skip reaches round one through story intro")
	for fighter in main_node._fighters_for_team(1):
		fighter.health = 0.0
	main_node._check_for_result()
	_check(main_node.mode == 4, "round victory opens result screen")
	_check(ui.button_named("BACK TO TITLE") != null, "result screen has a persistent Back button")
	await _click(ui.button_named("CONTINUE TO LEVEL TWO"))
	_check(main_node.mode == 3 and main_node.round_number == 2, "result button advances into round two")
	_check(not main_node.arena.visible and main_node.second_arena.visible, "round two selects Floodline")
	_check(main_node.active_arena == main_node.second_arena, "combat logic uses selected arena")
	_check(not main_node.arena.is_processing() and main_node.second_arena.is_processing(), "inactive arena cannot damage round two")
	_check(main_node.world_environment.environment == main_node.second_arena.stage_environment, "round two activates its authored environment")
	_check(main_node.second_arena.get_node("RiverSurface").visible, "round two shows the river surface")
	_check(main_node.second_arena.get_node("StageWorldEnvironment").environment == null, "stage preview environment does not conflict at runtime")

	for fighter in main_node._fighters_for_team(1):
		fighter.health = 0.0
	main_node._check_for_result()
	await _click(ui.button_named("PLAY AGAIN"))
	_check(main_node.mode == 3 and main_node.round_number == 2, "play again restarts the final round")
	_check(main_node.get_node("Nofia").health > 0.0, "replay restores fighter health")
	for fighter in main_node._fighters_for_team(0):
		fighter.health = 0.0
	main_node._check_for_result()
	await _click(ui.button_named("BACK TO TITLE"))
	_check(main_node.mode == 0, "result Back returns to title")
	_check(main_node.arena.visible and not main_node.second_arena.visible, "home restores first stage")

	if failures == 0:
		print("PASS: UI navigation, story portraits/reference, tile traversal, combat hit, pause/back, stage progression")
		quit(0)
	else:
		push_error("%d smoke checks failed" % failures)
		quit(1)


func _test_arena_traversal() -> void:
	var battle_arena: BreakableArena = main_node.active_arena
	_check(battle_arena.tile_nodes.size() == 40, "arena exposes forty authored breakable tiles")
	var collapsed_count := 0
	for row in range(battle_arena.ROWS):
		for column in range(battle_arena.COLUMNS):
			if collapsed_count >= 28:
				break
			if battle_arena.collapse_tile(Vector2i(column, row)):
				collapsed_count += 1
			_check(battle_arena._remaining_floor_is_connected(), "tile pattern retains one connected walkable route")
	_check(collapsed_count >= 20, "heavy attacks can remove a substantial number of floor tiles")
	var route: Array[Vector3] = battle_arena.find_path(Vector3(-7, 0, 0), Vector3(7, 0, 0))
	_check(not route.is_empty(), "fighters can route between opposing sides after tile collapse")
	_check(route.size() > 2, "pathfinder routes around destroyed floor instead of crossing a gap")
	var safe_position: Vector3 = battle_arena.nearest_safe_position(Vector3(-7, 0, 0))
	_check(battle_arena.is_walkable(safe_position), "collapse fallback always relocates to safe floor")
	battle_arena.reset_tiles()
	_check(battle_arena.find_path(Vector3(-7, 0, 0), Vector3(7, 0, 0)).size() > 1, "arena reset restores an end-to-end route")

	var nofia: TeamFighter = main_node.get_node("Nofia")
	var lurna: TeamFighter = main_node.get_node("Lurna")
	main_node.get_node("Iona").health = 0.0
	main_node.get_node("Lurna").position = Vector3(-6.0, 0.0, 0.0)
	nofia.position = Vector3(6.0, 0.0, 0.0)
	var start_position := nofia.position
	main_node._update_ai_for_team(1, 0.2)
	_check(nofia.position.distance_to(start_position) > 0.01, "opponent AI makes progress toward a reachable target")
	_check(battle_arena.is_walkable(nofia.position), "AI does not step into a missing floor tile")
	for step in range(40):
		main_node._update_ai_for_team(1, 0.15)
	_check(main_node._flat_distance(nofia.position, lurna.position) <= 3.45, "opponent AI reaches attack range instead of getting stuck")
	_check(not battle_arena.find_path(nofia.position, lurna.position).is_empty(), "fighters retain an escape route after the AI closes distance")
	lurna.position = Vector3(-6.0, 0.0, -0.8)
	nofia.position = Vector3(-4.1, 0.0, 0.8)
	nofia.heavy_cooldown = 2.0
	nofia.attack_cooldown = 0.0
	nofia.attack_windup = 0.0
	var same_tile_distance: float = main_node._flat_distance(nofia.position, lurna.position)
	main_node._update_ai_for_team(1, 0.2)
	_check(main_node._flat_distance(nofia.position, lurna.position) < same_tile_distance, "AI closes distance when both fighters share one floor tile")
	for step in range(5):
		main_node._update_ai_for_team(1, 0.2)
	_check(main_node._flat_distance(nofia.position, lurna.position) <= main_node.BASIC_RANGE, "AI can enter basic-attack range within a shared tile")


func _test_player_attack() -> void:
	var lurna: TeamFighter = main_node.get_node("Lurna")
	var nofia: TeamFighter = main_node.get_node("Nofia")
	main_node.get_node("Iona").health = 0.0
	main_node.get_node("Kest").health = 0.0
	lurna.position = Vector3(0, 0, 0)
	nofia.position = Vector3(1.15, 0, 0)
	lurna.facing_left = false
	lurna.rotation.y = PI * 0.5
	nofia.health = nofia.max_health
	main_node.player_attack_cooldown = 0.0
	nofia.position = Vector3(4.0, 0.0, 0.0)
	var initial_health := nofia.health
	main_node._player_attack()
	_check(is_equal_approx(nofia.health, initial_health), "close-range strike does not hit outside attack range")
	main_node.player_attack_cooldown = 0.0
	nofia.position = Vector3(1.15, 0.0, 0.0)
	var attack := InputEventKey.new()
	attack.physical_keycode = KEY_J
	attack.keycode = KEY_J
	attack.pressed = true
	main_node._input(attack)
	_check(nofia.health < nofia.max_health, "close-range attack hits a nearby opposing fighter")
	_check(main_node.player_energy > 60.0, "a landed attack restores pulse energy")


func _begin_skip_flow() -> void:
	await _click(ui.button_named("BEGIN"))
	await _click(ui.button_named("START THE TUTORIAL"))
	await _click(ui.button_named("SKIP TUTORIAL"))
	_check(main_node.mode == 5, "Skip opens the story introduction")
	await _click(ui.button_named("ENTER THE OLD HOUSE"))
	_check(main_node.mode == 7 and main_node.old_home.visible, "story entry opens the navigable house")
	_check(main_node.fighters[0].position.distance_to(Vector3(-3.0, 0.0, 2.0)) < 0.01, "Lurna starts on a clear house path")
	for step in range(17):
		main_node._move_in_story(Vector3(0.0, 0.0, -1.0), 0.1)
	_check(main_node.fighters[0].position.z < -4.7, "Lurna can walk from the house start to its north door")
	_press_main_key(KEY_E)
	_check(main_node.mode == 8 and main_node.emberwood.visible, "door interaction transitions into Emberwood")
	_check(main_node.world_environment.environment == main_node.emberwood.stage_environment, "Emberwood activates its distinct environment")
	_check(main_node.emberwood.get_node("BurningHearth/FireLight").visible, "forest fire lighting remains present during exploration")
	for step in range(45):
		main_node._move_in_story(Vector3(0.0, 0.0, -1.0), 0.1)
	_check(main_node.fighters[0].position.z < -12.0, "Lurna can follow the open forest road to its exit")
	_press_main_key(KEY_E)
	_check(main_node.mode == 3, "forest exit interaction starts Ash Yard round one")


func _has_mesh(node: Node) -> bool:
	return node is MeshInstance3D and (node as MeshInstance3D).mesh != null


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error("FAIL: " + description)


func _click(button: Button) -> void:
	_check(button != null, "expected menu button exists")
	if button == null:
		return
	await process_frame
	button.pressed.emit()
	await process_frame


func _send_key(physical_key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = physical_key
	event.physical_keycode = physical_key
	event.pressed = true
	if ui.menu_active:
		ui._input(event)
	else:
		main_node._input(event)


func _press_main_key(physical_key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = physical_key
	event.physical_keycode = physical_key
	event.pressed = true
	main_node._input(event)
