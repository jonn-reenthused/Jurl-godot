extends RigidBody2D

@onready var animationNode: AnimatedSprite2D = $AnimatedSprite2D

@export var isDestroyable: bool = true
@export var resetPhysics: bool = false
@export var initialPosition: Vector2
@export var causesDamage: bool = true
@export var ContactType: String = "Asteroid"

var thrust = Vector2(0, -250)
var torque = 500
var hasLaunched = false
var thrustNumber = 1
var rotationDirection = 0
var rng = RandomNumberGenerator.new()
var spriteRotationSpeed: float = 0.5

func destroyAsteroid():
	if $CollisionShape2D:
		$CollisionShape2D.queue_free()
		
	animationNode.connect("animation_finished", _on_animation_finished)
	animationNode.play("explosion")

func destroy():
	destroyAsteroid()

func _on_animation_finished():
	var tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "modulate:a", 0, 0.5)
	tween.tween_callback(self.queue_free)
	
func _ready():
	randomize()
	var random = RandomNumberGenerator.new()
	
	spriteRotationSpeed = random.randf_range(0.1, 0.5)
	
	animationNode.play("default")

func _process(delta):
	animationNode.rotate(spriteRotationSpeed * delta)
	pass

func _integrate_forces(state):
	if Globals.current_game_state != Globals.GameState.IN_GAME:
		return;

	if resetPhysics:
		resetPhysics = false

		# Stop all movement
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0
		state.transform.origin = initialPosition
	else:
		if Globals.disable_controls == false:
			if !hasLaunched:
				hasLaunched = true
				thrustNumber = rng.randi_range(40,150)
				rotationDirection = rng.randi_range(-180,180)
				
				rotation = rotationDirection
				
				for i in range(1, thrustNumber):
					state.apply_force(thrust.rotated(rotation))
