class_name SlotManager
extends Node

const SoundManagerClass = preload("res://scripts/SoundManager.gd")

signal stock_changed(current_stock: int)
signal reel_updated(reels: Array[String])
signal reel_stopped(reel_index: int, symbol: String)
signal slot_win(prize_type: String, prize_coins: int, prize_score: int, symbols: Array[String])
signal slot_lose(symbols: Array[String])

const MAX_STOCK: int = 5
const SYMBOLS: Array[String] = ["7️⃣", "🪙", "🍒", "⭐", "💎"]

var stock_count: int = 0
var is_spinning: bool = false

# Current visible reels
var current_reels: Array[String] = ["7️⃣", "7️⃣", "7️⃣"]
var _target_reels: Array[String] = ["7️⃣", "7️⃣", "7️⃣"]

var _reel_spin_time: float = 0.0
var _reel_stopped_flags: Array[bool] = [false, false, false]
var _spin_step_timer: float = 0.0

func _process(delta: float) -> void:
	if not is_spinning:
		if stock_count > 0:
			_start_spin()
		return
		
	_reel_spin_time += delta
	_spin_step_timer += delta
	
	# Rapid symbol cycling animation while spinning
	if _spin_step_timer >= 0.06:
		_spin_step_timer = 0.0
		for i in range(3):
			if not _reel_stopped_flags[i]:
				current_reels[i] = SYMBOLS[randi() % SYMBOLS.size()]
		reel_updated.emit(current_reels)
		
	# Reel 0 Stop (at 0.9s)
	if _reel_spin_time >= 0.9 and not _reel_stopped_flags[0]:
		_reel_stopped_flags[0] = true
		current_reels[0] = _target_reels[0]
		SoundManagerClass.play(SoundManagerClass.SfxType.SLOT_STOP)
		reel_stopped.emit(0, current_reels[0])
		reel_updated.emit(current_reels)
		
	# Reel 1 Stop (at 1.5s)
	if _reel_spin_time >= 1.5 and not _reel_stopped_flags[1]:
		_reel_stopped_flags[1] = true
		current_reels[1] = _target_reels[1]
		SoundManagerClass.play(SoundManagerClass.SfxType.SLOT_STOP)
		reel_stopped.emit(1, current_reels[1])
		reel_updated.emit(current_reels)
		
	# Reel 2 Stop (at 2.1s)
	if _reel_spin_time >= 2.1 and not _reel_stopped_flags[2]:
		_reel_stopped_flags[2] = true
		current_reels[2] = _target_reels[2]
		SoundManagerClass.play(SoundManagerClass.SfxType.SLOT_STOP)
		reel_stopped.emit(2, current_reels[2])
		reel_updated.emit(current_reels)
		_evaluate_result()

func add_stock() -> bool:
	if stock_count < MAX_STOCK:
		stock_count += 1
		SoundManagerClass.play(SoundManagerClass.SfxType.SLOT_CHECKER)
		stock_changed.emit(stock_count)
		return true
	return false

func _start_spin() -> void:
	if stock_count <= 0 or is_spinning:
		return
		
	stock_count -= 1
	stock_changed.emit(stock_count)
	
	is_spinning = true
	_reel_spin_time = 0.0
	_spin_step_timer = 0.0
	_reel_stopped_flags = [false, false, false]
	
	# Determine lottery result
	_roll_lottery()

func _roll_lottery() -> void:
	var roll := randf()
	
	if roll < 0.10:
		# 777 FEVER JACKPOT (10%)
		_target_reels = ["7️⃣", "7️⃣", "7️⃣"]
	elif roll < 0.32:
		# COIN BONUS (22%)
		_target_reels = ["🪙", "🪙", "🪙"]
	elif roll < 0.58:
		# CHERRY BONUS (26%)
		_target_reels = ["🍒", "🍒", "🍒"]
	elif roll < 0.72:
		# STAR / RUBY BONUS (14%)
		_target_reels = ["⭐", "⭐", "⭐"]
	elif roll < 0.82:
		# DIAMOND BONUS (10%)
		_target_reels = ["💎", "💎", "💎"]
	else:
		# MISS / LOSE (18%)
		var sym1 = SYMBOLS[randi() % SYMBOLS.size()]
		var sym2 = SYMBOLS[randi() % SYMBOLS.size()]
		while sym2 == sym1:
			sym2 = SYMBOLS[randi() % SYMBOLS.size()]
		var sym3 = SYMBOLS[randi() % SYMBOLS.size()]
		_target_reels = [sym1, sym2, sym3]

func _evaluate_result() -> void:
	is_spinning = false
	
	if _target_reels[0] == _target_reels[1] and _target_reels[1] == _target_reels[2]:
		var match_sym = _target_reels[0]
		SoundManagerClass.play(SoundManagerClass.SfxType.SLOT_WIN)
		
		match match_sym:
			"7️⃣":
				slot_win.emit("FEVER_JACKPOT", 20, 1000, _target_reels)
			"🪙":
				slot_win.emit("COIN_BONUS", 8, 300, _target_reels)
			"🍒":
				slot_win.emit("CHERRY_BONUS", 4, 150, _target_reels)
			"⭐":
				slot_win.emit("STAR_SPECIAL", 2, 500, _target_reels)
			"💎":
				slot_win.emit("DIAMOND_BONUS", 10, 600, _target_reels)
			_:
				slot_win.emit("COIN_BONUS", 5, 200, _target_reels)
	else:
		slot_lose.emit(_target_reels)
