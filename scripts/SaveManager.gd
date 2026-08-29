class_name SaveManager
extends RefCounted

const SAVE_PATH = "user://save_data.json"

static func save_game(coins: int, high_score: int, total_won: int) -> void:
	var data = {
		"coins": coins,
		"high_score": high_score,
		"total_coins_won": total_won,
		"version": 1
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_str = JSON.stringify(data, "\t")
		file.store_string(json_str)
		file.close()

static func load_game() -> Dictionary:
	var default_data = {
		"coins": 50,
		"high_score": 0,
		"total_coins_won": 0
	}
	if not FileAccess.file_exists(SAVE_PATH):
		return default_data
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return default_data
		
	var json_str = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_str)
	if parse_result == OK and json.data is Dictionary:
		var loaded: Dictionary = json.data
		var result = default_data.duplicate()
		if loaded.has("coins"):
			result["coins"] = int(loaded["coins"])
		if loaded.has("high_score"):
			result["high_score"] = int(loaded["high_score"])
		if loaded.has("total_coins_won"):
			result["total_coins_won"] = int(loaded["total_coins_won"])
		return result
		
	return default_data
