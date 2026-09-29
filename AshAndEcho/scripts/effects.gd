class_name ArenaEffects
extends Node3D
## Runtime visual effects. Keeps the original API (burst, shockwave) and adds
## slash arcs, pulse blasts, dash trails, tile shatter, embers and a reactor core.

const SLASH_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform vec4 tint : source_color = vec4(1.0);
uniform float progress = 0.0;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = atan(p.y, p.x) / PI;
	float head = -0.5 + progress;
	float tail = clamp((head - a) / 0.55, 0.0, 1.0);
	float inside = step(a, head) * step(head - 0.55, a);
	float thick = mix(0.11, 0.02, tail);
	float band = 1.0 - smoothstep(0.0, thick, abs(r - 0.78));
	float fade = 1.0 - smoothstep(0.75, 1.0, progress);
	float v = band * inside * (1.0 - tail) * fade;
	ALBEDO = tint.rgb * 3.5;
	ALPHA = clamp(v, 0.0, 1.0);
}
"""

var _slash_shader: Shader
var _embers: CPUParticles3D
var _core: Node3D
var _core_light: OmniLight3D
var _core_material: StandardMaterial3D
var _core_time := 0.0


func _process(delta: float) -> void:
	if _core == null or not _core.visible:
		return
	_core_time += delta
	var pulse := 0.5 + 0.5 * sin(_core_time * 2.2)
	_core_light.light_energy = 1.0 + pulse * 1.5
	_core_material.emission_energy_multiplier = 1.6 + pulse * 1.4
	var s := 1.0 + pulse * 0.06
	_core.scale = Vector3(s, s, s)


# ---------------------------------------------------------------- helpers

func _glow_material(color: Color, energy: float = 3.0, alpha: float = 1.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, alpha)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if alpha < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func _free_after(node: Node, seconds: float) -> void:
	get_tree().create_timer(seconds).timeout.connect(node.queue_free)


func _flash(pos: Vector3, color: Color, energy: float, duration: float, light_range: float = 8.0) -> void:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	light.position = pos
	add_child(light)
	var tween := create_tween()
	tween.tween_property(light, "light_energy", 0.0, duration)
	tween.tween_callback(light.queue_free)


# ---------------------------------------------------------------- original API

func burst(origin: Vector3, color: Color, amount: int = 14) -> void:
	var sparks := CPUParticles3D.new()
	sparks.emitting = false
	sparks.one_shot = true
	sparks.amount = amount * 2
	sparks.lifetime = 0.55
	sparks.explosiveness = 1.0
	var mesh := SphereMesh.new()
	mesh.radius = 0.055
	mesh.height = 0.11
	mesh.radial_segments = 6
	mesh.rings = 3
	var material := _glow_material(color, 4.0, 1.0)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	mesh.material = material
	sparks.mesh = mesh
	sparks.direction = Vector3.UP
	sparks.spread = 180.0
	sparks.initial_velocity_min = 2.5
	sparks.initial_velocity_max = 6.5
	sparks.gravity = Vector3(0.0, -9.0, 0.0)
	sparks.scale_amount_min = 0.6
	sparks.scale_amount_max = 1.5
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	ramp.set_color(1, Color(color.r, color.g, color.b, 0.0))
	sparks.color_ramp = ramp
	sparks.position = origin + Vector3(0.0, 0.9, 0.0)
	add_child(sparks)
	sparks.emitting = true
	_free_after(sparks, 1.0)
	_flash(origin + Vector3(0.0, 1.0, 0.0), color, 2.5, 0.18, 5.0)


func shockwave(origin: Vector3, color: Color) -> void:
	for ring_index in range(2):
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.62
		torus.outer_radius = 0.74 if ring_index == 0 else 0.68
		ring.mesh = torus
		ring.position = origin + Vector3(0.0, 0.04 + ring_index * 0.02, 0.0)
		ring.scale = Vector3(0.25, 0.25, 0.25)
		var material := _glow_material(color, 4.0, 0.9)
		ring.material_override = material
		add_child(ring)
		var final_scale := 4.4 if ring_index == 0 else 3.0
		var duration := 0.5 if ring_index == 0 else 0.35
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(ring, "scale", Vector3(final_scale, final_scale, final_scale), duration) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(material, "albedo_color:a", 0.0, duration)
		tween.chain().tween_callback(ring.queue_free)
	_flash(origin + Vector3(0.0, 0.6, 0.0), color, 5.0, 0.35, 9.0)


# ---------------------------------------------------------------- new powers

## Glowing crescent slash in front of a fighter.
func slash_arc(origin: Vector3, facing_left: bool, color: Color) -> void:
	if _slash_shader == null:
		_slash_shader = Shader.new()
		_slash_shader.code = SLASH_SHADER
	var quad := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(3.0, 3.0)
	quad.mesh = mesh
	var material := ShaderMaterial.new()
	material.shader = _slash_shader
	material.set_shader_parameter("tint", color)
	material.set_shader_parameter("progress", 0.0)
	quad.material_override = material
	var side := -1.0 if facing_left else 1.0
	quad.position = origin + Vector3(side * 0.9, 1.1, 0.0)
	quad.scale = Vector3(side, 1.0, 1.0)
	quad.rotation.z = randf_range(-0.35, 0.35)
	add_child(quad)
	var tween := create_tween()
	tween.tween_method(func(value: float) -> void: material.set_shader_parameter("progress", value), 0.0, 1.0, 0.26)
	tween.tween_callback(quad.queue_free)
	_flash(origin + Vector3(side * 1.0, 1.1, 0.0), color, 3.0, 0.2, 5.0)


## Big energy pulse: double shockwave, rising light column, upward sparks.
func pulse_blast(origin: Vector3, color: Color) -> void:
	shockwave(origin, color)
	var column := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.9
	cylinder.bottom_radius = 1.4
	cylinder.height = 7.0
	column.mesh = cylinder
	column.position = origin + Vector3(0.0, 3.5, 0.0)
	var material := _glow_material(color, 3.5, 0.55)
	column.material_override = material
	add_child(column)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(column, "scale", Vector3(0.15, 1.15, 0.15), 0.45) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.45)
	tween.chain().tween_callback(column.queue_free)
	burst(origin, color, 26)
	_flash(origin + Vector3(0.0, 2.0, 0.0), color, 8.0, 0.5, 12.0)


## Ghost copies of the fighter along a dash path.
func dash_trail(from: Vector3, to: Vector3, color: Color) -> void:
	for index in range(6):
		var ghost := MeshInstance3D.new()
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.34
		capsule.height = 1.7
		ghost.mesh = capsule
		var material := _glow_material(color, 2.5, 0.45)
		ghost.material_override = material
		ghost.position = from.lerp(to, float(index) / 5.0) + Vector3(0.0, 0.9, 0.0)
		add_child(ghost)
		var tween := create_tween()
		tween.tween_interval(0.02 * index)
		tween.set_parallel(true)
		tween.tween_property(material, "albedo_color:a", 0.0, 0.32)
		tween.tween_property(ghost, "scale", Vector3(0.6, 0.9, 0.6), 0.32)
		tween.chain().tween_callback(ghost.queue_free)
	burst(from, color, 8)


## Floor tile breaking into chunks that tumble into the void.
func tile_shatter(center: Vector3, color: Color = Color(1.0, 0.35, 0.15)) -> void:
	for index in range(8):
		var chunk := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(randf_range(0.25, 0.55), randf_range(0.12, 0.25), randf_range(0.25, 0.55))
		chunk.mesh = box
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.12, 0.11, 0.12)
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.6
		chunk.material_override = material
		var start := center + Vector3(randf_range(-0.6, 0.6), 0.1, randf_range(-0.6, 0.6))
		chunk.position = start
		add_child(chunk)
		var velocity := Vector3(randf_range(-2.0, 2.0), randf_range(2.5, 5.0), randf_range(-2.0, 2.0))
		var spin := Vector3(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0), randf_range(-6.0, 6.0))
		var tween := create_tween()
		tween.tween_method(_tumble.bind(chunk, start, velocity, spin), 0.0, 1.4, 1.4)
		tween.tween_callback(chunk.queue_free)
	burst(center + Vector3(0.0, -0.4, 0.0), color, 20)
	_flash(center + Vector3(0.0, 0.5, 0.0), color, 4.0, 0.4, 7.0)


func _tumble(t: float, chunk: Node3D, start: Vector3, velocity: Vector3, spin: Vector3) -> void:
	if not is_instance_valid(chunk):
		return
	chunk.position = start + velocity * t + Vector3(0.0, -9.0 * t * t * 0.5, 0.0)
	chunk.rotation = spin * t


# ---------------------------------------------------------------- atmosphere

## Rising embers over the whole arena.
func start_embers() -> void:
	if _embers != null:
		return
	_embers = CPUParticles3D.new()
	_embers.amount = 90
	_embers.lifetime = 5.0
	_embers.preprocess = 4.0
	_embers.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_embers.emission_box_extents = Vector3(11.0, 0.2, 6.0)
	_embers.direction = Vector3.UP
	_embers.spread = 20.0
	_embers.initial_velocity_min = 0.6
	_embers.initial_velocity_max = 1.7
	_embers.gravity = Vector3(0.15, 0.25, 0.0)
	_embers.scale_amount_min = 0.5
	_embers.scale_amount_max = 1.3
	var mesh := SphereMesh.new()
	mesh.radius = 0.035
	mesh.height = 0.07
	mesh.radial_segments = 6
	mesh.rings = 3
	var material := _glow_material(Color(1.0, 0.55, 0.2), 4.0, 1.0)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	mesh.material = material
	_embers.mesh = mesh
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 0.7, 0.3, 1.0))
	ramp.set_color(1, Color(1.0, 0.2, 0.05, 0.0))
	_embers.color_ramp = ramp
	_embers.position = Vector3(0.0, 0.3, 0.0)
	add_child(_embers)


## Glowing industrial furnace in the background (replaces the red sphere).
func spawn_core(pos: Vector3 = Vector3(0.0, 7.0, -16.0)) -> void:
	if _core != null:
		return
	_core = Node3D.new()
	_core.position = pos
	add_child(_core)
	# Central furnace sphere - smaller, warmer
	var sphere := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 1.4
	mesh.height = 2.8
	sphere.mesh = mesh
	_core_material = _glow_material(Color(1.0, 0.45, 0.15), 1.8, 0.85)
	sphere.material_override = _core_material
	_core.add_child(sphere)
	# Industrial rings around it
	var ring_material := _glow_material(Color(0.95, 0.35, 0.10), 2.5, 0.7)
	for ring_index in range(2):
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 2.2 + ring_index * 0.4
		torus.outer_radius = 2.35 + ring_index * 0.4
		ring.mesh = torus
		ring.rotation.x = PI * 0.5
		ring.rotation.z = ring_index * 0.4
		ring.material_override = ring_material
		_core.add_child(ring)
	# Soft warm light - much dimmer than before
	_core_light = OmniLight3D.new()
	_core_light.light_color = Color(1.0, 0.55, 0.25)
	_core_light.omni_range = 18.0
	_core_light.light_energy = 1.2
	_core.add_child(_core_light)


func set_core_color(color: Color) -> void:
	if _core == null:
		return
	_core_material.albedo_color = color
	_core_material.emission = color
	_core_light.light_color = color


func set_world_fx_enabled(enabled: bool) -> void:
	if _embers != null:
		_embers.emitting = enabled
	if _core != null:
		_core.visible = enabled
