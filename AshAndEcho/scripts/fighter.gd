class_name TeamFighter
extends Node3D

const FighterModelScript = preload("res://scripts/character_model.gd")

@export var fighter_name := "Fighter"
@export_range(0, 1) var team_index := 0
@export var is_player_controlled := false
@export_range(0, 3) var character_variant := 0
@export var max_health := 100.0

var health := 100.0
var attack_cooldown := 0.0
var heavy_cooldown := 1.8
var attack_windup := 0.0
var hurt_timer := 0.0
var dash_timer := 0.0
var invulnerable_timer := 0.0
var facing_left := false
var is_attacking := false
var is_telegraphing := false
var last_attack_was_heavy := false
var character_model: FighterModelScript


func _ready() -> void:
	health = max_health
	character_model = $CharacterModel
	character_model.configure(team_index, character_variant)


func _process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	heavy_cooldown = maxf(0.0, heavy_cooldown - delta)
	attack_windup = maxf(0.0, attack_windup - delta)
	hurt_timer = maxf(0.0, hurt_timer - delta)
	dash_timer = maxf(0.0, dash_timer - delta)
	invulnerable_timer = maxf(0.0, invulnerable_timer - delta)
	if character_model:
		character_model.update_pose(
			facing_left,
			is_attacking,
			is_telegraphing or attack_windup > 0.0,
			hurt_timer > 0.0,
			dash_timer > 0.0
		)
	is_attacking = false
	is_telegraphing = false


func reset_fighter() -> void:
	health = max_health
	attack_cooldown = 0.0
	heavy_cooldown = randf_range(1.3, 2.3)
	attack_windup = 0.0
	hurt_timer = 0.0
	dash_timer = 0.0
	invulnerable_timer = 0.0
	is_attacking = false
	is_telegraphing = false
	visible = true


func start_attack_windup(heavy: bool) -> void:
	attack_windup = 0.64 if heavy else 0.32
	is_telegraphing = true
	is_attacking = true
	last_attack_was_heavy = heavy


func receive_hit(amount: float) -> bool:
	if health <= 0.0 or invulnerable_timer > 0.0:
		return false
	health = maxf(0.0, health - amount)
	hurt_timer = 0.3
	return true


func face_position(target: Vector3) -> void:
	facing_left = target.x < position.x
	rotation.y = -PI * 0.5 if facing_left else PI * 0.5
