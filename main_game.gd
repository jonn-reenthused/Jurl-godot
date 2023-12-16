extends Node2D

var rng = RandomNumberGenerator.new()
var audioStreamPlayer: AudioStreamPlayer
@onready var backgroundMusic = $BackgroundMusicPlayer
@onready var life1 = $Life1
@onready var life2 = $Life2
@onready var life3 = $Life3
@onready var instructionsLabel = $HBoxContainer/InstructionsLabel
@onready var shaderBackground = $StaticSpaceBackground

@export var alienInstance: PackedScene
@export var asteroidInstance: PackedScene
@export var playerInstance: PackedScene
@export var inGameMenu: PackedScene
@export var starInstance: PackedScene

var _player
var levelSet = []
var localTime = 0
var localEndTime = 0
var currentBestTimeForLevel = 0
var alreadyPaused: bool = false

var enemySpawns: Array = []

const jurlSpriteMin = 827
const jurlSpriteMax = 1350

signal LevelStart
# Called when the node enters the scene tree for the first time.
func _ready():
	## The StartTime keeps track of the overall time (for all the main levels)
	Globals.startTime = Time.get_ticks_msec()
	Globals.loadBestTimes()

	Steam.connect("input_device_disconnected",_input_device_disconnected)
	Steam.connect("overlay_toggled", _overlay_Toggled)

	## Background shader doesn't work on windows, not sure why?
	if OS.get_name().to_upper() == "WINDOWS":
		shaderBackground.hide()
	
	#if Globals.speedRunMode:
	$timeLabel.show()
	$bestTimeLabel.show()
	#else:
	#	$timeLabel.hide()
	
	enemySpawns = [
		$EnemySpawn1, $EnemySpawn6, $EnemySpawn9, $EnemySpawn7, $EnemySpawn12, $EnemySpawn4,
		$EnemySpawn2, $EnemySpawn5, $EnemySpawn10, $EnemySpawn8, $EnemySpawn11, $EnemySpawn3
		]
	
	alienInstance = preload("res://alien.tscn")
	asteroidInstance = preload("res://asteroid.tscn")
	playerInstance = preload("res://player.tscn")
	inGameMenu = preload("res://Options.tscn")
	starInstance = preload("res://star.tscn")
		
	_player = playerInstance.instantiate()
	add_child(_player)
	
	Globals.player_died.connect(_player_died)
	resetGame()
	
	Globals.InGameMenuExit.connect(_menu_exit)

func resetGame():
	Globals.musicIndex = rng.randi_range(0, Globals.music_files.size() - 1)

	if Globals.skipTraining and !Globals.speedRunMode:
		Globals.current_level = Globals.skipToLevel
	else:
		Globals.current_level = 1
	
	Globals.current_lives = 3
	Globals.additional_enemies = 0
	
	life1.show()
	life2.show()
	life3.show()
	
	resetForNewLevel()

func setupSound(fromReset: bool):
	if fromReset:
		var soundFilename = Globals.music_files[Globals.musicIndex]
		var soundFile:AudioStreamMP3 = Globals.load_mp3(soundFilename)
		backgroundMusic.stream = soundFile
		
		Globals.musicIndex += 1
		if Globals.musicIndex >= Globals.music_files.size():
			Globals.musicIndex = 0
		
		if Globals.musicVolume > 0:
			var tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_LINEAR)

			tween.tween_property(backgroundMusic, "volume_db", -20, 1)
			backgroundMusic.volume_db = -20
			backgroundMusic.play()
			tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_LINEAR)
			tween.tween_property(backgroundMusic, "volume_db", Globals.musicVolume - 20, 1)
	else:
		if Globals.musicVolume > 0:
			backgroundMusic.volume_db = Globals.musicVolume - 20
		else:
			backgroundMusic.stop()

func _startMusicFromFade():
	setupSound(true)

func resetForNewLevel():
	if backgroundMusic.has_stream_playback():
		var tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_LINEAR)
		tween.tween_property(backgroundMusic, "volume_db", -40, 1)
		tween.tween_callback(_startMusicFromFade)
		tween.play()
	else:
		setupSound(true)

	localTime = Time.get_ticks_msec()
	
	if Globals.current_level <= Globals.lastSpeedrunLevel:		
		currentBestTimeForLevel = Globals.getBestTimeForLevel(Globals.current_level)
		print("Getting time: " + str(currentBestTimeForLevel) + " for level " + str(Globals.current_level))
		
		if currentBestTimeForLevel > 0:
			$bestTimeLabel.text = Globals.timeFrameToString(currentBestTimeForLevel)
			$bestTimeLabel.add_theme_color_override("font_color", Color.GREEN)
			$bestTimeLabel.show()
		else:
			$bestTimeLabel.hide()
	
	loadLevelAliens()
	SetupDiamonds()
	resetPlayer()
	Globals.current_game_state = Globals.GameState.IN_GAME

func loadLevelAliens():
	if Globals.current_level <= Globals.levelEnemies.size():
		levelSet = Globals.levelEnemies[Globals.current_level - 1]
	else:
		var arrayA = rng.randi_range(2, 5)
		var arrayB = rng.randi_range(2, 5)
		
		levelSet = Globals.levelEnemies[arrayA]
		levelSet.append_array(Globals.levelEnemies[arrayB])
		Globals.additional_enemies = Globals.current_level / Globals.levelEnemies.size()
	
func resetPlayer():
	RemoveAliens()
	SetupAliens()
	
	_player.resetPhysics = true
	_player.position = $PlayerStartPosition.position
	_player.initialPosition = Vector2(_player.position.x, _player.position.y)
	_player.look_at(Vector2.ZERO)
	
	showText(Globals.level_text[min(Globals.current_level, Globals.level_text.size()) - 1])
	if Globals.current_level <= Globals.maxLevels:
		showInstructions(Globals.instructions[(Globals.current_level - 1)])
		instructionsLabel.show()

func RemoveAliens():
	for i in range(0, get_child_count()):
		if get_children()[i].name.contains("Alien$"):
			get_children()[i].queue_free()

func SetupAliens():
	var alienIndex: int = 0
	
	for count in range(0, Globals.additional_enemies + 1):
		for alien in levelSet:
			if alien == Globals.AlienTypes.METEOR:
				randomize()
				var newAsteroid =  asteroidInstance.instantiate()
				newAsteroid.name = "Alien$Asteroid$" + str(rng.randi_range(1,30000))
				
				if alienIndex < enemySpawns.size():
					newAsteroid.position = enemySpawns[alienIndex].position
				else:
					newAsteroid.position.x = rng.randi_range(100, 500)
					newAsteroid.position.y = rng.randi_range(400, 800)
				
				add_child(newAsteroid)
			else:
				randomize()
				var newAlien =  alienInstance.instantiate()
				newAlien.alienType = alien
				newAlien.name = "Alien$Hunter$" + str(rng.randi_range(1,30000))

				if alienIndex < enemySpawns.size():
					newAlien.position = enemySpawns[alienIndex].position
				else:
					newAlien.position.x = rng.randi_range(100, 500)
					newAlien.position.y = rng.randi_range(400, 800)
				
				add_child(newAlien)
				
				alienIndex += 1

func SetupDiamonds():	
	var startY = 324
	var startX = 600
	var xStep = 100
	var yStep = 100
	var yMax = 900
	var wibble: bool = false
	
	var y = startY
	var x = startX
	
	for i in range(0,Globals.maximum_stars):
		var newStar =  starInstance.instantiate()
		newStar.name = "Asteroid" + newStar.name
		
		if y > yMax:
			if wibble:
				y = startY
			else:
				y = startY - (yStep / 2)
				
			wibble = !wibble
			
			x += xStep

		newStar.position.x = x
		newStar.position.y = y
		
		add_child(newStar)

		y += yStep
		
	Globals.current_stars = Globals.maximum_stars

func PauseGame():
	if(get_tree().paused):
		return
		
	get_tree().paused = true
	
	var menu = inGameMenu.instantiate()
	menu.z_index = 10
	menu.is_in_game = true
	
	add_child(menu)

func _overlay_Toggled(is_toggled: bool) -> void:
	PauseGame()

func _input_device_disconnected(input_handle: int) -> void:
	#var index: int = Steam.getGamepadIndexForController(input_handle)
	#if index == 0:
	PauseGame()

func verifyConfig():
	if OS.has_feature("mobile"):
		if Globals.hideOnscreenControls and $TouchScreenLeft.visible:
			$TouchScreenLeft.hide()
			$TouchScreenRight.hide()
			$TouchScreenThrust.hide()
		elif !Globals.hideOnscreenControls and !$TouchScreenLeft.visible:
			$TouchScreenLeft.show()
			$TouchScreenRight.show()
			$TouchScreenThrust.show()

func _menu_exit():
	verifyConfig()
	setupSound(false)
	get_tree().paused = false

func _input(event):
	Steam.runFrame()
	if event.is_action_pressed("escape") or event.is_action_pressed("menuPad"):
		PauseGame()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Globals.current_game_state != Globals.GameState.LEVEL_END:
		$timeLabel.text = Globals.timeFrameToString(Time.get_ticks_msec() - localTime)
		
	if $bestTimeLabel.visible and currentBestTimeForLevel > 0:
		if Time.get_ticks_msec() - localTime > currentBestTimeForLevel:
			$bestTimeLabel.add_theme_color_override("font_color", Color.RED)
		else:
			$bestTimeLabel.add_theme_color_override("font_color", Color.GREEN)
			
	
	if Globals.current_stars <= 0 && Globals.current_game_state != Globals.GameState.LEVEL_END && Globals.current_game_state != Globals.GameState.LEVEL_START:
		Globals.current_game_state = Globals.GameState.LEVEL_END
		Globals.disable_controls = true

		localEndTime = Time.get_ticks_msec() - localTime
		if Globals.current_level < Globals.lastSpeedrunLevel:
			if localEndTime < currentBestTimeForLevel or currentBestTimeForLevel == 0:
				Globals.bestTimes[Globals.current_level] = localEndTime
				Globals.create_or_update_besttimes_file()
		
		if Globals.current_level == Globals.lastSpeedrunLevel:
			Globals.endTime = Time.get_ticks_msec()
			if Globals.speedRunMode:
				Globals.goto_scene("res://SpeedRun.tscn")
				return;
		
		_player.stopAnimations()
		
		Globals.current_level += 1
		$JurlResult.texture = load("res://Graphics/jurl-succeeded.png")
		showJurlResult()
		
	if !backgroundMusic.playing && backgroundMusic.stream:
		backgroundMusic.volume_db = -20
		if Globals.musicVolume > 0: backgroundMusic.play()
		var tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_LINEAR)
		tween.tween_property(backgroundMusic, "volume_db", Globals.musicVolume - 20, 1)

func showText(text):
	var levelText = get_node("LevelText")
	
	levelText.text = text

	fadeInText()

func finishLevel():
	showText("LEVEL\nCOMPLETE")

func showJurlResult():
	$JurlResult.position.y = jurlSpriteMax
	$JurlResult.visible = true
	
	var tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property($JurlResult, "position:y", jurlSpriteMin, 1)
	tween.tween_callback(hideJurlResult)
	
func hideJurlResult():
	$JurlResult.position.y = jurlSpriteMin
	$JurlResult.visible = true
	
	var tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property($JurlResult, "position:y", jurlSpriteMax, .5).set_delay(1)
	if Globals.current_game_state == Globals.GameState.GAME_OVER:
		tween.tween_callback(endGame)
	else:
		tween.tween_callback(finishLevel)

func endGame():
	Globals.goto_scene("res://menu.tscn")

func showInstructions(text):
	instructionsLabel.text = text

func hideInstructions():
	instructionsLabel.hide()
	instructionsLabel.modulate.a = 1

func enableGame():
	var tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(instructionsLabel, "modulate:a", 0, 10)
	tween.tween_callback(hideInstructions)

	if Globals.current_game_state != Globals.GameState.GAME_OVER:
		Globals.disable_controls = false
		$Player.resetPlayer()
		if Globals.current_game_state == Globals.GameState.LEVEL_END:
			resetForNewLevel()
	else:
		showJurlResult()

func fadeInText():
	var tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property($LevelText, "modulate:a", 1, 2)
	tween.tween_callback(fadeOutText)

func fadeOutText():
	var tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property($LevelText, "modulate:a", 0, 2)
	tween.tween_callback(enableGame)

func _player_died():
	Globals.disable_controls = true
	Globals.current_game_state = Globals.GameState.LOSE
	Globals.current_lives -= 1

	if Globals.current_lives == 2:
		life1.hide()
	elif Globals.current_lives == 1:
		life2.hide()
	elif Globals.current_lives == 0:
		life3.hide()
	
	if Globals.current_lives > 0:
		Globals.current_game_state = Globals.GameState.IN_GAME
		resetPlayer()
	else:
		Globals.current_game_state = Globals.GameState.GAME_OVER
		$JurlResult.texture = load("res://Graphics/jurl-failed.png")
		showText("GAME OVER")
	
