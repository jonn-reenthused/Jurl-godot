extends Node2D

@onready var difficultySlider = $ReferenceRect/DifficultySlider
@onready var musicSlider = $ReferenceRect/MusicSlider
@onready var fXSlider = $ReferenceRect/FXSlider
@onready var skipLevels = $ReferenceRect/CheckButton
@onready var quitButton: Button = $ReferenceRect/QuitButton
@onready var speedRunMode = $ReferenceRect/speedRunMode
@onready var okButton: Button = $ReferenceRect/OKButton
@onready var oscSwitch = $ReferenceRect/onScreenControls

@export var is_in_game: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	difficultySlider.value = Globals.difficultyLevel
	musicSlider.value = Globals.musicVolume
	fXSlider.value = Globals.effectsVolume
	skipLevels.isSwitched = Globals.skipTraining
	speedRunMode.isSwitched = Globals.speedRunMode
	oscSwitch.isSwitched = Globals.hideOnscreenControls
	
	if !OS.has_feature("mobile"):
		$ReferenceRect/hideControlsLabel.show()
		oscSwitch.show()
		fXSlider.focus_neighbor_bottom = NodePath("../onScreenControls")
		skipLevels.focus_neighbor_top = NodePath("../onScreenControls")
		oscSwitch.focus_neighbor_bottom = NodePath("../CheckButton")
		oscSwitch.focus_neighbor_top = NodePath("../FXSlider")
	else:
		speedRunMode.focus_neighbor_left = NodePath("../CheckButton")
		fXSlider.focus_neighbor_bottom = NodePath("../CheckButton")
		skipLevels.focus_neighbor_top = NodePath("../FXSlider")
		$ReferenceRect/hideControlsLabel.hide()
		oscSwitch.hide()
	
	difficultySlider.grab_focus()
	
	if !is_in_game:
		quitButton.hide()

func setGlobalData():
	Globals.difficultyLevel = difficultySlider.value
	Globals.musicVolume = musicSlider.value
	Globals.effectsVolume = fXSlider.value
	
	if speedRunMode.isSwitched:
		skipLevels.isSwitched = false
	
	Globals.skipTraining = skipLevels.isSwitched
	Globals.speedRunMode = speedRunMode.isSwitched
	Globals.hideOnscreenControls = oscSwitch.isSwitched
	
	Globals.create_or_update_config_file()


func _on_ok_button_pressed():
	setGlobalData()
	
	if !is_in_game:	
		Globals.goto_scene("res://menu.tscn")
	else:
		Globals.InGameMenuExit.emit()
		queue_free()

func _on_quit_button_pressed():
	setGlobalData()
	Globals.goto_scene("res://menu.tscn")
	get_tree().paused = false


func _on_speed_run_mode_toggled(button_pressed):
	if skipLevels.button_pressed and button_pressed:
		skipLevels.button_pressed = false

	pass # Replace with function body.


func _on_check_button_toggled(button_pressed):
	if speedRunMode.button_pressed and button_pressed:
		speedRunMode.button_pressed = false
		
	pass # Replace with function body.

func _unhandled_input(event):
	if event.is_action_pressed("menu-select") or event.is_action_pressed("thrustPad"):
		if speedRunMode.has_focus():
			speedRunMode.isSwitched = !speedRunMode.isSwitched
		elif skipLevels.has_focus():
			skipLevels.isSwitched = !skipLevels.isSwitched
		elif oscSwitch.has_focus():
			oscSwitch.isSwitched = !oscSwitch.isSwitched

func _input(event):
	if event.is_action_pressed("menu-select") or event.is_action_pressed("thrustPad"):
		if quitButton.has_focus():
			_on_quit_button_pressed()
		elif okButton.has_focus():
			_on_ok_button_pressed()

func _process(_delta):
	pass	

func _on_on_screen_controls__on_toggled(value: bool):
	pass # Replace with function body.


func _on_check_button__on_toggled(value: bool):
	if value:
		if speedRunMode.isSwitched:
			speedRunMode.isSwitched = false
			

func _on_speed_run_mode__on_toggled(value):
	if value:
		if skipLevels.isSwitched:
			skipLevels.isSwitched = false
			
