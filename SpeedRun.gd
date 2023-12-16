extends Node2D

@onready var difficulty = $VBoxContainer/DifficultyLabel
@onready var lives = $VBoxContainer/LivesLeftLabel
@onready var time = $VBoxContainer/Time

# Called when the node enters the scene tree for the first time.
func _ready():
	if Globals.difficultyLevel == 3:
		difficulty.text = "HARD"
	elif Globals.difficultyLevel == 2:
		difficulty.text = "MEDIUM"
	else:
		difficulty.text = "EASY"

	lives.text = "LIVES LEFT: " + str(Globals.current_lives)
	
	time.text = Globals.timeFrameToString(Globals.endTime - Globals.startTime)



func _on_button_pressed():
	Globals.goto_scene("res://menu.tscn")
