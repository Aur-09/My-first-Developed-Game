extends Node3D

@export var pulse_speed := 1.0

@onready var outer_flame: MeshInstance3D = $OuterFlame
@onready var inner_flame: MeshInstance3D = $InnerFlame
@onready var side_flame: MeshInstance3D = $SideFlame
@onready var fire_light: OmniLight3D = $FireLight
@onready var smoke_a: MeshInstance3D = $SmokeA
@onready var smoke_b: MeshInstance3D = $SmokeB

var time := 0.0
var outer_base := Vector3.ONE
var inner_base := Vector3.ONE
var side_base := Vector3.ONE


func _ready() -> void:
	outer_base = outer_flame.scale
	inner_base = inner_flame.scale
	side_base = side_flame.scale


func _process(delta: float) -> void:
	time += delta * pulse_speed
	var flare := 0.5 + 0.5 * sin(time * 5.1)
	outer_flame.scale = outer_base * Vector3(0.92 + flare * 0.12, 0.88 + flare * 0.2, 0.92 + flare * 0.12)
	inner_flame.scale = inner_base * Vector3(0.9 + flare * 0.14, 0.88 + flare * 0.24, 0.9 + flare * 0.14)
	side_flame.scale = side_base * Vector3(0.92 + flare * 0.18, 0.8 + flare * 0.3, 0.92 + flare * 0.18)
	outer_flame.rotation.y = sin(time * 2.7) * 0.17
	side_flame.rotation.z = sin(time * 3.8) * 0.12
	fire_light.light_energy = 1.8 + flare * 1.25
	fire_light.omni_range = 7.0 + flare * 1.6
	smoke_a.position.x = sin(time * 1.2) * 0.11
	smoke_b.position.x = cos(time * 0.9) * 0.14
	smoke_a.position.y = 1.8 + fposmod(time * 0.45, 0.55)
	smoke_b.position.y = 2.3 + fposmod(time * 0.37 + 0.3, 0.7)
