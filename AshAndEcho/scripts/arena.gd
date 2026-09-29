class_name BreakableArena
extends Node3D

signal tile_fell(tile_center: Vector3)

const COLUMNS := 8
const ROWS := 5
const TILE_SPACING := Vector2(2.0, 1.8)
const FIRST_TILE := Vector2(-7.0, -3.6)
const FALL_WARNING_TIME := 1.4
const MINIMUM_FLOOR_TILES := 12
const INTACT := 0
const WARNING := 1
const GAP := 2

@export var primary_tile_color := Color(0.15, 0.20, 0.22)
@export var secondary_tile_color := Color(0.105, 0.15, 0.18)
@export var stage_environment: Environment
@export var floor_texture_path := "res://assets/textures/tile_ash_yard.png"

var tile_nodes: Dictionary = {}
var tile_materials: Dictionary = {}
var tile_states: Dictionary = {}
var tile_timers: Dictionary = {}
var animation_time := 0.0


func _ready() -> void:
	_build_floor()


func _process(delta: float) -> void:
	animation_time += delta
	for key in tile_states.keys():
		var tile_key: Vector2i = key
		if tile_states[tile_key] == WARNING:
			tile_timers[tile_key] -= delta
			var material: StandardMaterial3D = tile_materials[tile_key]
			var pulse := 0.55 + 0.45 * sin(animation_time * 13.0)
			material.emission_energy_multiplier = 0.7 + pulse * 2.5
			if tile_timers[tile_key] <= 0.0:
				collapse_tile(tile_key)


func _build_floor() -> void:
	var floor_texture: Texture2D = null
	if ResourceLoader.exists(floor_texture_path):
		floor_texture = load(floor_texture_path) as Texture2D
	for row in range(ROWS):
		for column in range(COLUMNS):
			var key := Vector2i(column, row)
			var tile := get_node("TileGrid/Tile_%d_%d" % [column, row]) as MeshInstance3D
			var material := StandardMaterial3D.new()
			var alternating := (row + column) % 2 == 0
			material.albedo_color = primary_tile_color if alternating else secondary_tile_color
			material.roughness = 0.72
			if floor_texture != null:
				material.albedo_texture = floor_texture
				material.uv1_scale = Vector3(1, 1, 1)
			tile.material_override = material

			tile_nodes[key] = tile
			tile_materials[key] = material
			tile_states[key] = INTACT
			tile_timers[key] = 0.0


func warn_at(world_position: Vector3, radius_in_tiles: int = 0) -> void:
	var center := tile_coordinates(world_position)
	for row in range(ROWS):
		for column in range(COLUMNS):
			var key := Vector2i(column, row)
			var distance := Vector2(column - center.x, row - center.y).length()
			if distance > float(radius_in_tiles) + 0.15:
				continue
			if tile_states[key] == GAP:
				continue
			tile_states[key] = WARNING
			tile_timers[key] = maxf(tile_timers[key], FALL_WARNING_TIME)
			var material: StandardMaterial3D = tile_materials[key]
			material.emission_enabled = true
			material.emission = Color(1.0, 0.16, 0.055)
			material.emission_energy_multiplier = 1.7


func is_walkable(world_position: Vector3) -> bool:
	var key := tile_coordinates(world_position)
	if key.x < 0 or key.x >= COLUMNS or key.y < 0 or key.y >= ROWS:
		return false
	return tile_states[Vector2i(key.x, key.y)] != GAP


func find_path(from_position: Vector3, to_position: Vector3) -> Array[Vector3]:
	var start := _nearest_open_tile(tile_coordinates(from_position))
	var goal := _nearest_open_tile(tile_coordinates(to_position))
	var path: Array[Vector3] = []
	if start.x < 0 or goal.x < 0:
		return path
	var open: Array[Vector2i] = [start]
	var came_from: Dictionary = {start: start}
	var directions := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	while not open.is_empty():
		var current: Vector2i = open.pop_front()
		if current == goal:
			break
		for direction in directions:
			var next: Vector2i = current + direction
			if not _is_open_tile(next) or came_from.has(next):
				continue
			came_from[next] = current
			open.append(next)
	if not came_from.has(goal):
		return path
	var reverse_path: Array[Vector2i] = [goal]
	while reverse_path.back() != start:
		reverse_path.append(came_from[reverse_path.back()])
	reverse_path.reverse()
	for tile_key in reverse_path:
		path.append(tile_center(tile_key))
	return path


func collapse_tile(tile_key: Vector2i) -> bool:
	if not _is_open_tile(tile_key):
		return false
	if _open_tile_count() <= MINIMUM_FLOOR_TILES:
		_clear_warning(tile_key)
		return false
	tile_states[tile_key] = GAP
	if not _remaining_floor_is_connected():
		tile_states[tile_key] = INTACT
		_clear_warning(tile_key)
		return false
	tile_timers[tile_key] = 0.0
	(tile_nodes[tile_key] as MeshInstance3D).visible = false
	tile_fell.emit(tile_center(tile_key))
	return true


func _clear_warning(tile_key: Vector2i) -> void:
	tile_states[tile_key] = INTACT
	tile_timers[tile_key] = 0.0
	var material: StandardMaterial3D = tile_materials[tile_key]
	material.emission_enabled = false
	material.emission_energy_multiplier = 1.0


func _is_open_tile(tile_key: Vector2i) -> bool:
	return (
		tile_key.x >= 0
		and tile_key.x < COLUMNS
		and tile_key.y >= 0
		and tile_key.y < ROWS
		and tile_states[Vector2i(tile_key.x, tile_key.y)] != GAP
	)


func _nearest_open_tile(origin: Vector2i) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_distance := INF
	for row in range(ROWS):
		for column in range(COLUMNS):
			var candidate := Vector2i(column, row)
			if not _is_open_tile(candidate):
				continue
			var distance := Vector2(origin.x - column, origin.y - row).length_squared()
			if distance < best_distance:
				best_distance = distance
				best = candidate
	return best


func _open_tile_count() -> int:
	var count := 0
	for tile_key in tile_states:
		if tile_states[tile_key] != GAP:
			count += 1
	return count


func _remaining_floor_is_connected() -> bool:
	var start := _nearest_open_tile(Vector2i.ZERO)
	if start.x < 0:
		return true
	var visited: Dictionary = {start: true}
	var open: Array[Vector2i] = [start]
	var directions := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	while not open.is_empty():
		var current: Vector2i = open.pop_front()
		for direction in directions:
			var next: Vector2i = current + direction
			if not _is_open_tile(next) or visited.has(next):
				continue
			visited[next] = true
			open.append(next)
	return visited.size() == _open_tile_count()


func nearest_safe_position(world_position: Vector3) -> Vector3:
	var nearest := _nearest_open_tile(tile_coordinates(world_position))
	if nearest.x < 0:
		reset_tiles()
		return tile_center(Vector2i(COLUMNS / 2, ROWS / 2))
	return tile_center(nearest)


func position_is_in_tile(world_position: Vector3, center: Vector3) -> bool:
	return (
		absf(world_position.x - center.x) <= TILE_SPACING.x * 0.5
		and absf(world_position.z - center.z) <= TILE_SPACING.y * 0.5
	)


func tile_center(key: Vector2i) -> Vector3:
	return Vector3(
		FIRST_TILE.x + float(key.x) * TILE_SPACING.x,
		0.0,
		FIRST_TILE.y + float(key.y) * TILE_SPACING.y
	)


func tile_coordinates(world_position: Vector3) -> Vector2i:
	return Vector2i(
		floori((world_position.x - FIRST_TILE.x + TILE_SPACING.x * 0.5) / TILE_SPACING.x),
		floori((world_position.z - FIRST_TILE.y + TILE_SPACING.y * 0.5) / TILE_SPACING.y)
	)


func reset_tiles() -> void:
	for key in tile_states.keys():
		var tile_key: Vector2i = key
		tile_states[tile_key] = INTACT
		tile_timers[tile_key] = 0.0
		(tile_nodes[tile_key] as MeshInstance3D).visible = true
		var material: StandardMaterial3D = tile_materials[tile_key]
		material.emission_enabled = false
		material.emission_energy_multiplier = 1.0
