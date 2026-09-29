extends Node3D

enum GameMode { HOME, INSTRUCTIONS, TUTORIAL, FIGHT, RESULTS, INTRO, PAUSED, STORY_HOUSE, STORY_FOREST }

const TEAM_BLUE := Color(0.22, 0.60, 0.95)
const TEAM_RED := Color(0.90, 0.20, 0.15)
const GameUIScript = preload("res://scripts/game_ui.gd")
const MAX_ENERGY := 100.0
const PULSE_COST := 45.0
const MOVE_SPEED := 4.7
const BASIC_RANGE := 1.9
const PULSE_RANGE := 3.25
const BACKDROP_PATH := "res://assets/env/ash_sky.png"

var mode := GameMode.HOME
var round_number := 1
var player_energy := 60.0
var dash_cooldown := 0.0
var dash_timer := 0.0
var dash_direction := Vector3.ZERO
var player_attack_cooldown := 0.0
var elapsed := 0.0
var shake_strength := 0.0
var game_ui: GameUIScript
var active_arena: BreakableArena
const CAMERA_START := Vector3(0.0, 8.0, 18.0)
const CORE_RED := Color(1.0, 0.45, 0.15)
const CORE_BLUE := Color(0.25, 0.55, 0.95)

var camera_home := CAMERA_START
var camera_focus := Vector3(0.0, 0.0, -0.15)
var backdrop_node: MeshInstance3D

@onready var arena: BreakableArena = $Arena
@onready var second_arena: BreakableArena = $ArenaTwo
@onready var camera: Camera3D = $Camera3D
@onready var effects: ArenaEffects = $Effects
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var fighters: Array[TeamFighter] = [$Lurna, $Iona, $Nofia, $Kest]
@onready var old_home: StoryLocation = $OldHome
@onready var emberwood: StoryLocation = $Emberwood


func _ready() -> void:
	randomize()
	_ensure_input_actions()
	if get_window() != null:
		get_window().grab_focus()
	camera.look_at(Vector3(0.0, 0.0, -0.15), Vector3.UP)
	active_arena = arena
	arena.get_node("StageWorldEnvironment").environment = null
	second_arena.get_node("StageWorldEnvironment").environment = null
	old_home.get_node("StageWorldEnvironment").environment = null
	emberwood.get_node("StageWorldEnvironment").environment = null
	world_environment.environment = arena.stage_environment
	_enhance_environment(arena.stage_environment, Color(0.28, 0.12, 0.10))
	_enhance_environment(second_arena.stage_environment, Color(0.08, 0.16, 0.26))
	effects.start_embers()
	effects.spawn_core()
	effects.set_core_color(CORE_RED)
	_spawn_backdrop()
	arena.tile_fell.connect(_on_tile_fell)
	second_arena.tile_fell.connect(_on_tile_fell)
	second_arena.set_process(false)
	_set_location_processing(old_home, false)
	_set_location_processing(emberwood, false)
	for actor in fighters:
		actor.reset_fighter()
	game_ui = GameUIScript.new()
	game_ui.name = "GameUI"
	add_child(game_ui)
	game_ui.play_requested.connect(_show_instructions)
	game_ui.instructions_requested.connect(_show_instructions)
	game_ui.instructions_back_requested.connect(_show_home)
	game_ui.tutorial_back_requested.connect(_show_instructions)
	game_ui.tutorial_exit_requested.connect(_show_instructions)
	game_ui.tutorial_viewed.connect(_show_tutorial)
	game_ui.tutorial_start_requested.connect(_show_story_intro)
	game_ui.intro_back_requested.connect(_return_to_tutorial)
	game_ui.intro_start_requested.connect(_enter_old_house)
	game_ui.round_continue_requested.connect(_advance_to_second_round)
	game_ui.retry_requested.connect(_retry_round)
	game_ui.home_requested.connect(_return_home)
	game_ui.pause_requested.connect(_pause_fight)
	game_ui.resume_requested.connect(_resume_fight)
	arena.visible = true
	second_arena.visible = false
	old_home.visible = false
	emberwood.visible = false
	_show_home()


func _spawn_backdrop() -> void:
	if not ResourceLoader.exists(BACKDROP_PATH):
		return
	var texture: Texture2D = load(BACKDROP_PATH) as Texture2D
	if texture == null:
		return
	var quad := QuadMesh.new()
	quad.size = Vector2(60.0, 30.0)
	backdrop_node = MeshInstance3D.new()
	backdrop_node.name = "Backdrop"
	backdrop_node.mesh = quad
	backdrop_node.position = Vector3(0.0, 8.0, -34.0)
	backdrop_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission_texture = texture
	material.emission_energy_multiplier = 0.35
	backdrop_node.material_override = material
	add_child(backdrop_node)


func _set_backdrop_visible(show: bool) -> void:
	if backdrop_node != null:
		backdrop_node.visible = show


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if mode == GameMode.STORY_HOUSE or mode == GameMode.STORY_FOREST:
		if key.physical_keycode == KEY_ESCAPE:
			_return_home()
		elif key.physical_keycode == KEY_E:
			_try_story_interaction()
		return
	if mode != GameMode.FIGHT:
		return
	match key.physical_keycode:
		KEY_ESCAPE:
			_pause_fight()
		KEY_J, KEY_SPACE:
			_player_attack()
		KEY_SHIFT, KEY_K:
			_player_dash()
		KEY_E, KEY_L:
			_player_pulse()


func _process(delta: float) -> void:
	if mode == GameMode.STORY_HOUSE or mode == GameMode.STORY_FOREST:
		_release_gameplay_focus()
		_update_story_exploration(delta)
		return
	if mode != GameMode.FIGHT:
		return
	_release_gameplay_focus()
	elapsed += delta
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	dash_timer = maxf(0.0, dash_timer - delta)
	player_attack_cooldown = maxf(0.0, player_attack_cooldown - delta)
	shake_strength = move_toward(shake_strength, 0.0, 17.0 * delta)

	for actor in fighters:
		actor.attack_cooldown = maxf(0.0, actor.attack_cooldown - delta)
		actor.heavy_cooldown = maxf(0.0, actor.heavy_cooldown - delta)
		if actor.attack_windup > 0.0:
			actor.attack_windup -= delta
			if actor.attack_windup <= 0.0:
				_resolve_ai_attack(actor)

	_update_camera_focus(delta)
	_update_player(delta)
	_update_ai_for_team(0, delta)
	_update_ai_for_team(1, delta)
	_update_camera_shake()
	_update_ui()
	_check_for_result()


func _show_home() -> void:
	mode = GameMode.HOME
	_set_backdrop_visible(false)
	game_ui.show_home()


func _show_instructions() -> void:
	mode = GameMode.INSTRUCTIONS
	_set_backdrop_visible(false)
	game_ui.show_instructions()


func _show_tutorial() -> void:
	mode = GameMode.TUTORIAL
	_set_backdrop_visible(false)


func _show_story_intro() -> void:
	mode = GameMode.INTRO
	_set_backdrop_visible(false)
	game_ui.show_story_intro()


func _return_to_tutorial() -> void:
	mode = GameMode.TUTORIAL
	_set_backdrop_visible(false)
	game_ui.show_tutorial(game_ui.TUTORIAL_STEPS.size() - 1)


func _pause_fight() -> void:
	if mode != GameMode.FIGHT:
		return
	mode = GameMode.PAUSED
	Engine.time_scale = 0.0
	game_ui.show_pause()


func _resume_fight() -> void:
	if mode != GameMode.PAUSED:
		return
	Engine.time_scale = 1.0
	mode = GameMode.FIGHT
	game_ui.show_combat()


func _begin_first_round() -> void:
	round_number = 1
	arena.visible = true
	second_arena.visible = false
	old_home.visible = false
	emberwood.visible = false
	arena.set_process(true)
	second_arena.set_process(false)
	active_arena = arena
	_set_stage_lighting(1)
	effects.set_world_fx_enabled(true)
	_start_fight()


func _advance_to_second_round() -> void:
	round_number = 2
	arena.reset_tiles()
	arena.set_process(false)
	second_arena.set_process(true)
	arena.visible = false
	second_arena.visible = true
	active_arena = second_arena
	_set_stage_lighting(2)
	_start_fight()


func _retry_round() -> void:
	_start_fight()


func _return_home() -> void:
	arena.reset_tiles()
	second_arena.reset_tiles()
	arena.visible = true
	second_arena.visible = false
	old_home.visible = false
	emberwood.visible = false
	_set_location_processing(old_home, false)
	_set_location_processing(emberwood, false)
	arena.set_process(true)
	second_arena.set_process(false)
	active_arena = arena
	_set_stage_lighting(1)
	effects.set_world_fx_enabled(true)
	Engine.time_scale = 1.0
	for actor in fighters:
		actor.reset_fighter()
	_show_home()


func _enter_old_house() -> void:
	mode = GameMode.STORY_HOUSE
	arena.visible = false
	second_arena.visible = false
	old_home.visible = true
	emberwood.visible = false
	_set_backdrop_visible(false)
	_set_location_processing(old_home, true)
	_set_location_processing(emberwood, false)
	world_environment.environment = old_home.stage_environment
	effects.set_world_fx_enabled(false)
	var story_positions := [
		Vector3(-3.0, 0.0, 2.0),
		Vector3(-3.3, 0.0, 1.35),
		Vector3(1.35, 0.0, -0.15),
		Vector3(3.2, 0.0, 1.15)
	]
	for index in range(fighters.size()):
		var actor := fighters[index]
		actor.position = story_positions[index]
		actor.reset_fighter()
		actor.facing_left = index >= 2
		actor.rotation.y = -PI * 0.5 if actor.facing_left else PI * 0.5
	camera_home = Vector3(0.0, 8.4, 18.5)
	camera_focus = Vector3(0.0, 0.8, -0.2)
	camera.position = camera_home
	camera.look_at(camera_focus, Vector3.UP)
	game_ui.show_exploration(
		"THE OLD HOUSE",
		"LURNA + NOFIA  /  Walk to the north door with WASD or arrows. Press E at the threshold to enter Emberwood."
	)


func _enter_emberwood() -> void:
	mode = GameMode.STORY_FOREST
	old_home.visible = false
	emberwood.visible = true
	_set_backdrop_visible(false)
	_set_location_processing(old_home, false)
	_set_location_processing(emberwood, true)
	world_environment.environment = emberwood.stage_environment
	var story_positions := [
		Vector3(0.0, 0.0, 8.6),
		Vector3(-2.3, 0.0, 9.1),
		Vector3(1.5, 0.0, 9.3),
		Vector3(3.6, 0.0, 8.5)
	]
	for index in range(fighters.size()):
		var actor := fighters[index]
		actor.position = story_positions[index]
		actor.reset_fighter()
		actor.facing_left = index >= 2
		actor.rotation.y = -PI * 0.5 if actor.facing_left else PI * 0.5
	camera_home = Vector3(0.0, 10.5, 25.0)
	camera_focus = Vector3(0.0, 0.8, 2.5)
	camera.position = camera_home
	camera.look_at(camera_focus, Vector3.UP)
	game_ui.show_exploration(
		"EMBERWOOD CLEARING",
		"THE OLD ROAD  /  Follow the stone path north through the burning clearing. Press E at the far marker to face the Ash Yard."
	)


func _update_story_exploration(delta: float) -> void:
	var movement := _move_vector()
	if movement.length_squared() > 1.0:
		movement = movement.normalized()
	_move_in_story(movement, delta)
	var player := fighters[0]
	camera_home = camera_home.lerp(Vector3(player.position.x * 0.25, 9.5, player.position.z + 18.0), 1.0 - exp(-2.5 * delta))
	camera_focus = camera_focus.lerp(player.position + Vector3(0.0, 0.8, -1.0), 1.0 - exp(-3.0 * delta))
	camera.position = camera_home
	camera.look_at(camera_focus, Vector3.UP)


func _move_in_story(direction: Vector3, delta: float) -> void:
	if direction.length_squared() <= 0.0001:
		return
	var player := fighters[0]
	var distance := MOVE_SPEED * delta
	var candidate_x := player.position + Vector3(direction.x * distance, 0.0, 0.0)
	if _story_position_is_open(candidate_x):
		player.position.x = candidate_x.x
	var candidate_z := player.position + Vector3(0.0, 0.0, direction.z * distance)
	if _story_position_is_open(candidate_z):
		player.position.z = candidate_z.z
	if absf(direction.x) > 0.01:
		player.facing_left = direction.x < 0.0
		player.rotation.y = -PI * 0.5 if player.facing_left else PI * 0.5


func _story_position_is_open(position: Vector3) -> bool:
	if mode == GameMode.STORY_HOUSE:
		if absf(position.x) > 8.0 or position.z < -5.8 or position.z > 5.9:
			return false
		var table_zone := Vector2(position.x - 0.2, position.z - 0.25)
		if absf(table_zone.x) < 1.75 and absf(table_zone.y) < 1.12:
			return false
		var hearth_zone := Vector2(position.x + 6.2, position.z + 3.0)
		if absf(hearth_zone.x) < 1.35 and absf(hearth_zone.y) < 0.75:
			return false
	else:
		if absf(position.x) > 17.0 or position.z < -14.5 or position.z > 13.5:
			return false
		for fire_position in [Vector2(-7.2, -3.0), Vector2(6.8, -8.5), Vector2(10.0, 5.8)]:
			if Vector2(position.x, position.z).distance_to(fire_position) < 2.0:
				return false
	return true


func _try_story_interaction() -> void:
	var player := fighters[0]
	if mode == GameMode.STORY_HOUSE and player.position.z < -4.7:
		_enter_emberwood()
	elif mode == GameMode.STORY_FOREST and player.position.z < -12.0 and absf(player.position.x) < 4.0:
		_begin_first_round()


func _set_location_processing(location: Node, enabled: bool) -> void:
	for child in location.find_children("*", "", true, false):
		child.set_process(enabled)


func _set_stage_lighting(stage_number: int) -> void:
	world_environment.environment = arena.stage_environment if stage_number == 1 else second_arena.stage_environment
	effects.set_core_color(CORE_RED if stage_number == 1 else CORE_BLUE)
	_set_backdrop_visible(true)


func _start_fight() -> void:
	mode = GameMode.FIGHT
	player_energy = 60.0
	dash_cooldown = 0.0
	dash_timer = 0.0
	player_attack_cooldown = 0.0
	elapsed = 0.0
	shake_strength = 0.0
	Engine.time_scale = 1.0
	camera_home = CAMERA_START
	camera_focus = Vector3(0.0, 0.0, -0.15)
	camera.position = camera_home
	active_arena.reset_tiles()
	var spawn_positions := [
		Vector3(-3.0, 0.0, 0.0),
		Vector3(-5.0, 0.0, 1.25),
		Vector3(3.0, 0.0, 0.0),
		Vector3(5.0, 0.0, -1.25)
	]
	for index in range(fighters.size()):
		var actor := fighters[index]
		actor.position = spawn_positions[index]
		actor.reset_fighter()
		actor.facing_left = actor.team_index == 1
		actor.rotation.y = -PI * 0.5 if actor.facing_left else PI * 0.5
	game_ui.show_combat()
	_update_ui()


func _move_vector() -> Vector3:
	var movement := Vector3.ZERO
	if _held("move_left", [KEY_A, KEY_LEFT]):
		movement.x -= 1.0
	if _held("move_right", [KEY_D, KEY_RIGHT]):
		movement.x += 1.0
	if _held("move_up", [KEY_W, KEY_UP]):
		movement.z -= 1.0
	if _held("move_down", [KEY_S, KEY_DOWN]):
		movement.z += 1.0
	return movement


func _held(action: String, physical_keys: Array) -> bool:
	if InputMap.has_action(action) and Input.is_action_pressed(action):
		return true
	for key in physical_keys:
		if Input.is_key_pressed(key) or Input.is_physical_key_pressed(key):
			return true
	return false


func _ensure_input_actions() -> void:
	var bindings := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"strike": [KEY_J, KEY_SPACE],
		"dash": [KEY_SHIFT, KEY_K],
		"pulse": [KEY_E, KEY_L]
	}
	for action in bindings.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for keycode in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = keycode
			event.keycode = keycode
			if not InputMap.action_has_event(action, event):
				InputMap.action_add_event(action, event)


func _release_gameplay_focus() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null:
		focused.release_focus()


func _update_player(delta: float) -> void:
	var movement := _move_vector()
	if movement.length_squared() > 1.0:
		movement = movement.normalized()
	if absf(movement.x) > 0.01:
		fighters[0].facing_left = movement.x < 0.0
		fighters[0].rotation.y = -PI * 0.5 if fighters[0].facing_left else PI * 0.5
	if dash_timer > 0.0:
		_try_move(fighters[0], dash_direction * 13.0 * delta)
	elif movement.length_squared() > 0.0:
		_try_move(fighters[0], movement * MOVE_SPEED * delta)


func _update_ai_for_team(team: int, delta: float) -> void:
	for actor in _fighters_for_team(team):
		if actor.health <= 0.0 or actor.is_player_controlled or actor.attack_windup > 0.0:
			continue
		var target := _nearest_enemy(actor)
		if target == null:
			continue
		actor.face_position(target.position)
		var difference := Vector2(target.position.x - actor.position.x, target.position.z - actor.position.z)
		var distance := difference.length()
		var path := active_arena.find_path(actor.position, target.position)
		if path.is_empty():
			active_arena.reset_tiles()
			path = active_arena.find_path(actor.position, target.position)
		if path.is_empty():
			continue
		var heavy_attack := actor.heavy_cooldown <= 0.0 and distance <= 3.45
		var attack_range := 3.45 if heavy_attack else BASIC_RANGE
		if distance <= attack_range and path.size() <= 2 and actor.attack_cooldown <= 0.0:
			actor.start_attack_windup(heavy_attack)
			if heavy_attack:
				active_arena.warn_at(target.position)
				effects.burst(target.position, TEAM_RED if team == 1 else TEAM_BLUE, 6)
			continue
		if distance > attack_range and distance > 1.15:
			if path.size() > 1:
				_move_along_path(actor, path, 3.0 if distance > 3.8 else 1.7, delta)
			else:
				_move_toward(actor, target.position, 1.7, delta)


func _move_along_path(actor: TeamFighter, path: Array[Vector3], speed: float, delta: float) -> void:
	if path.size() < 2:
		return
	var next_point: Vector3 = path[1]
	_move_toward(actor, next_point, speed, delta)


func _move_toward(actor: TeamFighter, target_position: Vector3, speed: float, delta: float) -> void:
	var direction := Vector3(target_position.x - actor.position.x, 0.0, target_position.z - actor.position.z)
	if direction.length_squared() <= 0.0001:
		return
	var step := minf(direction.length(), speed * delta)
	_try_move(actor, direction.normalized() * step)


func _resolve_ai_attack(attacker: TeamFighter) -> void:
	if attacker.health <= 0.0:
		return
	var target := _nearest_enemy(attacker)
	if target == null:
		return
	attacker.face_position(target.position)
	if attacker.last_attack_was_heavy:
		attacker.heavy_cooldown = randf_range(4.5, 6.0)
		attacker.attack_cooldown = 1.0
		effects.pulse_blast(attacker.position, TEAM_RED if attacker.team_index == 1 else TEAM_BLUE)
		shake_strength = maxf(shake_strength, 0.14)
		for enemy in _fighters_for_team(1 - attacker.team_index):
			if _flat_distance(attacker.position, enemy.position) <= 3.5:
				_damage_fighter(enemy, 18.0, attacker.team_index)
				active_arena.warn_at(enemy.position)
	else:
		attacker.attack_cooldown = 0.72
		effects.slash_arc(attacker.position, attacker.facing_left, TEAM_RED if attacker.team_index == 1 else TEAM_BLUE)
		if _flat_distance(attacker.position, target.position) <= BASIC_RANGE + 0.35:
			_damage_fighter(target, 11.0, attacker.team_index)
			effects.burst(target.position, TEAM_RED if attacker.team_index == 1 else TEAM_BLUE, 9)


func _player_attack() -> void:
	if player_attack_cooldown > 0.0:
		return
	player_attack_cooldown = 0.38
	var player := fighters[0]
	player.is_attacking = true
	var hit_anyone := false
	effects.slash_arc(player.position, player.facing_left, TEAM_BLUE)
	for enemy in _fighters_for_team(1):
		if enemy.health <= 0.0 or _flat_distance(player.position, enemy.position) > BASIC_RANGE:
			continue
		if player.facing_left == (enemy.position.x > player.position.x):
			continue
		_damage_fighter(enemy, 15.0, 0)
		effects.burst(enemy.position, TEAM_BLUE, 13)
		hit_anyone = true
	if hit_anyone:
		player_energy = minf(MAX_ENERGY, player_energy + 14.0)
		shake_strength = maxf(shake_strength, 0.06)
		_hit_stop(0.05)


func _player_dash() -> void:
	if dash_cooldown > 0.0 or dash_timer > 0.0:
		return
	var direction := _move_vector()
	if direction.length_squared() < 0.001:
		direction.x = -1.0 if fighters[0].facing_left else 1.0
	dash_direction = direction.normalized()
	dash_timer = 0.2
	dash_cooldown = 1.05
	fighters[0].invulnerable_timer = dash_timer + 0.13
	fighters[0].dash_timer = dash_timer
	effects.dash_trail(fighters[0].position, fighters[0].position + dash_direction * 13.0 * dash_timer, TEAM_BLUE)


func _player_pulse() -> void:
	if player_energy < PULSE_COST:
		return
	player_energy -= PULSE_COST
	effects.pulse_blast(fighters[0].position, TEAM_BLUE)
	shake_strength = maxf(shake_strength, 0.16)
	_hit_stop(0.07)
	active_arena.warn_at(fighters[0].position, 1)
	for enemy in _fighters_for_team(1):
		if enemy.health > 0.0 and _flat_distance(fighters[0].position, enemy.position) <= PULSE_RANGE:
			_damage_fighter(enemy, 24.0, 0)
			active_arena.warn_at(enemy.position)
			player_energy = minf(MAX_ENERGY, player_energy + 8.0)


func _damage_fighter(target: TeamFighter, damage: float, attacking_team: int) -> void:
	if target.health <= 0.0 or not target.receive_hit(damage):
		return
	effects.burst(target.position, TEAM_BLUE if attacking_team == 0 else TEAM_RED, 10)
	shake_strength = maxf(shake_strength, 0.04)
	var away := Vector3(target.position.x - fighters[0].position.x, 0.0, target.position.z - fighters[0].position.z)
	if away.length_squared() > 0.01:
		var knock := away.normalized() * 0.35
		var new_pos := target.position + knock
		if active_arena.is_walkable(new_pos):
			target.position = new_pos


func _nearest_enemy(actor: TeamFighter) -> TeamFighter:
	var closest: TeamFighter
	var closest_distance := INF
	for candidate in _fighters_for_team(1 - actor.team_index):
		if candidate.health <= 0.0:
			continue
		var distance := _flat_distance(actor.position, candidate.position)
		if distance < closest_distance:
			closest = candidate
			closest_distance = distance
	return closest


func _fighters_for_team(team: int) -> Array[TeamFighter]:
	var result: Array[TeamFighter] = []
	for actor in fighters:
		if actor.team_index == team:
			result.append(actor)
	return result


func _flat_distance(first: Vector3, second: Vector3) -> float:
	return Vector2(first.x - second.x, first.z - second.z).length()


func _try_move(actor: TeamFighter, displacement: Vector3) -> void:
	var horizontal := actor.position + Vector3(displacement.x, 0.0, 0.0)
	if active_arena.is_walkable(horizontal):
		actor.position.x = horizontal.x
	var depth := actor.position + Vector3(0.0, 0.0, displacement.z)
	if active_arena.is_walkable(depth):
		actor.position.z = depth.z


func _check_for_result() -> void:
	for team in [0, 1]:
		var defeated := true
		for actor in _fighters_for_team(team):
			if actor.health > 0.0:
				defeated = false
		if defeated:
			mode = GameMode.RESULTS
			var blue_won: bool = team == 1
			game_ui.show_round_result(blue_won, blue_won and round_number == 1, round_number)
			return


func _update_camera_shake() -> void:
	if shake_strength <= 0.001:
		camera.position = camera_home
	else:
		camera.position = camera_home + Vector3(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength) * 0.35,
			randf_range(-shake_strength, shake_strength)
		)
	camera.look_at(camera_focus, Vector3.UP)


func _update_ui() -> void:
	game_ui.update_match(_fighters_for_team(0), _fighters_for_team(1), player_energy, round_number)
	for actor in fighters:
		actor.visible = actor.health > 0.0


func _on_tile_fell(tile_center: Vector3) -> void:
	effects.tile_shatter(tile_center)
	if mode != GameMode.FIGHT:
		return
	for actor in fighters:
		if actor.health <= 0.0 or not active_arena.position_is_in_tile(actor.position, tile_center):
			continue
		_damage_fighter(actor, 13.0, 1 - actor.team_index)
		var safe_spot := active_arena.nearest_safe_position(actor.position)
		actor.position.x = safe_spot.x
		actor.position.z = safe_spot.z


func _hit_stop(duration: float) -> void:
	if Engine.time_scale < 1.0:
		return
	Engine.time_scale = 0.08
	await get_tree().create_timer(duration, true, false, true).timeout
	if is_equal_approx(Engine.time_scale, 0.08):
		Engine.time_scale = 1.0


func _update_camera_focus(delta: float) -> void:
	var center := Vector3.ZERO
	var count := 0
	var min_x := INF
	var max_x := -INF
	for actor in fighters:
		if actor.health <= 0.0:
			continue
		center += actor.position
		count += 1
		min_x = minf(min_x, actor.position.x)
		max_x = maxf(max_x, actor.position.x)
	if count == 0:
		return
	center /= float(count)
	var spread := max_x - min_x
	var target_home := Vector3(center.x * 0.45, 6.6, clampf(12.5 + spread * 0.55, 13.0, 18.0))
	var target_focus := Vector3(center.x * 0.6, 0.6, center.z * 0.5)
	var weight := 1.0 - exp(-4.0 * delta)
	camera_home = camera_home.lerp(target_home, weight)
	camera_focus = camera_focus.lerp(target_focus, weight)


func _enhance_environment(env: Environment, fog_color: Color) -> void:
	if env == null:
		return
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.12
	env.glow_hdr_threshold = 0.85
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.ssao_enabled = true
	env.fog_enabled = true
	env.fog_light_color = fog_color
	env.fog_density = 0.012
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.25
	env.adjustment_contrast = 1.08
