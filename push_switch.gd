@tool

extends Control

@export var OuterRectangleColour: Color = Color.GREEN
@export var InnerRectangleColour: Color = Color.GREEN
@export var OuterRectangleWidth: int = 4
@export var InnerRectanglePadding: int = 4
@export var focusRingColour: Color = Color.RED
@export var isSwitched: bool = false : set=_switched_changed, get=_get_switched

var _isSwitched: bool = false

signal _on_toggled(value: bool)

# Called when the node enters the scene tree for the first time.
func _ready():
	if Engine.is_editor_hint():
		var new_stylebox_normal = $MyButton.get_theme_stylebox("normal").duplicate()
		new_stylebox_normal.border_width_top = 3
		new_stylebox_normal.border_color = Color(0, 1, 0.5)
		$MyButton.add_theme_stylebox_override("normal", new_stylebox_normal)
	else:
		pass
		
func _draw():
	var outerRectangle = Rect2(0, 0, size.x, size.y)
	var innerRectangle = outerRectangle.grow(-(InnerRectanglePadding + OuterRectangleWidth))

	draw_rect(outerRectangle, OuterRectangleColour,false, OuterRectangleWidth)
	
	if isSwitched:
		draw_rect(innerRectangle, InnerRectangleColour, true)
	
	if has_focus():
		var circleRadius = (min(size.x, size.y) - 4) / PI
		var circleX = (size.x - (circleRadius * 1.6))
		var circleY = (size.y - (circleRadius * 1.6))
		
		draw_circle(Vector2(circleX, circleY), circleRadius, focusRingColour)
		
		pass
		
		
		
func _input(event):
	var outerRectangle = Rect2(0, 0, size.x, size.y)

	if event is InputEventMouseButton:
		var mouseCoordinates = get_local_mouse_position() #get_global_mouse_position()
			
		if event.button_index == MOUSE_BUTTON_LEFT && event.pressed == false:
			if outerRectangle.encloses(Rect2(mouseCoordinates.x, mouseCoordinates.y,1,1)):
				isSwitched = !isSwitched
	#elif event is InputEventAction:
	#	if event.is_action_pressed("ui_accept") || event.is_action_pressed("ui_select"):
	#		isSwitched = !isSwitched
	#elif event is InputEventJoypadButton:
	#	if event.button_index == JOY_BUTTON_A && event.is_pressed():
	#		isSwitched = !isSwitched
	#elif event is InputEventKey:
	#	if event.is_pressed() && (event.keycode == KEY_ENTER || event.keycode == KEY_SPACE):
	#		isSwitched = !isSwitched

func _switched_changed(value):
	_isSwitched = value
	_on_toggled.emit(_isSwitched)
	queue_redraw()

func _get_switched():
	return _isSwitched

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Engine.is_editor_hint():
		queue_redraw()
