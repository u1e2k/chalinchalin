class_name Coin
extends RigidBody3D

const SoundManagerClass = preload("res://scripts/SoundManager.gd")

enum Type {
	NORMAL,   # Gold Coin: +2 Coins, 100 Pts
	SILVER,   # Silver Coin: +1 Coin, 50 Pts
	SPECIAL   # Ruby/Neon Coin: +5 Coins, 500 Pts + Fever boost
}

@export var coin_type: Type = Type.NORMAL
@export var coin_radius: float = 0.24
@export var coin_height: float = 0.07

var coin_value: int = 2
var score_value: int = 100
var is_collected: bool = false
var spawn_time: float = 0.0

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	spawn_time = Time.get_ticks_msec() / 1000.0
	_setup_type_appearance()

func set_coin_type(type: Type) -> void:
	coin_type = type
	if is_node_ready():
		_setup_type_appearance()

func _setup_type_appearance() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	
	match coin_type:
		Type.NORMAL:
			coin_value = 2
			score_value = 100
			mat.albedo_color = Color(1.0, 0.82, 0.15) # Rich Arcade Gold
			mat.metallic = 0.92
			mat.roughness = 0.25
			mat.metallic_specular = 0.7
		Type.SILVER:
			coin_value = 1
			score_value = 50
			mat.albedo_color = Color(0.88, 0.90, 0.94) # Crisp Silver
			mat.metallic = 0.95
			mat.roughness = 0.20
		Type.SPECIAL:
			coin_value = 5
			score_value = 500
			mat.albedo_color = Color(1.0, 0.15, 0.45) # Neon Ruby
			mat.metallic = 0.5
			mat.roughness = 0.15
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.2, 0.5)
			mat.emission_energy_multiplier = 1.2
			
	if mesh_instance:
		mesh_instance.material_override = mat

func collect(is_win: bool) -> void:
	if is_collected:
		return
	is_collected = true
	freeze = true
	
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	if is_win:
		# Ascend and sparkle effect
		tween.tween_property(self, "scale", Vector3(1.4, 1.4, 1.4), 0.12)
		tween.chain().tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.18)
		tween.tween_property(self, "global_position:y", global_position.y + 0.4, 0.3)
	else:
		# Fall and shrink
		tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.25)
		tween.tween_property(self, "global_position:y", global_position.y - 0.5, 0.25)
		
	tween.chain().tween_callback(queue_free)

func apply_tilt(impulse: Vector3) -> void:
	if not freeze and not is_collected:
		sleeping = false
		apply_central_impulse(impulse)
		apply_torque_impulse(Vector3(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1), randf_range(-0.1, 0.1)))
