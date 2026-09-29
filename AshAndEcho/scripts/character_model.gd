@tool
class_name FighterModel
extends Node3D

const CREW_COLORS := [Color(0.22, 0.60, 0.95), Color(0.90, 0.20, 0.15)]
const SPRITES: Array[String] = [
	"res://assets/sprites/lurna.png",
	"res://assets/sprites/nofia.png"
]
const SPRITE_FALLBACK: Array[String] = [
	"res://assets/portraits/lurna.png",
	"res://assets/portraits/nofia.png"
]

var team_index := 0
var character_variant := 0
var pulse_time := 0.0
var applied_palette := ""
var sprite_plane: MeshInstance3D
var sprite_material: ShaderMaterial
var shadow_decal: MeshInstance3D


const SPRITE_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;
uniform sampler2D albedo_tex : source_color;
uniform vec4 tint : source_color = vec4(1.0);
uniform float emission_boost = 0.4;
uniform float white_cutoff = 0.92;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0],
		INV_VIEW_MATRIX[1],
		INV_VIEW_MATRIX[2],
		MODEL_MATRIX[3]
	);
}

void fragment() {
	vec4 c = texture(albedo_tex, UV);
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	float alpha = step(lum, white_cutoff);
	alpha *= c.a;
	ALBEDO = c.rgb * tint.rgb * (1.0 + emission_boost);
	EMISSION = c.rgb * tint.rgb * emission_boost;
	ALPHA = alpha;
}
"""


func _ready() -> void:
	var fighter := get_parent()
	if fighter != null and fighter.has_method("get"):
		team_index = int(fighter.get("team_index"))
		character_variant = int(fighter.get("character_variant"))
	_apply_identity()


func configure(team: int, variant: int) -> void:
	team_index = clampi(team, 0, 1)
	character_variant = clampi(variant, 0, 3)
	_apply_identity()


func update_pose(
	facing_left: bool, attacking: bool, telegraphing: bool, hurt: bool, dashing: bool
) -> void:
	if Engine.is_editor_hint():
		return
	if sprite_plane == null or sprite_material == null:
		return
	var delta := get_process_delta_time()
	pulse_time += delta

	# Flip per team so red crew faces camera the right way
	var flip_factor := 1.0
	if team_index == 0:
		flip_factor = -1.0 if facing_left else 1.0
	else:
		flip_factor = 1.0 if facing_left else -1.0
	sprite_plane.scale.x = flip_factor

	if dashing:
		sprite_plane.position.y = 1.05 + sin(pulse_time * 22.0) * 0.08
	else:
		sprite_plane.position.y = lerpf(sprite_plane.position.y, 1.05, delta * 8.0)

	if hurt:
		sprite_plane.scale = Vector3(flip_factor * 1.15, 0.85, 1.0)
		sprite_material.set_shader_parameter("tint", Color(1.0, 0.7, 0.7))
	else:
		sprite_plane.scale = sprite_plane.scale.lerp(Vector3(flip_factor, 1.0, 1.0), delta * 10.0)
		sprite_material.set_shader_parameter("tint", Color(1.0, 1.0, 1.0))

	var boost := 0.4
	if telegraphing:
		var tell := 0.5 + 0.5 * sin(pulse_time * 19.0)
		boost = 0.6 + tell * 1.4
	elif attacking:
		boost = 1.2
	sprite_material.set_shader_parameter("emission_boost", boost)


func _hide_old_meshes() -> void:
	var stack: Array[Node] = [self]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			if child.name == "SpritePlane" or child.name == "ShadowDecal":
				continue
			if child is Node3D:
				(child as Node3D).visible = false
			stack.append(child)


func _apply_identity() -> void:
	if not is_inside_tree():
		return
	var identity_key := "%d:%d" % [team_index, character_variant]
	if applied_palette == identity_key:
		return
	applied_palette = identity_key

	_hide_old_meshes()

	if sprite_plane != null:
		sprite_plane.queue_free()
		sprite_plane = null
	if shadow_decal != null:
		shadow_decal.queue_free()
		shadow_decal = null

	var path: String = SPRITES[team_index]
	if not ResourceLoader.exists(path):
		path = SPRITE_FALLBACK[team_index]
	var texture: Texture2D = null
	if ResourceLoader.exists(path):
		texture = load(path) as Texture2D

	var quad := QuadMesh.new()
	quad.size = Vector2(1.8, 2.2)
	sprite_plane = MeshInstance3D.new()
	sprite_plane.name = "SpritePlane"
	sprite_plane.mesh = quad
	sprite_plane.position = Vector3(0, 1.05, 0)
	sprite_plane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var shader := Shader.new()
	shader.code = SPRITE_SHADER
	sprite_material = ShaderMaterial.new()
	sprite_material.shader = shader
	if texture != null:
		sprite_material.set_shader_parameter("albedo_tex", texture)
	sprite_material.set_shader_parameter("tint", Color(1, 1, 1))
	sprite_material.set_shader_parameter("emission_boost", 0.4)
	sprite_plane.material_override = sprite_material
	add_child(sprite_plane)

	var decal_mesh := QuadMesh.new()
	decal_mesh.size = Vector2(1.1, 0.7)
	shadow_decal = MeshInstance3D.new()
	shadow_decal.name = "ShadowDecal"
	shadow_decal.mesh = decal_mesh
	shadow_decal.position = Vector3(0, 0.02, 0)
	shadow_decal.rotation.x = -PI * 0.5
	var shadow_material := StandardMaterial3D.new()
	shadow_material.albedo_color = Color(0, 0, 0, 0.4)
	shadow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow_decal.material_override = shadow_material
	add_child(shadow_decal)


func _crew_cloth_color() -> Color:
	return Color(0.10, 0.20, 0.35) if team_index == 0 else Color(0.30, 0.105, 0.09)
