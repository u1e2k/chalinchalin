class_name PauseMenu
extends Control

const SoundManagerClass = preload("res://scripts/SoundManager.gd")

signal resumed
signal restarted
signal quit_requested

@onready var resume_btn: Button = $CenterContainer/Panel/VBox/ResumeButton
@onready var restart_btn: Button = $CenterContainer/Panel/VBox/RestartButton
@onready var quit_btn: Button = $CenterContainer/Panel/VBox/QuitButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	resume_btn.pressed.connect(_on_resume_pressed)
	restart_btn.pressed.connect(_on_restart_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	
	for btn in [resume_btn, restart_btn, quit_btn]:
		btn.focus_entered.connect(_on_button_focused)

func open_menu() -> void:
	visible = true
	get_tree().paused = true
	SoundManagerClass.play(SoundManagerClass.SfxType.UI_SELECT)
	# Explicit controller focus grab
	await get_tree().process_frame
	resume_btn.grab_focus()

func close_menu() -> void:
	visible = false
	get_tree().paused = false
	resumed.emit()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_pause") or event.is_action_pressed("btn_start") or event.is_action_pressed("action_cancel") or event.is_action_pressed("btn_b"):
		get_viewport().set_input_as_handled()
		close_menu()

func _on_button_focused() -> void:
	SoundManagerClass.play(SoundManagerClass.SfxType.UI_FOCUS)

func _on_resume_pressed() -> void:
	SoundManagerClass.play(SoundManagerClass.SfxType.UI_SELECT)
	close_menu()

func _on_restart_pressed() -> void:
	SoundManagerClass.play(SoundManagerClass.SfxType.UI_SELECT)
	visible = false
	get_tree().paused = false
	restarted.emit()

func _on_quit_pressed() -> void:
	SoundManagerClass.play(SoundManagerClass.SfxType.UI_SELECT)
	visible = false
	get_tree().paused = false
	quit_requested.emit()
