class_name GameOverMenu
extends Control

const SoundManagerClass = preload("res://scripts/SoundManager.gd")

signal retry_pressed
signal quit_pressed

@onready var score_value_label: Label = $CenterContainer/Panel/VBox/ScoreContainer/ScoreValue
@onready var coins_value_label: Label = $CenterContainer/Panel/VBox/CoinsContainer/CoinsValue
@onready var retry_btn: Button = $CenterContainer/Panel/VBox/RetryButton
@onready var quit_btn: Button = $CenterContainer/Panel/VBox/QuitButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	retry_btn.pressed.connect(_on_retry_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	
	retry_btn.focus_entered.connect(_on_button_focused)
	quit_btn.focus_entered.connect(_on_button_focused)

func show_game_over(final_score: int, total_coins_won: int) -> void:
	visible = true
	get_tree().paused = true
	
	if score_value_label:
		score_value_label.text = "%d" % final_score
	if coins_value_label:
		coins_value_label.text = "%d" % total_coins_won
		
	SoundManagerClass.play(SoundManagerClass.SfxType.GAME_OVER)
	
	# Initial focus grab for controller
	await get_tree().process_frame
	retry_btn.grab_focus()

func _on_button_focused() -> void:
	SoundManagerClass.play(SoundManagerClass.SfxType.UI_FOCUS)

func _on_retry_pressed() -> void:
	SoundManagerClass.play(SoundManagerClass.SfxType.UI_SELECT)
	visible = false
	get_tree().paused = false
	retry_pressed.emit()

func _on_quit_pressed() -> void:
	SoundManagerClass.play(SoundManagerClass.SfxType.UI_SELECT)
	visible = false
	get_tree().paused = false
	quit_pressed.emit()
