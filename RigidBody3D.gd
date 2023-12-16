extends RigidBody3D

var thrust = Vector3(0, -250, 0)
var torque = 0.05
var thrust_vector: Vector3

@export var max_speed = 50.0
@export var acceleration = 0.6
@export var yaw_speed = 1.25

var forward_speed = 0.0
var yaw_input = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func get_input(delta):
	yaw_input = Input.get_axis("right", "left")
	
	if Input.is_action_pressed("thrust"):
		forward_speed = lerp(forward_speed, max_speed, acceleration * delta)
	#if Input.is_action_pressed("throttle_down"):
	#	forward_speed = lerp(forward_speed, 0, acceleration * delta)
	transform.basis = transform.basis.rotated(transform.basis.y, yaw_input * yaw_speed * delta)
	transform.basis = transform.basis.orthonormalized()

func _physics_process(delta):
	get_input(delta)

func _integrate_forces(state):
	apply_force(transform.basis.z * (forward_speed / 10))
	
