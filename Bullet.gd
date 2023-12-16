extends RigidBody2D

var thrust = Vector2(0, -1000)
var age = 0
@export var parentAlien: String
@export var isActiveBullet: bool = false
@export var causesDamage: bool = true
@export var isDestroyable: bool = true
@export var ContactType: String = "Alien"
const lifeCycle = 1000

# Called when the node enters the scene tree for the first time.
func _ready():
	pointTowardsPlayer()
	pass # Replace with function body.

func start(_position, _direction):
	age = Time.get_ticks_msec()
	rotation = _direction
	position = _position
	isActiveBullet = true
	#velocity = Vector2(speed, 0).rotated(rotation)

func pointTowardsPlayer():
	var playerPosition = Globals.playerPosition

	look_at(playerPosition)
	rotation += PI/2

func _integrate_forces(_state):
	if !isActiveBullet:
		return
	
	if Globals.current_game_state != Globals.GameState.IN_GAME:
		return;
	
	apply_force(thrust.rotated(self.rotation))

func _process(_delta):
	if !isActiveBullet:
		return
	
	if Time.get_ticks_msec() - age > lifeCycle:
		queue_free()
		return
	
	if get_contact_count() > 0 && Globals.disable_controls == false:
		var bodies = get_colliding_bodies()
		
		if bodies.size() == 0:
			return;
		
		queue_free()

func destroy():
	pass
