extends Node2D

var currentKey: int = 0

@onready var leftLabel: Label = $LeftLabel
@onready var rightLabel: Label = $RightLabel
@onready var thrustLabel: Label = $ThrustLabel

@onready var label1: Label = $Label
@onready var label2: Label = $Label2
@onready var label3: Label = $Label3

@onready var okButton: Button = $OKButton
@onready var cancelButton: Button = $CancelButton

var leftKey = 0
var rightKey = 0
var thrustKey = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	currentKey = 0
	
	if Globals.customKeyLeft > 0:
		leftLabel.text = OS.get_keycode_string(Globals.customKeyLeft).to_upper()
		
	if Globals.customKeyRight > 0:
		rightLabel.text = OS.get_keycode_string(Globals.customKeyRight).to_upper()

	if Globals.customKeyThrust > 0:
		thrustLabel.text = OS.get_keycode_string(Globals.customKeyThrust).to_upper()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_on_cancel_button_pressed()
			return
			
		setNewKey(event.keycode)
		#if event.scancode > 64 and event.scancode < 91: # A-Z
			
		#	pass

func setNewKey(scancode):
	var hasChanged: bool = false
	
	if currentKey == 0:
		leftKey = scancode
		leftLabel.text = OS.get_keycode_string(scancode).to_upper()
		hasChanged = true
	elif currentKey == 1 and leftKey != scancode:
		rightKey = scancode
		rightLabel.text = OS.get_keycode_string(scancode).to_upper()
		hasChanged = true
	elif currentKey == 2 and leftKey != scancode and rightKey != scancode:
		thrustKey = scancode
		thrustLabel.text = OS.get_keycode_string(scancode).to_upper()
		hasChanged = true

	if hasChanged:
		currentKey += 1
		if currentKey > 2:
			okButton.grab_focus()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if currentKey == 0:
		label1.add_theme_color_override("font_color", Color(0, 1, 0, 1))
	else:
		label1.add_theme_color_override("font_color", Color(1, 0, 0, 1))

	if currentKey == 1:
		label2.add_theme_color_override("font_color", Color(0, 1, 0, 1))
	else:
		label2.add_theme_color_override("font_color", Color(1, 0, 0, 1))

	if currentKey == 2:
		label3.add_theme_color_override("font_color", Color(0, 1, 0, 1))
	else:
		label3.add_theme_color_override("font_color", Color(1, 0, 0, 1))


func _on_cancel_button_pressed():
	Globals.goto_scene("res://menu.tscn")


func _on_ok_button_pressed():
	Globals.useCustomKeys = true
	Globals.customKeyLeft = leftKey
	Globals.customKeyRight = rightKey
	Globals.customKeyThrust = thrustKey
	
	Globals.create_or_update_keys_file()
	Globals.goto_scene("res://menu.tscn")
	


func _on_clear_button_pressed():
	Globals.useCustomKeys = false
	Globals.create_or_update_keys_file()
	Globals.goto_scene("res://menu.tscn")
	
	pass # Replace with function body.
