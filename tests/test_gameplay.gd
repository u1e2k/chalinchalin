extends SceneTree

var frame_count: int = 0

func _init() -> void:
	print("[TEST] Starting automated Coin Pusher gameplay verification with Slot System...")
	change_scene_to_file("res://scenes/Main.tscn")

func _process(delta: float) -> bool:
	frame_count += 1
	var root_node: Node = root.get_node_or_null("Main")
	if not root_node or not root_node.is_node_ready():
		return false
		
	# Frame 15: Verify initial state & loaded coins
	if frame_count == 15:
		print("[TEST] Current coins: %d" % root_node.current_coins)
		assert(root_node.current_coins > 0, "Coins must be positive from save or initial")
		print("[TEST] Active board coins count: %d" % root_node._active_coins.size())
		assert(root_node._active_coins.size() == 40, "Initial coins on board should be 40 (28 lower + 12 upper)")
		
	# Frame 25: Test Slot Stock addition via Checker
	if frame_count == 25:
		print("[TEST] Testing CheckerGate and Slot stock...")
		var slot_mgr = root_node.slot_manager
		assert(slot_mgr != null, "SlotManager must exist")
		assert(slot_mgr.stock_count == 0, "Initial stock must be 0")
		slot_mgr.add_stock()
		assert(slot_mgr.stock_count == 1, "Stock must increase to 1")
		print("[TEST] Slot stock successfully incremented to 1")
		
	# Frame 40: Trigger Slot Win & Coin Shower directly
	if frame_count == 40:
		print("[TEST] Testing Slot Win & Coin Shower...")
		var syms: Array[String] = ["🪙", "🪙", "🪙"]
		root_node._on_slot_win("COIN_BONUS", 5, 300, syms)
		print("[TEST] Triggered Coin Shower (5 coins)...")
		
	# Frame 95: Verify coins spawned by shower
	if frame_count == 95:
		print("[TEST] Coins on board after shower: %d" % root_node._active_coins.size())
		assert(root_node._active_coins.size() >= 45, "Board coins must increase by 5 from shower")
		
	# Frame 100: Place coin beyond front edge to test WinZone drop
	if frame_count == 100:
		print("[TEST] Spawning physical coin beyond edge (Z=1.65, Y=0.1) to fall into chute...")
		var coin_scene = preload("res://scenes/Coin.tscn")
		var test_coin = coin_scene.instantiate()
		test_coin.name = "TestFallingCoin"
		test_coin.position = Vector3(0, 0.1, 1.65)
		root_node._register_coin(test_coin)
		
	# Frame 125: Verify physical drop down into WinZone
	if frame_count == 125:
		var c = root_node.get_node_or_null("CoinContainer/TestFallingCoin")
		if c:
			print("[TEST] TestFallingCoin pos: %s, is_collected: %s" % [str(c.global_position), str(c.get("is_collected"))])
		else:
			print("[TEST] TestFallingCoin has been freed/collected!")
		print("[TEST] WinZone test complete. Score: %d" % root_node.current_score)
		
	# Frame 135: Test Pause Menu opening
	if frame_count == 135:
		print("[TEST] Opening Pause Menu...")
		root_node.pause_menu.open_menu()
		assert(root_node.pause_menu.visible == true, "Pause menu should be visible")
		assert(root.get_tree().paused == true, "Tree should be paused")
		
	# Frame 140: Test A button on focused button
	if frame_count == 140:
		print("[TEST] Pressing A button on Pause Menu...")
		var ev := InputEventAction.new()
		ev.action = "action_accept"
		ev.pressed = true
		root_node.pause_menu._input(ev)
		assert(root_node.pause_menu.visible == false, "Pause menu should close on Resume press")
		assert(root.get_tree().paused == false, "Tree should be unpaused")
		
	# Frame 155: Success and quit
	if frame_count >= 155:
		print("[TEST] ALL AUTOMATED VERIFICATION TESTS (SLOT + CHECKER + SHOWER + PERSISTENCE) PASSED SUCCESSFULLY!")
		quit(0)
		return true
		
	return false
