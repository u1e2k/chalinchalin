class_name CoinShooter
extends Node3D

const CoinScript = preload("res://scripts/Coin.gd")
const SoundManagerClass = preload("res://scripts/SoundManager.gd")

signal coin_spawned(coin: Node3D)

@export var move_speed: float = 3.2
@export var min_x: float = -1.4
@export var max_x: float = 1.4
@export var fire_cooldown: float = 0.25
@export var coin_scene: PackedScene

var _cooldown_timer: float = 0.0
var can_fire: bool = true

@onready var spawn_marker: Marker3D = $SpawnPoint
@onready var nozzle_mesh: MeshInstance3D = $NozzleMesh

func _ready() -> void:
	if not coin_scene:
		coin_scene = load("res://scenes/Coin.tscn")

func _process(delta: float) -> void:
	# Handle Shooter Movement
	var move_dir := Input.get_axis("move_left", "move_right")
	if absf(move_dir) > 0.05:
		position.x = clampf(position.x + move_dir * move_speed * delta, min_x, max_x)
		
	# Handle Fire Cooldown
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta
		
	# Handle Fire Input (Continuous hold supported)
	if Input.is_action_pressed("action_accept") or Input.is_action_pressed("btn_a"):
		if _cooldown_timer <= 0.0 and can_fire:
			_spawn_coin()
			_cooldown_timer = fire_cooldown

func _spawn_coin() -> void:
	if not coin_scene:
		return
		
	var coin: Node3D = coin_scene.instantiate()
	var spawn_pos := spawn_marker.global_position if spawn_marker else global_position
	# Slight natural randomization
	spawn_pos.x += randf_range(-0.03, 0.03)
	spawn_pos.z += randf_range(-0.03, 0.03)
	
	# Determine special coin chance (6% special, 16% silver, 78% normal)
	var roll := randf()
	if roll < 0.06:
		coin.set("coin_type", CoinScript.Type.SPECIAL)
	elif roll < 0.22:
		coin.set("coin_type", CoinScript.Type.SILVER)
	else:
		coin.set("coin_type", CoinScript.Type.NORMAL)
		
	# Subtle initial velocity & spin
	coin.set("linear_velocity", Vector3(randf_range(-0.1, 0.1), -1.0, randf_range(-0.2, 0.1)))
	coin.set("angular_velocity", Vector3(randf_range(-1.0, 1.0), randf_range(-2.0, 2.0), randf_range(-1.0, 1.0)))
	
	# Recoil animation on nozzle
	if nozzle_mesh:
		var tween := create_tween()
		tween.tween_property(nozzle_mesh, "position:y", 0.08, 0.05)
		tween.tween_property(nozzle_mesh, "position:y", 0.0, 0.1)
		
	SoundManagerClass.play(SoundManagerClass.SfxType.COIN_DROP)
	coin.position = spawn_pos
	coin_spawned.emit(coin)
