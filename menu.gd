extends Node2D

#@onready var startGame = $StartGameLabel

@onready var start: Button = $StartGameButton
@onready var about: Button = $AboutButton
@onready var options: Button = $OptionsButton
@onready var redefine: Button = $Redefine

var selectedButton: Button
var waitOnReady: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	if !OS.has_feature("mobile"):
		redefine.show()
	else:
		redefine.hide()
	
	Globals.load_config()
	selectedButton = about
	about.grab_focus()
	
	waitOnReady = true

func _on_start_game_button_pressed():
	startGame()
	
func _on_options_button_pressed():
	optionsPressed()

func _on_about_button_pressed():
	aboutPressed()

func startGame():
	Globals.goto_scene("res://main_game.tscn")

func aboutPressed():
	Globals.goto_scene("res://credits.tscn")

func optionsPressed():
	Globals.goto_scene("res://Options.tscn")

func _input(event):
	var current: Button
	
	if event.is_action_pressed("menu-select") or event.is_action_pressed("thrustPad"):
		if start.has_focus():
			startGame()
		elif about.has_focus():
			aboutPressed()
		elif options.has_focus():
			optionsPressed()

	if event.is_action_pressed("quit-game"):
		get_tree().quit()
	
	if not current: #should not happen but in case it does
		return
	
func _on_redefine_pressed():
	Globals.goto_scene("res://redefine_keys.tscn")
