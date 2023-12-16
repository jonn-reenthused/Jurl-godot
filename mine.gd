extends RigidBody2D

var isActive: bool = false
var awakeTime = 0
var age = 0
@onready var animatedNode = $MineSprite
@export var causesDamage: bool = false
@export var isDestroyable: bool = true

func start(_position, _direction):
	age = Time.get_ticks_msec()
	rotation = _direction
	position = _position

# Called when the node enters the scene tree for the first time.
func _ready():
	awakeTime = Time.get_ticks_msec()
	animatedNode.play("disabled")
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if !isActive:
		if Time.get_ticks_msec() - awakeTime > 6000:
			isActive = true
			animatedNode.play("default")
			causesDamage = true
		return

	if get_contact_count() > 0 && Globals.disable_controls == false:
		var bodies = get_colliding_bodies()
		if bodies.size() > 0:
			destroy()
			print(bodies[0])
			if bodies[0].name.contains("Wall"):
				return
			
			if bodies[0].isDestroyable:
				bodies[0].destroy()

func destroy():
	if animatedNode.is_connected("animation_finished", _on_animation_finished):
		animatedNode.disconnect("animation_finished", _on_animation_finished)
	
	animatedNode.connect("animation_finished", _on_animation_finished)
	animatedNode.play("explosion")

func _on_animation_finished():
	queue_free()
	
