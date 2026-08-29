class_name Main
extends Node3D

const CoinScript = preload("res://scripts/Coin.gd")
const SoundManagerClass = preload("res://scripts/SoundManager.gd")
const SaveManagerClass = preload("res://scripts/SaveManager.gd")

@export var initial_coins: int = 50
@export var max_active_coins: int = 120

# Coin Recovery System Settings
@export var recovery_target: int = 25       # Recover coins up to this amount
@export var recovery_interval: float = 3.5    # Interval in seconds per coin replenishment

var current_coins: int = 50
var current_score: int = 0
var high_score: int = 0
var total_coins_won: int = 0
var is_game_over: bool = false
var combo_count: int = 0
var combo_timer: float = 0.0

var _active_coins: Array[Node3D] = []
var _recovery_timer: float = 0.0

@onready var coin_shooter: Node3D = $CoinShooter
@onready var coin_container: Node3D = $CoinContainer
@onready var pusher: Node3D = $Pusher
@onready var win_zone: Area3D = $WinZone
@onready var lose_zone_left: Area3D = $LoseZoneLeft
@onready var lose_zone_right: Area3D = $LoseZoneRight
@onready var hud: Control = $UI/HUD
@onready var pause_menu: Control = $UI/PauseMenu
@onready var game_over_menu: Control = $UI/GameOverMenu
@onready var camera: Camera3D = $Camera3D

var coin_scene: PackedScene = preload("res://scenes/Coin.tscn")

func _ready() -> void:
	# Load saved progress (Coins & Stats Persistence)
	var save_data = SaveManagerClass.load_game()
	current_coins = save_data.get("coins", initial_coins)
	high_score = save_data.get("high_score", 0)
	total_coins_won = save_data.get("total_coins_won", 0)
	
	current_score = 0
	is_game_over = false
	
	# Connect signals
	if coin_shooter and coin_shooter.has_signal("coin_spawned"):
		coin_shooter.coin_spawned.connect(_on_coin_spawned_by_shooter)
		
	if win_zone and win_zone.has_signal("coin_dropped"):
		win_zone.coin_dropped.connect(_on_coin_dropped)
	if lose_zone_left and lose_zone_left.has_signal("coin_dropped"):
		lose_zone_left.coin_dropped.connect(_on_coin_dropped)
	if lose_zone_right and lose_zone_right.has_signal("coin_dropped"):
		lose_zone_right.coin_dropped.connect(_on_coin_dropped)
		
	if pause_menu:
		if pause_menu.has_signal("restarted"):
			pause_menu.restarted.connect(_restart_game)
		if pause_menu.has_signal("quit_requested"):
			pause_menu.quit_requested.connect(_quit_game)
		
	if game_over_menu:
		if game_over_menu.has_signal("retry_pressed"):
			game_over_menu.retry_pressed.connect(_restart_game)
		if game_over_menu.has_signal("quit_pressed"):
			game_over_menu.quit_pressed.connect(_quit_game)
		
	# Update initial HUD
	if hud:
		hud.update_coins(current_coins)
		hud.update_score(current_score)
	
	# Populate board with initial starting coins
	_spawn_initial_board_coins()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_save_game()

func _save_game() -> void:
	if current_score > high_score:
		high_score = current_score
	SaveManagerClass.save_game(current_coins, high_score, total_coins_won)

func _process(delta: float) -> void:
	if is_game_over or get_tree().paused:
		return
		
	# Combo countdown
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo_count = 0
			
	# Coin Recovery System (救済措置: コインが一定数未満なら一定時間ごとに自動補給)
	if current_coins < recovery_target:
		_recovery_timer += delta
		if _recovery_timer >= recovery_interval:
			_recovery_timer = 0.0
			current_coins += 1
			_save_game()
			if hud:
				hud.update_coins(current_coins, true)
				hud.show_recovery_notice(1)
			if coin_shooter:
				coin_shooter.set("can_fire", true)
	else:
		_recovery_timer = 0.0
			
	# Handle Pause input
	if Input.is_action_just_pressed("ui_pause") or Input.is_action_just_pressed("btn_start"):
		if pause_menu and not pause_menu.visible and game_over_menu and not game_over_menu.visible:
			_save_game()
			pause_menu.open_menu()

func _on_coin_spawned_by_shooter(coin: Node3D) -> void:
	if current_coins <= 0:
		coin.queue_free()
		return
		
	current_coins -= 1
	if hud:
		hud.update_coins(current_coins)
	
	_register_coin(coin)
	_save_game()
	
	# Cap management
	_enforce_coin_cap()
	
	# Disable shooter if empty
	if current_coins <= 0 and coin_shooter:
		coin_shooter.set("can_fire", false)

func _register_coin(coin: Node3D) -> void:
	if coin_container:
		coin_container.add_child(coin)
	_active_coins.append(coin)
	coin.tree_exited.connect(func(): _active_coins.erase(coin))

func _enforce_coin_cap() -> void:
	if _active_coins.size() > max_active_coins:
		# Find oldest sleeping coin to cull
		for coin in _active_coins:
			if is_instance_valid(coin) and coin.get("sleeping") == true and not coin.get("is_collected"):
				coin.queue_free()
				break

func _on_coin_dropped(coin: Node3D, is_win: bool) -> void:
	if is_win:
		combo_count += 1
		combo_timer = 2.2
		var multiplier := 1.0 + float(combo_count - 1) * 0.25
		
		var gain_coins: int = coin.get("coin_value") if coin.get("coin_value") != null else 2
		var gain_score: int = int(float(coin.get("score_value") if coin.get("score_value") != null else 100) * multiplier)
		
		current_coins += gain_coins
		current_score += gain_score
		total_coins_won += gain_coins
		_save_game()
		
		if hud:
			hud.update_coins(current_coins, true)
			hud.update_score(current_score, true)
			
			var c_type = coin.get("coin_type")
			if c_type == CoinScript.Type.SPECIAL:
				hud.show_floating_text("★ SPECIAL! +%d COINS" % gain_coins, Color(1, 0.2, 0.6))
			elif c_type == CoinScript.Type.SILVER:
				hud.show_floating_text("+%d COIN" % gain_coins, Color(0.85, 0.9, 1.0))
			else:
				hud.show_floating_text("+%d COINS" % gain_coins, Color(1, 0.85, 0.2))
				
			if combo_count >= 2:
				hud.show_combo(combo_count)
				
		# Re-enable shooting if coins were restored
		if current_coins > 0 and coin_shooter:
			coin_shooter.set("can_fire", true)
	else:
		combo_count = 0

func _spawn_initial_board_coins() -> void:
	# Populate Lower Bed (Z: -0.7 to 0.95)
	for i in range(28):
		var coin: Node3D = coin_scene.instantiate()
		var x := randf_range(-1.25, 1.25)
		var z := randf_range(-0.7, 0.95)
		var y := 0.05 + float(i % 2) * 0.08
		coin.position = Vector3(x, y, z)
		coin.rotation = Vector3(0, randf_range(0, TAU), 0)
		if randf() < 0.15:
			coin.set("coin_type", CoinScript.Type.SILVER)
		elif randf() < 0.05:
			coin.set("coin_type", CoinScript.Type.SPECIAL)
		_register_coin(coin)
		
	# Populate Upper Bed (Z: -2.8 to -1.8)
	for i in range(12):
		var coin: Node3D = coin_scene.instantiate()
		var x := randf_range(-1.2, 1.2)
		var z := randf_range(-2.8, -1.8)
		var y := 0.55 + float(i % 2) * 0.08
		coin.position = Vector3(x, y, z)
		coin.rotation = Vector3(0, randf_range(0, TAU), 0)
		_register_coin(coin)

func _restart_game() -> void:
	_save_game()
	get_tree().reload_current_scene()

func _quit_game() -> void:
	_save_game()
	get_tree().quit()
