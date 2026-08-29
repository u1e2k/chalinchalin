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
		
	# Frame 25: Test Coin Drop by Shooter
	if frame_count == 25:
		print("[TEST] Triggering coin drop via action_accept...")
		var shooter = root_node.coin_shooter
		shooter._spawn_coin()
		print("[TEST] Coins after drop: %d" % root_node.current_coins)
		assert(root_node.current_coins == 49, "Coin should decrease to 49")
		
	# Frame 45: Test Tilt
	if frame_count == 45:
		print("[TEST] Triggering Tilt action...")
		root_node._try_tilt()
		assert(root_node.tilt_charge == 0.0, "Tilt charge must be reset to 0")
		
	# Frame 65: Test Win Drop Zone simulation
	if frame_count == 65:
		print("[TEST] Simulating coin winning in WinZone...")
		var test_coin = root_node._active_coins[0]
		root_node.win_zone._on_body_entered(test_coin)
		print("[TEST] Current coins after win: %d, score: %d" % [root_node.current_coins, root_node.current_score])
		assert(root_node.current_coins >= 50, "Coins should have increased")
		assert(root_node.current_score > 0, "Score should have increased")
		
	# Frame 85: Test Pause Menu opening
	if frame_count == 85:
		print("[TEST] Opening Pause Menu...")
		root_node.pause_menu.open_menu()
		assert(root_node.pause_menu.visible == true, "Pause menu should be visible")
		assert(root.get_tree().paused == true, "Tree should be paused")
		root_node.pause_menu.close_menu()
		assert(root.get_tree().paused == false, "Tree should be unpaused")
		
	# Frame 100: Success and quit
	if frame_count >= 100:
		print("[TEST] ALL AUTOMATED VERIFICATION TESTS PASSED SUCCESSFULLY!")
		quit(0)
		return true
		
	return false
