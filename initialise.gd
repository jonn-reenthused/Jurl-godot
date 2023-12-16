extends Node

# Called when the node enters the scene tree for the first time.
func _ready():
	
	var y = 224
	var x = 480
	
	$Star.position.x = x
	$Star.position.y = y
	
	for i in range(1,109):
		var newStar =  get_node("Star").duplicate() #$Star.duplicate()
		
		y += 30
		if y > 600:
			y = 224
			x += 30

		newStar.position.x = x
		newStar.position.y = y
		
		add_child(newStar)
		
	#pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
