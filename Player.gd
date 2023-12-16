extends RigidBody2D

var thrust = Vector2(0, -250)
var torque = 500
var points = Globals.current_score
var hiscore = Globals.hiscore
var isDead: bool = false

enum ThrustType {NONE, LEFT, RIGHT, AHEAD}

var lastThrustType: ThrustType = ThrustType.NONE

@export var isDestroyable: bool = true
@export var resetPhysics: bool = false
@export var initialPosition: Vector2
@export var ContactType: String = "Player"

@onready var animationNode: AnimatedSprite2D = $PlayerShip

@onready var audioLeft: AudioStreamPlayer2D = $ThrustLeftPlayer
@onready var audioRight: AudioStreamPlayer2D = $ThrustRightPlayer
@onready var audioForward: AudioStreamPlayer2D = $ThrustForwardPlayer

var thrustLeft: AudioStreamMP3
var thrustRight: AudioStreamMP3
var thrustThrust: AudioStreamMP3

func resetPlayer():
	randomize()
	isDead = false
	animationNode.play("default")
	modulate.a = 1

func _ready():
	resetPlayer()
	
	thrustLeft = Globals.load_mp3("res://sound/effects/thrust-left.mp3")
	thrustRight = Globals.load_mp3("res://sound/effects/thrust-right.mp3")
	thrustThrust = Globals.load_mp3("res://sound/effects/thrust-ahead.mp3")

	audioLeft.stream = thrustLeft
	audioForward.stream = thrustThrust
	audioRight.stream = thrustRight

func _process(_delta):
	Globals.playerPosition = position
	
	if isDead:
		return
	
	if get_contact_count() > 0 && Globals.disable_controls == false:
		var bodies = get_colliding_bodies()
		var isStar: bool = false
		var isAlien: bool = false
		
		if bodies.size() > 0:
			var collisionName = ""
			
			if bodies[0].get("ContactType"):
				collisionName = bodies[0].ContactType
			
			if collisionName.contains("Star") && bodies[0].collision_layer != 4:
				bodies[0].collision_layer = 4
				Globals.playEffect(Globals.pinballEffects)
				var tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_ELASTIC)
				tween.tween_property(bodies[0], "scale", Vector2(0,0), 0.5)
				tween.tween_callback(bodies[0].queue_free)
				Globals.showPoints(bodies[0])
				
				points += 10
				Globals.current_stars -= 1
				set_points()
			elif collisionName.contains("Asteroid"):
					bodies[0].destroyAsteroid()
					if points > 0:
						points -= 1
						set_points()
			elif collisionName.contains("Alien"):
				if bodies[0].causesDamage:
					destroyPlayer()

func _integrate_forces(state):
	if isDead or Globals.current_game_state != Globals.GameState.IN_GAME:
		return
	
	if resetPhysics:
		resetPhysics = false

		# Stop all movement
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0
		state.transform.origin = initialPosition
	else:
		var animation = "default"
		
		var thrustPressed: bool = false
		var leftPressed: bool = false
		var rightPressed: bool = false

		if Globals.disable_controls == false:
			Steam.runFrame()
			if (Globals.useCustomKeys && Input.is_key_pressed(Globals.customKeyThrust)) or (!Globals.useCustomKeys and Input.is_action_pressed("thrust")) or Input.is_action_pressed("thrustPad") :
				animation = "thrust"
				thrustPressed = true
				forwardPlayEffect(false)
				#playEffect(ThrustType.AHEAD)
				state.apply_force(thrust.rotated(rotation))
			else:
				thrustPressed = false
				state.apply_force(Vector2())
				#if lastThrustType == ThrustType.AHEAD:
				#	playEffect(ThrustType.NONE)
				forwardPlayEffect(true)
			var rotation_direction = 0
			if (Globals.useCustomKeys && Input.is_key_pressed(Globals.customKeyRight)) or (!Globals.useCustomKeys and Input.is_action_pressed("right")) or Input.is_action_pressed("rightPad"):
				animation = "spinright"
				rightPressed = true
				#playEffect(ThrustType.RIGHT)
				rightPlayEffect(false)
				rotation_direction += 1
			else:
				rightPressed = false
				state.apply_force(Vector2())
				#if lastThrustType == ThrustType.RIGHT:
				#	playEffect(ThrustType.NONE)
				rightPlayEffect(true)
			if (Globals.useCustomKeys && Input.is_key_pressed(Globals.customKeyLeft)) or (!Globals.useCustomKeys and Input.is_action_pressed("left")) or Input.is_action_pressed("leftPad"):
				animation = "spinleft"
				#playEffect(ThrustType.LEFT)
				leftPressed = true
				leftPlayEffect(false)
				rotation_direction -= 1
			else:
				leftPressed = false
				state.apply_force(Vector2())
				#if lastThrustType == ThrustType.LEFT:
				#	playEffect(ThrustType.NONE)
				leftPlayEffect(true)
			state.apply_torque(rotation_direction * torque)
			
			if thrustPressed:
				if leftPressed:
					animation = "thrustLeft"
				elif rightPressed:
					animation = "thrustRight"
			
			animationNode.play(animation)

func destroy():
	destroyPlayer()

func destroyPlayer():
	isDead = true

	Globals.playEffect(Globals.explosionEffect)
	
	if animationNode.is_connected("animation_finished", _on_animation_finished):
		animationNode.disconnect("animation_finished", _on_animation_finished)
	
	animationNode.connect("animation_finished", _on_animation_finished)
	animationNode.play("explosion")

func stopAnimations():
	animationNode.play("default")
	leftPlayEffect(true)
	rightPlayEffect(true)
	forwardPlayEffect(true)

func set_points():
	var scoreText = str(points)

	while scoreText.length() < 6:
		scoreText = "0" + scoreText

	var scoreNode = get_parent().find_child("Score")
	scoreNode.text = scoreText
	Globals.current_score = points
	set_hiscore()

func set_hiscore():
	if points > hiscore:
		hiscore = points
		Globals.hiscore = hiscore
	
	var scoreText = str(hiscore)

	while scoreText.length() < 6:
		scoreText = "0" + scoreText

	var scoreNode = get_parent().find_child("HiScore")
	scoreNode.text = scoreText

func _on_animation_finished():
	var tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(self, "modulate:a", 0, 0.3)
	tween.tween_callback(_on_complete_death)
	
func _on_complete_death():
	Globals.player_died.emit()

func leftPlayEffect(stop: bool):
	audioLeft.volume_db = Globals.effectsVolume - 20
	if !stop:
		if Globals.effectsVolume > 0 and !audioLeft.playing:
			audioLeft.play()
	else:
		audioLeft.stop()

func rightPlayEffect(stop: bool):
	audioRight.volume_db = Globals.effectsVolume - 20
	if !stop:
		if Globals.effectsVolume > 0 and !audioRight.playing:
			audioRight.play()
	else:
		audioRight.stop()

func forwardPlayEffect(stop: bool):
	audioForward.volume_db = Globals.effectsVolume - 20
	if !stop:
		if Globals.effectsVolume > 0 and !audioForward.playing: 
			audioForward.play()
	else:
		audioForward.stop()
