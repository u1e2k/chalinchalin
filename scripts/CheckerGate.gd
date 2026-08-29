class_name CheckerGate
extends Area3D

const CoinScript = preload("res://scripts/Coin.gd")

signal coin_passed

@export var gate_color: Color = Color(0.0, 0.9, 1.0, 1.0) # Cyan Neon
@export var is_moving: bool = false
@export var move_range: float = 0.55
@export var move_speed: float = 1.4

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var light: OmniLight3D = $OmniLight3D

var _base_pos: Vector3
var _time_accum: float = 0.0
var _is_active: bool = true
var _recent_coins: Dictionary = {}

func _ready() -> void:
	_base_pos = position
	monitoring = true
	monitorable = true
	collision_layer = 0
	collision_mask = 2 # Detect Coin
	
	body_entered.connect(_on_body_entered)
	_update_visuals(false)

func _process(delta: float) -> void:
	# Moving Gate Logic (左右にスイング移動するギミック)
	if is_moving:
		_time_accum += delta * move_speed
		position.x = _base_pos.x + sin(_time_accum) * move_range
		
	# Clean up cooldowns
	var to_erase: Array = []
	for coin in _recent_coins.keys():
		_recent_coins[coin] -= delta
		if _recent_coins[coin] <= 0.0 or not is_instance_valid(coin):
			to_erase.append(coin)
	for k in to_erase:
		_recent_coins.erase(k)

func _on_body_entered(body: Node3D) -> void:
	if not _is_active or not is_instance_valid(body):
		return
		
	if body is CoinScript or body.get("coin_type") != null:
		if not _recent_coins.has(body):
			_recent_coins[body] = 1.2 # Cooldown per coin
			_trigger_gate()

func _trigger_gate() -> void:
	coin_passed.emit()
	
	# Visual Flash Animation
	_update_visuals(true)
	var tween := create_tween()
	tween.tween_interval(0.18)
	tween.tween_callback(func(): _update_visuals(false))

func _update_visuals(is_lit: bool) -> void:
	if mesh_instance:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = gate_color if is_lit else Color(0.2, 0.25, 0.3)
		mat.emission_enabled = is_lit
		mat.emission = gate_color
		mat.emission_energy_multiplier = 3.5 if is_lit else 0.5
		mesh_instance.material_override = mat
		
	if light:
		light.light_color = gate_color
		light.light_energy = 2.2 if is_lit else 0.4
