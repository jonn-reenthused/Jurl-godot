extends Node2D

@onready var logo = $ColorRect

func _nextScene():
	Globals.goto_scene("res://title.tscn")

func _hideLabel():
	var tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(logo, "modulate:a", 0, 2)
	tween.tween_callback(self._nextScene)

func _pause():
	await get_tree().create_timer(2).timeout
	_hideLabel()

# Called when the node enters the scene tree for the first time.
func _ready():
	_pause()

func _input(event):
	# Mouse in viewport coordinates.
	if event is InputEventMouseButton:
		Globals.goto_scene("res://menu.tscn")

	if Input.is_action_pressed("menu-select"):
		Globals.goto_scene("res://menu.tscn")
