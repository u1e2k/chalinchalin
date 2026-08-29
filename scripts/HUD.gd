class_name HUD
extends Control

@onready var coin_label: Label = $TopBar/HBox/CoinPanel/HBox/CoinLabel
@onready var score_label: Label = $TopBar/HBox/ScorePanel/HBox/ScoreLabel
@onready var floating_container: Control = $FloatingContainer
@onready var combo_label: Label = $CenterNotify/ComboLabel
@onready var control_guide: Label = $BottomBar/Panel/GuideLabel

var _current_coins: int = 50
var _current_score: int = 0

func _ready() -> void:
	update_coins(50)
	update_score(0)

func update_coins(amount: int, animate: bool = false) -> void:
	_current_coins = amount
	if coin_label:
		coin_label.text = "%d" % amount
		if animate:
			var tween := create_tween()
			coin_label.scale = Vector2(1.3, 1.3)
			tween.tween_property(coin_label, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func update_score(amount: int, animate: bool = false) -> void:
	_current_score = amount
	if score_label:
		score_label.text = "%06d" % amount
		if animate:
			var tween := create_tween()
			score_label.scale = Vector2(1.2, 1.2)
			tween.tween_property(score_label, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func show_floating_text(text: String, color: Color = Color.YELLOW, screen_pos: Vector2 = Vector2.ZERO) -> void:
	var label := Label.new()
	label.text = text
	label.modulate = color
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	
	if screen_pos == Vector2.ZERO:
		screen_pos = Vector2(360, 480) + Vector2(randf_range(-60, 60), randf_range(-20, 20))
		
	label.position = screen_pos
	floating_container.add_child(label)
	
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", screen_pos.y - 60.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.7).set_delay(0.2)
	tween.chain().tween_callback(label.queue_free)

func show_combo(combo_count: int) -> void:
	if combo_label and combo_count >= 2:
		combo_label.text = "x%d COMBO!" % combo_count
		combo_label.modulate = Color(1.0, 0.3, 0.8, 1.0)
		combo_label.scale = Vector2(1.5, 1.5)
		
		var tween := create_tween().set_parallel(true)
		tween.tween_property(combo_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(combo_label, "modulate:a", 0.0, 0.8).set_delay(0.4)
