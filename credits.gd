extends Node2D

@onready var button = $Button

# Called when the node enters the scene tree for the first time.
func _ready():
	button.grab_focus()
	pass # Replace with function body.


func _input(event):
	if event.is_action_pressed("thrustPad"):
		_on_button_pressed()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_button_pressed():
	Globals.goto_scene("res://menu.tscn")
