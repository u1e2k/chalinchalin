class_name HUD
extends Control

@onready var coin_panel: PanelContainer = $TopBar/HBox/CoinPanel
@onready var coin_label: Label = $TopBar/HBox/CoinPanel/HBox/CoinLabel
@onready var score_label: Label = $TopBar/HBox/ScorePanel/HBox/ScoreLabel
@onready var floating_container: Control = $FloatingContainer
@onready var combo_label: Label = $CenterNotify/ComboLabel
@onready var control_guide: Label = $BottomBar/Panel/GuideLabel

# Slot UI Nodes
@onready var slot_panel: PanelContainer = $TopBar/HBox/SlotPanel
@onready var reel_labels: Array[Label] = [
	$TopBar/HBox/SlotPanel/VBox/ReelsContainer/Reel1Panel/Reel1Label,
	$TopBar/HBox/SlotPanel/VBox/ReelsContainer/Reel2Panel/Reel2Label,
	$TopBar/HBox/SlotPanel/VBox/ReelsContainer/Reel3Panel/Reel3Label
]
@onready var stock_lamps: Array[Label] = [
	$TopBar/HBox/SlotPanel/VBox/StockContainer/Stock1,
	$TopBar/HBox/SlotPanel/VBox/StockContainer/Stock2,
	$TopBar/HBox/SlotPanel/VBox/StockContainer/Stock3,
	$TopBar/HBox/SlotPanel/VBox/StockContainer/Stock4,
	$TopBar/HBox/SlotPanel/VBox/StockContainer/Stock5
]

var _current_coins: int = 50
var _current_score: int = 0

func _ready() -> void:
	update_coins(50)
	update_score(0)
	update_stock(0)

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

func update_stock(count: int) -> void:
	for i in range(stock_lamps.size()):
		if stock_lamps[i]:
			if i < count:
				stock_lamps[i].modulate = Color(0.0, 1.0, 0.9, 1.0) # Bright neon cyan
				stock_lamps[i].text = "◆"
			else:
				stock_lamps[i].modulate = Color(0.3, 0.35, 0.45, 0.6)
				stock_lamps[i].text = "◇"

func update_reels(symbols: Array[String]) -> void:
	for i in range(min(symbols.size(), reel_labels.size())):
		if reel_labels[i]:
			reel_labels[i].text = symbols[i]

func play_slot_stop_effect(reel_index: int) -> void:
	if reel_index < reel_labels.size() and reel_labels[reel_index]:
		var lbl = reel_labels[reel_index]
		var tween := create_tween()
		lbl.scale = Vector2(1.35, 1.35)
		tween.tween_property(lbl, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func play_slot_win_effect(prize_type: String) -> void:
	if slot_panel:
		var tween := create_tween().set_parallel(true)
		slot_panel.scale = Vector2(1.15, 1.15)
		tween.tween_property(slot_panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		
	var title_text := "★ JACKPOT! ★" if prize_type == "FEVER_JACKPOT" else "★ WIN! ★"
	var color := Color(1.0, 0.85, 0.1) if prize_type != "FEVER_JACKPOT" else Color(1.0, 0.2, 0.6)
	show_floating_text(title_text, color, Vector2(360, 220))

func show_recovery_notice(amount: int = 1) -> void:
	var label := Label.new()
	label.text = "⚡ RECOVERY +%d" % amount
	label.modulate = Color(0.25, 1.0, 0.6, 1.0) # Emerald neon
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	
	# Position directly beneath CoinPanel
	var base_pos := Vector2(60.0, 72.0)
	label.position = base_pos
	floating_container.add_child(label)
	
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", base_pos.y + 18.0, 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.85).set_delay(0.2)
	tween.chain().tween_callback(label.queue_free)

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
