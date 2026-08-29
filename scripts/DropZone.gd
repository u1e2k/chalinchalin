class_name DropZone
extends Area3D

const CoinScript = preload("res://scripts/Coin.gd")
const SoundManagerClass = preload("res://scripts/SoundManager.gd")

signal coin_dropped(coin: Node3D, is_win: bool)

@export var is_win_zone: bool = true

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Detect coins
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body is CoinScript or body.get("coin_type") != null:
		var coin: Node3D = body
		if not coin.get("is_collected"):
			SoundManagerClass.play(SoundManagerClass.SfxType.COIN_WIN if is_win_zone else SoundManagerClass.SfxType.COIN_LOSE)
			coin_dropped.emit(coin, is_win_zone)
			if coin.has_method("collect"):
				coin.collect(is_win_zone)
