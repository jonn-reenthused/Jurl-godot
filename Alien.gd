## Most of the enemy classes in Jurl, all except the Asteroid, this contains the basic setup and AI
class_name Alien extends RigidBody2D

## AlienType specifies which of the aliens this is
@export var alienType: Globals.AlienTypes = Globals.AlienTypes.WANDERER
@export var bulletNode: PackedScene
@export var mineNode: PackedScene
@export var causesDamage: bool = true
@export var isDestroyable: bool = true
@export var ContactType: String = "Alien"

@onready var animationNode: AnimatedSprite2D = $AnimatedSprite2D
@onready var muzzle = $Muzzle
@onready var poopShoot = $PoopShoot
@onready var Laser = $LaserBeam2D

var storedPlayerPosition: Vector2 # The laser is instant kill, so let's lag the position
var animationName: String = "Wanderer"
var defaultThrust = -100
var defaultMinerThrust = -500
var thrust = Vector2.ZERO
var miner_thrust = Vector2.ZERO
var lastupdate = 0
var isFiringAge = 0
var torque = 500
var isFiring: bool = false
var isDead: bool = false

var lastMineTime = Time.get_ticks_msec()
var lastDirectionTime = 0
var lastThrust = 0
var lastThrustDirection = 0
var hasHitWall: bool = false
var amMining: bool = false
var mineClunk: AudioStreamMP3
var laserShot: AudioStreamMP3
var bulletShot: AudioStreamMP3
var MinerMineTime = 20000 - (100 * (Globals.difficultyLevel - 1))
var maxFiringTime = 6000 - (10 * (Globals.difficultyLevel - 1))
var lastFiringTime = 0
var currentAnimation: String = ""
var firingRange = 500 + (5 * (Globals.difficultyLevel - 1))

# Called when the node enters the scene tree for the first time.
func _ready():
	if Globals.difficultyLevel == 3: # If hard difficulty then no friendly fire
		isDestroyable = false

	var rng = RandomNumberGenerator.new()

	randomize()

	defaultThrust = rng.randi_range(-90, -150)
	defaultMinerThrust = rng.randi_range(-450, -600)
	thrust = Vector2(0, defaultThrust - (5 * (Globals.difficultyLevel - 1)))
	miner_thrust = Vector2(0, defaultMinerThrust - (5 * (Globals.difficultyLevel - 1)))
	
	bulletNode = preload("res://bullet.tscn")
	mineNode = preload("res://mine.tscn")
	mineClunk = Globals.load_mp3("res://sound/effects/mineclunk.mp3")
	laserShot = Globals.load_mp3("res://sound/effects/laser.mp3")
	bulletShot = Globals.load_mp3("res://sound/effects/boom.mp3")
	
	animationNode.connect("animation_changed", _on_animation_changed)	

	rotation = PI/2
	
	if alienType == Globals.AlienTypes.WANDERER:
		animationName = "wanderer"
		randomiseHeading()
	elif alienType == Globals.AlienTypes.HUNTER:
		animationName = "hunter"
	elif alienType == Globals.AlienTypes.SHOOTER:
		animationName = "shooter"
		maxFiringTime = 3000 - (100 * (Globals.difficultyLevel - 1))
	elif alienType == Globals.AlienTypes.MINER:
		randomize()
		animationName = "miner"
		rotation = PI/4
		MinerMineTime = rng.randi_range(10000, 25000)
		isDestroyable = false
	elif alienType == Globals.AlienTypes.LASER:
		animationName = "laser-default"
		maxFiringTime = 8000 - (100 * (Globals.difficultyLevel - 1))
		firingRange = 300 + (10 * (Globals.difficultyLevel - 1))
	
	animationNode.play(animationName)
	
func destroyAlien():
	isDead = true

	if animationNode.is_connected("animation_finished", _on_laser_animation_finished):
		animationNode.disconnect("animation_finished", _on_laser_animation_finished)
		
	if animationNode.is_connected("animation_finished", _on_shooter_animation_finished):
		animationNode.disconnect("animation_finished", _on_shooter_animation_finished)

	if animationNode.is_connected("animation_finished", _on_laser_move_finished):
		animationNode.disconnect("animation_finished", _on_laser_move_finished)
	
	animationNode.connect("animation_finished", _on_animation_finished)
	animationNode.play("explosion")

func destroy():
	if isDead:
		return;
	
	destroyAlien()

func randomiseHeading():
	if isDead:
		return;
	
	if Globals.current_game_state != Globals.GameState.IN_GAME:
		return

	var thisupdate = Time.get_ticks_msec()
	
	if thisupdate - lastupdate > 600:
		lastupdate = thisupdate
	else:
		return

	randomize()
	var rng = RandomNumberGenerator.new()

	var randomHeading = rng.randf_range(-180.0, 180.0)
		
	rotate(deg_to_rad(randomHeading))

func changeHeading() -> int:
	if isDead:
		return 0;
	
	if Globals.current_game_state != Globals.GameState.IN_GAME:
		return 0
	
	var thisupdate = Time.get_ticks_msec()
	
	if thisupdate - lastupdate > 1600:
		lastupdate = thisupdate
	else:
		return 0
	
	var rotation_direction = 0
	randomize()
	var rng = RandomNumberGenerator.new()
	
	var direction = rng.randi_range(-10,10)
	
	if direction < -5:
		rotation_direction = -1
	elif direction > 5:
		rotation_direction = 1
			
	return rotation_direction

func pointTowardsPlayer():
	if isDead:
		return;

	var playerPosition = Globals.playerPosition

	look_at(playerPosition)
	rotation += PI/2

func distanceToPlayer() -> float:
	if isDead:
		return 0;

	if alienType == Globals.AlienTypes.LASER and isFiring:
		return 0;
	
	var playerPosition = Globals.playerPosition
	var distance = position.distance_to(playerPosition)

	return distance

func checkDistanceAndMove() -> bool:
	if isDead:
		return false;
	
	if distanceToPlayer() > firingRange:
		return true
	else:
		return false

func beam_fire():
	if isDead:
		return;
	
	Laser.max_length = firingRange
	Laser.target_position = storedPlayerPosition
	Laser.is_casting = true
	await get_tree().create_timer(0.3).timeout
	Laser.is_casting = false

func checkDistanceAndFire():
	if isDead:
		return;
	
	if distanceToPlayer() <= firingRange:
		if isFiring:
			if Time.get_ticks_msec() - isFiringAge > 2000:
				isFiring = false
			return
		
		isFiring = true
		isFiringAge = Time.get_ticks_msec()
		
		if alienType == Globals.AlienTypes.LASER:
			if animationNode.is_connected("animation_finished", _on_laser_move_finished):
				animationNode.disconnect("animation_finished", _on_laser_move_finished)
			if !animationNode.is_connected("animation_finished", _on_laser_animation_finished):
				animationNode.connect("animation_finished", _on_laser_animation_finished)
				
			storedPlayerPosition = Globals.playerPosition
			animationNode.play("laser-fire")
		else:
			if !animationNode.is_connected("animation_finished", _on_shooter_animation_finished):
				animationNode.connect("animation_finished", _on_shooter_animation_finished)
			animationNode.play("shooter-fire")

func minerLayMine():
	if isDead:
		return;
	
	amMining = true
	
	if !animationNode.is_connected("animation_finished", _on_miner_animation_finished):
		animationNode.connect("animation_finished", _on_miner_animation_finished)

	animationNode.play("miner-mining")
	Globals.playEffect(self.mineClunk)

func _integrate_forces(state):
	if isDead:
		return;
	
	if Globals.current_game_state != Globals.GameState.IN_GAME or Globals.disable_controls:
		return;
	
	if alienType == Globals.AlienTypes.WANDERER:
		randomize()
		var rng = RandomNumberGenerator.new()

		if rng.randi_range(0,5) > 3:
			apply_force(thrust.rotated(self.rotation))
		
		if rng.randi_range(-5, 5) > 3:
			var rotation_direction = changeHeading()
			state.apply_torque_impulse(rotation_direction * torque)
		else:
			pointTowardsPlayer()
			
	elif alienType == Globals.AlienTypes.HUNTER:
		pointTowardsPlayer()
		
		apply_force(thrust.rotated(self.rotation))
	elif alienType == Globals.AlienTypes.SHOOTER or alienType == Globals.AlienTypes.LASER:
		pointTowardsPlayer()
	
		if checkDistanceAndMove():
			if alienType == Globals.AlienTypes.LASER:
				if !isFiring:
					if animationNode.is_connected("animation_finished", _on_laser_move_finished):
						animationNode.connect("animation_finished", _on_laser_move_finished)
					changeAnimation("laser-movement")
			else:
				if !isFiring:
					changeAnimation("shooter")
					
			apply_force(thrust.rotated(self.rotation))
		else:
			apply_force(-thrust.rotated(self.rotation))
			if Time.get_ticks_msec() - lastFiringTime > maxFiringTime:
				lastFiringTime = Time.get_ticks_msec()
				checkDistanceAndFire()
				
	elif alienType == Globals.AlienTypes.MINER:
		if amMining:
			return

		if Time.get_ticks_msec() - lastMineTime > MinerMineTime:
			minerLayMine()
		
		if Time.get_ticks_msec() - lastThrust > 1000:
			apply_force(miner_thrust.rotated(self.rotation))
			lastThrust = Time.get_ticks_msec()
		
		if Time.get_ticks_msec() - lastDirectionTime > 10000:
			lastDirectionTime = Time.get_ticks_msec()
			if lastThrustDirection == 1:
				lastThrustDirection = -1
			else:
				lastThrustDirection = 1
		
			if hasHitWall:
				hasHitWall = false
				state.apply_torque_impulse(1200)
			else:
				state.apply_torque_impulse(lastThrustDirection * 800)
			
func _on_animation_finished():
	var tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(self, "modulate:a", 0, 0.5)
	tween.tween_callback(self.queue_free)

func _on_shooter_animation_finished():
	if isDead:
		return;
	
	if currentAnimation != "shooter-fire":
		isFiring = false
		return;
	
	randomize()
	var rng = RandomNumberGenerator.new()
	
	var bullet = bulletNode.instantiate()

	bullet.start(muzzle.global_position, rotation)
	bullet.freeze = false
	
	Globals.playEffect(bulletShot)
	
	bullet.parentAlien = name
	bullet.name = "Alien$Bullet-" + str(rng.randi_range(1,100000))
	get_tree().current_scene.add_child(bullet)	
	animationNode.play("shooter")
	
	lastFiringTime = Time.get_ticks_msec()
	isFiring = false

func _on_laser_animation_finished():
	if isDead:
		return;
	
	if currentAnimation != "laser-fire":
		Laser.is_casting = false
		return;
	
	Globals.playEffect(laserShot)

	beam_fire()

	changeAnimation("laser-default")
	lastFiringTime = Time.get_ticks_msec()
	isFiring = false

func _on_miner_animation_finished():
	if isDead:
		return;
	
	animationNode.play("miner")
	var rng = RandomNumberGenerator.new()
	
	var mine = mineNode.instantiate()

	mine.start(poopShoot.global_position, -rotation)
	mine.freeze = false
	
	mine.name = "Alien$Mine-" + str(rng.randi_range(1,100000))
	get_tree().current_scene.add_child(mine)
	amMining = false
	lastMineTime = Time.get_ticks_msec()

func _on_animation_changed():
	currentAnimation = animationNode.animation

func _on_laser_move_finished():
	if isDead:
		return;
	
	changeAnimation("laser-movement-loop")

func _process(_delta):
	if isDead:
		return;
	
	if get_contact_count() > 0:
		var bodies = get_colliding_bodies()
		
		if bodies.size() == 0: # Assume Wall
			hasHitWall = true
		else:
			if bodies[0].name.contains("Bullet"):
				destroy()
			
func changeAnimation(newAnimation: String):	
	animationNode.play(newAnimation)
	pass
	
