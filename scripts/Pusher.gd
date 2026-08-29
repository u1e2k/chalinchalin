class_name Pusher
extends AnimatableBody3D

@export var speed: float = 1.2
@export var stroke: float = 0.55
@export var center_z: float = -1.8
@export var base_y: float = 0.0

var _time: float = 0.0

func _physics_process(delta: float) -> void:
	_time += delta * speed
	var current_z := center_z + sin(_time) * stroke
	global_position = Vector3(0.0, base_y, current_z)
