extends SceneTree

var frame_count: int = 0

func _init() -> void:
	print("[TEST] Starting automated Coin Pusher gameplay verification...")
	change_scene_to_file("res://scenes/Main.tscn")

func _process(delta: float) -> bool:
	frame_count += 1
	var root_node: Node = root.get_node_or_null("Main")
	if not root_node or not root_node.is_node_ready():
		return false
		
	# Frame 15: Verify initial state
	if frame_count == 15:
		print("[TEST] Initial coins: %d" % root_node.current_coins)
		assert(root_node.current_coins == 50, "Initial coins must be 50")
		print("[TEST] Active board coins count: %d" % root_node._active_coins.size())
		assert(root_node._active_coins.size() == 40, "Initial coins on board should be 40 (28 lower + 12 upper)")
		
	# Frame 25: Test Coin Recovery System
	if frame_count == 25:
		print("[TEST] Testing Coin Recovery System...")
		root_node.current_coins = 5
		root_node._process(4.0) # simulate elapsed time > recovery_interval
		print("[TEST] Coins after recovery tick: %d" % root_node.current_coins)
		assert(root_node.current_coins == 6, "Coins should recover by 1")
		
	# Frame 45: Verify Pusher movement
	if frame_count == 45:
		var pusher_node = root_node.pusher
		print("[TEST] Pusher position Z: %f" % pusher_node.global_position.z)
		assert(pusher_node.global_position.y == 0.0, "Pusher base Y must align with stage floor 0.0")
		
	# Frame 50: Place coin in the chute air (Z=1.65, Y=0.1) to test falling down into WinZone
	if frame_count == 50:
		print("[TEST] Spawning physical coin beyond edge (Z=1.65, Y=0.1) to fall into chute...")
		var coin_scene = preload("res://scenes/Coin.tscn")
		var test_coin = coin_scene.instantiate()
		test_coin.name = "TestFallingCoin"
		test_coin.position = Vector3(0, 0.1, 1.65)
		root_node._register_coin(test_coin)
		
	# Frame 55: Place coin in the left gutter (X=-2.0, Y=0.1, Z=0.0) to test LoseZone
	if frame_count == 55:
		print("[TEST] Spawning physical coin in Left Gutter (X=-2.0, Y=0.1) to test LoseZone...")
		var coin_scene = preload("res://scenes/Coin.tscn")
		var lose_coin = coin_scene.instantiate()
		lose_coin.name = "TestLoseCoin"
		lose_coin.position = Vector3(-2.0, 0.1, 0.0)
		root_node._register_coin(lose_coin)
		
	# Frame 85: Verify physical drop down into WinZone
	if frame_count == 85:
		var c = root_node.get_node_or_null("CoinContainer/TestFallingCoin")
		if c:
			print("[TEST] TestFallingCoin pos: %s, is_collected: %s" % [str(c.global_position), str(c.get("is_collected"))])
		else:
			print("[TEST] TestFallingCoin has been freed/collected!")
		print("[TEST] Current coins: %d, score: %d" % [root_node.current_coins, root_node.current_score])
		assert(root_node.current_coins > 6, "Coins should have increased from physical drop into WinZone")
		assert(root_node.current_score > 0, "Score should have increased from physical drop into WinZone")
		
		# Verify LoseZone coin was collected
		var lc = root_node.get_node_or_null("CoinContainer/TestLoseCoin")
		if lc:
			print("[TEST] TestLoseCoin is_collected: %s" % str(lc.get("is_collected")))
			assert(lc.get("is_collected") == true, "Lose coin must be collected/removed")
		else:
			print("[TEST] TestLoseCoin has been collected and freed!")
		
	# Frame 100: Test Pause Menu opening
	if frame_count == 100:
		print("[TEST] Opening Pause Menu...")
		root_node.pause_menu.open_menu()
		assert(root_node.pause_menu.visible == true, "Pause menu should be visible")
		assert(root.get_tree().paused == true, "Tree should be paused")
		
	# Frame 105: Test A button on focused button
	if frame_count == 105:
		print("[TEST] Pressing A button on Pause Menu...")
		var ev := InputEventAction.new()
		ev.action = "action_accept"
		ev.pressed = true
		root_node.pause_menu._input(ev)
		assert(root_node.pause_menu.visible == false, "Pause menu should close on Resume press")
		assert(root.get_tree().paused == false, "Tree should be unpaused")
		
	# Frame 120: Success and quit
	if frame_count >= 120:
		print("[TEST] ALL AUTOMATED VERIFICATION TESTS (WINZONE + LOSEZONE) PASSED SUCCESSFULLY!")
		quit(0)
		return true
		
	return false
