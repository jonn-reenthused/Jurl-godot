extends Node2D

@onready var jurl_title: Sprite2D = $"Jurl-title"
@onready var starfield: Sprite2D = $Starfield1
@onready var label: Label = $Label

# Called when the node enters the scene tree for the first time.
func _ready():
	jurl_title.offset = Vector2(-7, 0)
	
	var tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(jurl_title, "offset", Vector2(0, -200), 2)

	var tween2 = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_LINEAR)
	tween2.tween_property(starfield, "modulate:a", 1, 2)
	tween2.tween_callback(_showClickLabel)

func _input(event):
	# Mouse in viewport coordinates.
	if event is InputEventMouseButton:
		Globals.goto_scene("res://menu.tscn")

	if event.is_action_pressed("menu-select"):
		Globals.goto_scene("res://menu.tscn")

	if event.is_action_pressed("thrustPad"):
		Globals.goto_scene("res://menu.tscn")
		

	#if Input.is_joy_button_pressed(0,JOY_BUTTON_A):
	#	Globals.goto_scene("res://menu.tscn")

func _showClickLabel():
	var tween2 = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_CIRC)
	tween2.tween_property(label, "modulate:a", 1, 2)
	tween2.tween_callback(_hideClickLabel)

func _hideClickLabel():
	var tween2 = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_CIRC)
	tween2.tween_property(label, "modulate:a", 0, 2)
	tween2.tween_callback(_showClickLabel)
	
