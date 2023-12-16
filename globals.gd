extends Node

# ENUMS
enum GameState { MENU, LEVEL_START, IN_GAME, WIN, LOSE, LEVEL_END, GAME_OVER }
enum AlienTypes { METEOR, WANDERER, HUNTER, SHOOTER, MINER, LASER }
enum Difficulty { EASY, MEDIUM, HARD }

# SIGNALS
signal player_died
signal InGameMenuExit

# GAME VARIABLES
const maximum_stars = 18

var skipToLevel = 3
var skipTraining: bool = false
var hideOnscreenControls: bool = false

var speedRunMode: bool = false
var startTime = 0
var endTime = 0
var bestTimes: Array = [0,0,0,0,0,0,0,0,0,0,0,0]

var useSteam: bool = false

var current_scene = null
var current_score = 0
var current_lives = 3
var current_level: int = 1
var current_stars = maximum_stars
var lastSpeedrunLevel = 11
var musicIndex = 0

var additional_enemies: int = 0
var hiscore = 0
var disable_controls = false
var current_game_state: GameState = GameState.MENU
var playerPosition: Vector2

var explosionEffect: AudioStreamMP3

var maxLevels = 8

var useCustomKeys: bool = false
var customKeyLeft = 0
var customKeyRight = 0
var customKeyThrust = 0

var steamControllers

# CONFIG
var level_text = ["JUST\nCOLLECT\nEM' ALL", 
					"COLLECT\nAND\nAVOID",
					"COLLECT\nAND\nAVOID 2",
					"AREA\nOF\nEFFECT",
					"THEY'RE\nAFTER\nYOU",
					"PEW\nPEW\nPEW",
					"THE LIGHT\nHORRIFIC",
					"COLLECT\nAND\nAVOID 3",
					"HUNTING\nAND\nAVOIDING",
					"HUNTERS\nWITH\nGUNS",
					"MINER?\nI BARELY\nKNEW HER",
					"NOW\nIT\nJUST\nGETS\nHARDER"
					]
var instructions = ["a simple one, just collect the star diamonds and get used to the controls\n\nLeft and Right rotate, up applies thrust.",
					"It's just a few meteors, they just kind of mill around and then settle\nYou won't be hurt if you hit them, but you'll lose points",
					"These are wanderers, they're the sunday drivers of the alien fleet, just kind of drifting around with no real aim. Oh, don't hit them - you'll blow up.",
					"It's the most explosive of the bunch, the miners. They'll wander around and drop off mines. The mines won't be active for a few seconds, so try to nudge them into something.",
					"Uh oh, it's the intergalatic fuzz. These guys will just try to ram you. You don't want that, you really don't",
					"Shooters, first they rush you and then they hold firing range and try to blast you. You can avoid the plasma ball, but careful how it bounces.",
					"This ship has a Laser, fortunately it has a very short range and takes an age to charge\nJust keep out of the way because it's deadly",
					"You're on your own now"
					]

var music_files = ["res://sound/music/city-stomper.mp3",
					"res://sound/music/spaceship-shooter.mp3",
					"res://sound/music/warped-shooting-fx.mp3",
					"res://sound/music/far-away.mp3"
					]

var levelEnemies: Array = [[], 
							[Globals.AlienTypes.METEOR, Globals.AlienTypes.METEOR, Globals.AlienTypes.METEOR],
							[Globals.AlienTypes.WANDERER, Globals.AlienTypes.WANDERER, Globals.AlienTypes.WANDERER],
							[Globals.AlienTypes.MINER, Globals.AlienTypes.MINER, Globals.AlienTypes.MINER],
							[Globals.AlienTypes.HUNTER, Globals.AlienTypes.HUNTER],
							[Globals.AlienTypes.SHOOTER, Globals.AlienTypes.SHOOTER, Globals.AlienTypes.SHOOTER],
							[Globals.AlienTypes.LASER, Globals.AlienTypes.LASER, Globals.AlienTypes.LASER],
							[Globals.AlienTypes.WANDERER, Globals.AlienTypes.WANDERER, Globals.AlienTypes.HUNTER, Globals.AlienTypes.WANDERER],
							[Globals.AlienTypes.WANDERER, Globals.AlienTypes.SHOOTER, Globals.AlienTypes.SHOOTER, Globals.AlienTypes.HUNTER],
							[Globals.AlienTypes.HUNTER, Globals.AlienTypes.HUNTER, Globals.AlienTypes.HUNTER, Globals.AlienTypes.SHOOTER],
							[Globals.AlienTypes.SHOOTER, Globals.AlienTypes.LASER, Globals.AlienTypes.SHOOTER, Globals.AlienTypes.MINER],
							[Globals.AlienTypes.MINER, Globals.AlienTypes.MINER, Globals.AlienTypes.MINER, Globals.AlienTypes.MINER, Globals.AlienTypes.LASER, Globals.AlienTypes.LASER]
							]

var difficultyLevel = 1
var musicVolume = 5
var effectsVolume = 5

# LOCAL
@onready var soundeffects
var pinballEffects: AudioStreamMP3

# STEAM
var ACHIEVEMENTS: Dictionary = {"achieve1":false, "achieve2":false, "achieve3":false}

func _init():
	_initialize_Steam()

func _ready():
	## STEAM functions
	Steam.connect("current_stats_received",_steam_Stats_Ready,CONNECT_ONE_SHOT)
	getCustomKeys()
	
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)
	pinballEffects = load_mp3("res://sound/effects/pinball.mp3")
	explosionEffect = Globals.load_mp3("res://sound/effects/explosion.mp3")

func goto_scene(path):
	# This function will usually be called from a signal callback,
	# or some other function in the current scene.
	# Deleting the current scene at this point is
	# a bad idea, because it may still be executing code.
	# This will result in a crash or unexpected behavior.

	# The solution is to defer the load to a later time, when
	# we can be sure that no code from the current scene is running:

	call_deferred("_deferred_goto_scene", path)

func _deferred_goto_scene(path):
	# It is now safe to remove the current scene
	current_scene.free()

	# Load the new scene.
	var s = ResourceLoader.load(path)

	# Instance the new scene.
	current_scene = s.instantiate()

	# Add it to the active scene, as child of root.
	get_tree().root.add_child(current_scene)

	# Optionally, to make it compatible with the SceneTree.change_scene_to_file() API.
	get_tree().current_scene = current_scene

func showPoints(star: Node2D):
	var label: Label = Label.new()
	var settings: LabelSettings = LabelSettings.new()
	
	label.text = "10"
	label.label_settings = current_scene.find_child("ScoreLabel").label_settings
	settings.font_color = Color.GREEN
	settings.font_size = 20
	label.position = star.position
	#label.label_settings = settings
	
	current_scene.add_child(label)
	var tween = get_tree().create_tween().bind_node(current_scene).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(label, "scale", Vector2(3,3), 0.3)
	tween.tween_property(label, "modulate:a", 0, 0.5)
	tween.tween_callback(label.queue_free)

func _process(delta):
	Steam.run_callbacks()

func load_mp3(path):
	var sound = load(path)
	return sound

func playEffect(effect):
	soundeffects = get_tree().current_scene.find_child("EffectsPlayer")

	soundeffects.stream = effect
	soundeffects.volume_db = effectsVolume - 20
	if effectsVolume > 0: soundeffects.play()

func load_config():
	var config = ConfigFile.new()
	
	# Load data from a file.
	var err = config.load("user://config.cfg")

	# If the file didn't load, ignore it.
	if err != OK:
		create_or_update_config_file()
		return

	# Iterate over all sections.
	for player in config.get_sections():
		# Fetch the data for each section.
		var highscore = config.get_value(player, "highscore", 0)
		var musicvolume = config.get_value(player, "musicvolume", 5)
		var fxvolume = config.get_value(player, "fxvolume", 5)
		var difficulty = config.get_value(player, "difficulty", 1)
		var skipTrain = config.get_value(player, "skipTrainingLevels", false)
		var speedRun = config.get_value(player, "speedRunMode", false)
		var hideControls = config.get_value(player, "hideOnscreenControls", false)
		
		Globals.hiscore = highscore
		Globals.musicVolume = musicvolume
		Globals.effectsVolume = fxvolume
		Globals.difficultyLevel = difficulty
		Globals.skipTraining = skipTrain
		Globals.speedRunMode = speedRun
		Globals.hideOnscreenControls = hideControls

func create_or_update_config_file():
	# Create new ConfigFile object.
	var config = ConfigFile.new()

	# Store some values.
	config.set_value("config", "highscore", Globals.hiscore)
	config.set_value("config", "musicvolume", Globals.musicVolume)
	config.set_value("config", "fxvolume", Globals.effectsVolume)
	config.set_value("config", "difficulty", Globals.difficultyLevel)
	config.set_value("config", "skipTrainingLevels", Globals.skipTraining)
	config.set_value("config", "speedRunMode", Globals.speedRunMode)	
	config.set_value("config", "hideOnscreenControls", Globals.hideOnscreenControls)	

	# Save it to a file (overwrite if already exists).
	config.save("user://config.cfg")

func loadBestTimes():
	var config = ConfigFile.new()
	
	# Load data from a file.
	var err = config.load("user://times.cfg")

	# If the file didn't load, ignore it.
	if err != OK:
		create_or_update_besttimes_file()
		return

	# Iterate over all sections.
	for level in config.get_sections():
		# Fetch the data for each section.
		var besttime = config.get_value(level, "time", 0)
		var index = int(level)
		
		bestTimes[index] = besttime
		

func getBestTimeForLevel(level) -> int:
	var config = ConfigFile.new()
	
	# Load data from a file.
	var err = config.load("user://times.cfg")

	# If the file didn't load, ignore it.
	if err != OK:
		create_or_update_besttimes_file()
		return 0

	var besttime = config.get_value(str(level), "time", 0)

	return besttime

func create_or_update_besttimes_file():
	# Create new ConfigFile object.
	var config = ConfigFile.new()

	# Store some values.
	for index in range(1, bestTimes.size()):
		config.set_value(str(index), "time", bestTimes[index])
	
	# Save it to a file (overwrite if already exists).
	config.save("user://times.cfg")

func timeFrameToString(timeframe) -> String:
	var seconds = timeframe / 1000
	var ms = timeframe % 1000
	var minutes = seconds / 60
	seconds = seconds % 60
	var hours = minutes / 60
	minutes = minutes % 60
	
	var returnString = ""
	
	if hours < 10:
		returnString = "0"
	
	returnString += str(hours) + ":"
	
	if minutes < 10:
		returnString += "0"
		
	returnString += str(minutes) + ":"
	
	if seconds < 10:
		returnString += "0"
		
	returnString += str(seconds) + "." + str(ms)
	
	return returnString

func getCustomKeys():
	var config = ConfigFile.new()
	
	# Load data from a file.
	var err = config.load("user://keys.cfg")

	# If the file didn't load, ignore it.
	if err != OK:
		create_or_update_keys_file()
		useCustomKeys = false
		return

	var useCustomKeyMappings = config.get_value("keys", "UseCustomKeys", false)
	var customLeftKey = config.get_value("keys", "CustomLeftKey", 0)
	var customRightKey = config.get_value("keys", "CustomRightKey", 0)
	var customThrustKey = config.get_value("keys", "CustomThrustKey", 0)

	useCustomKeys = useCustomKeyMappings

	if !useCustomKeys:
		return
	else:
		customKeyLeft = customLeftKey
		customKeyRight = customRightKey
		customKeyThrust = customThrustKey

func create_or_update_keys_file():
	# Create new ConfigFile object.
	var config = ConfigFile.new()

	# Store some values.
	config.set_value("keys", "UseCustomKeys", useCustomKeys)
	config.set_value("keys", "CustomLeftKey", customKeyLeft)
	config.set_value("keys", "CustomRightKey", customKeyRight)
	config.set_value("keys", "CustomThrustKey", customKeyThrust)
	
	# Save it to a file (overwrite if already exists).
	config.save("user://keys.cfg")


# STEAM
func _exit_tree():
	var inputShutdown: bool = Steam.inputShutdown()
	print("Did Input shutdown?: "+str(inputShutdown))

func _initialize_Steam() -> void:
	var INIT: Dictionary = Steam.steamInit()
	
	if INIT:
		if INIT["status"] == 1:
			useSteam = true
	
	Steam.enableDeviceCallbacks()
	var inputinit: bool = Steam.inputInit()
	print("Did Steam initialise?: "+str(INIT))
	print("Did Input initialise?: "+str(inputinit))
	steamControllers = Steam.getConnectedControllers()
	print(steamControllers)
	var id = Steam.getSteamID()
	var name = Steam.getFriendPersonaName(id)
	print("Your steam name: " + str(name))

func _steam_Stats_Ready(game: int, result: int, user: int) -> void : 
	print("This game's ID: "+str(game))
	print("Call result: "+str(result))
	print("This user's Steam ID: "+str(user))
	# Get achievements and pass them to variables
	_get_Achievement("acheive1")
	_get_Achievement("acheive2")
	_get_Achievement("acheive3")

	# Get statistics (int) and pass them to variables
	var HIGHSCORE: int = Steam.getStatInt("HighScore")
	var HEALTH: int = Steam.getStatInt("Health")
	var MONEY: int = Steam.getStatInt("Money")

	# Process achievements
func _get_Achievement(value: String) -> void:
	var ACHIEVEMENT: Dictionary = Steam.getAchievement(value)
	# Achievement exists
	if ACHIEVEMENT['ret']:
	# Achievement is unlocked
		if ACHIEVEMENT['achieved']:
			ACHIEVEMENTS[value] = true
		# Achievement is locked
		else:
			ACHIEVEMENTS[value] = false
		# Achievement does not exist
	else:
		ACHIEVEMENTS[value] = false

