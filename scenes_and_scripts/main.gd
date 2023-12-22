extends Node2D

#####################################
# Santa Catch, 2024                 #
# A game by Daniel the Fox          #
# https://danielthefox.itch.io      #
# https://github.com/Daniel-The-Fox #
#####################################


# Nodes
@onready var bg_music_player = $BGMusicPlayer
@onready var bing_sfx = $BingSfx
@onready var game_start_timer = $GameStartTimer
@onready var player = $Player
@onready var player_end_position = $PlayerEndPosition
@onready var player_start_position = $PlayerStartPosition
@onready var present_spawn_timer = $PresentSpawnTimer
@onready var snow = $Snow


# Export variables
@export var bg_music_stream_1: AudioStream
@export var bg_music_stream_1_volume: int = -10
@export var bg_music_stream_2: AudioStream
@export var bg_music_stream_2_volume: int = -20
@export var bing_sfx_delay_sec:float = 1.0

@export var debug_mode: bool = false
@export var debug_mode_game_progress: float = 0.90

@export var highscore_node: PackedScene

@export var present_scale: float = 0.35
@export var present_scene: PackedScene
@export var present_spawn_timer_max: float = 1.975
@export var present_spawn_timer_min: float = 0.010
@export var present_x_offset_factor: float = 1.01

@export var presents_to_catch: int = 100


# General variables
var count_time: bool = true
var game_progress: float = 0.0
var highscore_screen
var presents_catched: int = 0:
	set(value):
		if value > presents_to_catch:
			value = presents_to_catch
		presents_catched = value
		game_progress = float(presents_catched) / float(presents_to_catch)
var screen_size: Vector2

var time_elapsed: float = 0.0
var time_elapsed_min: int = 0
var time_elapsed_sec: int = 0
var time_elapsed_string: String = str("00:00")
var time_end: float = 0.0
var time_now: float = 0.0
var time_start: float = 0.0


# Called when the node enters the scene tree for the first time.
func _ready():
	# randomize() should be called in _ready() in main scene
	# See https://docs.godotengine.org/en/stable/tutorials/math/random_number_generation.html
	randomize()
	screen_size = get_viewport_rect().size
	Events.game_started.connect(_on_game_started)
	Events.present_catched.connect(_on_present_catched)
	Events.highscore_screen_initialized.connect(_on_highscore_screen_initialized)
	Events.highscore_screen_continued.connect(_on_highscore_screen_continued)
	new_game()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if count_time and time_start > 0:
		update_time()


func new_game():
	bing_sfx.play()
	snow.show()
	game_progress = 0.0
	presents_catched = 0
	if debug_mode:
		print("ATTENTION: DEBUG MODE ACTIVATED!")
		presents_catched = floor(debug_mode_game_progress * presents_to_catch)
		game_start_timer.wait_time = 0.01
	Events.score_updated.emit(presents_catched, presents_to_catch, game_progress)
	await get_tree().create_timer(bing_sfx_delay_sec).timeout
	await play_random_bg_music()
	player.start(player_start_position.position)
	game_start_timer.start()


func spawn_present():
	#print("Spawning new present...")
	var present = present_scene.instantiate()
	present.scale = Vector2(present_scale, present_scale)
	present.position.x = -999
	present.position.y = 0
	add_child(present)
	@warning_ignore("narrowing_conversion")
	present.position.x = randi_range(
			0 + (roundi(present.width/2 * present_x_offset_factor)),
			screen_size.x - (roundi(present.width/2 * present_x_offset_factor)),
	)
	present.falling_speed = ceil(present.falling_speed * (1.0 + game_progress))
	#print("present.falling_speed: " + str(present.falling_speed))
	present_spawn_timer.wait_time = snapped(
			randf_range(
					present_spawn_timer_min,
					present_spawn_timer_max
			),
			0.001,
	)
	#print("present_spawn_timer.wait_time: " + str(present_spawn_timer.wait_time))


func _on_game_start_timeout():
	Events.game_started.emit()
	present_spawn_timer.start()


func _on_game_started():
	time_start = Time.get_unix_time_from_system()
	print("time_start (unix seconds): " + str(time_start))
	@warning_ignore("narrowing_conversion")
	print(
			"Game started at ",
			str(Time.get_datetime_string_from_unix_time(time_start)),
			"\n",
	)


func _on_present_spawn_timeout():
	spawn_present()
	Events.present_spawned.emit()


func _on_present_catched():
	presents_catched += 1
	print("presents_catched: " + str(presents_catched))
	# For details on GDScript string formatting, see
	# https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_format_string.html#padding
	print(
			"game_progress: ",
			str("%1.2f" % game_progress),
			" => ",
			str(int(game_progress * 100)),
			"%",
	)
	print("\n")
	Events.score_updated.emit(presents_catched, presents_to_catch, game_progress)
	if presents_catched >= presents_to_catch:
		await game_end()


func update_time():
	var _time_elapsed_sec_before = time_elapsed_sec
	time_now = Time.get_unix_time_from_system()
	time_elapsed = time_now - time_start
	# Inspired by https://ask.godotengine.org/3641/how-display-elapsed-time-in-game
	time_elapsed_min = int(time_elapsed / 60)
	time_elapsed_sec = int(time_elapsed) % 60
	# For details on GDScript string formatting, see
	# https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_format_string.html#padding
	time_elapsed_string = str("%02d:%02d") % [time_elapsed_min, time_elapsed_sec]
	#time_elapsed_label.text = time_elapsed_string
	if (time_elapsed_sec - _time_elapsed_sec_before) > 0:
		Events.time_elapsed_1s.emit(time_elapsed_string)


func game_end():
	count_time = false
	present_spawn_timer.stop()
	await update_time()
	time_end = time_now
	Events.game_ended.emit(int(time_elapsed))
	# See tutorial on tweening by Bramwell on YouTube: https://www.youtube.com/watch?v=04TB9gxz-uM
	#player_end_position
	#var player_tween = player.create_tween()
	#player_tween.tween_property(
	#		player,
	#		"position",
	#		player_end_position.position,
	#		3.0
	#)
	print("GAME ENDED! :)\n")
	# Wait a bit until all spawned presents got removed
	await get_tree().create_timer(0.3).timeout
	highscore_screen = highscore_node.instantiate()
	#highscore_screen.z_index = 999
	add_child(highscore_screen)
	#print("Highscore screen added to node tree")


# Attention:
# This signal is crucial in avoiding a race condition
# when loading an online highscore.
# Calling the load function of the SilentWolf online highscore provider addon
# with "await" is not enough as it seems... :-/
func _on_highscore_screen_initialized():
	print("Highscore screen initialized, checking for new highscore now...")
	await highscore_screen.check_if_new_highscore(int(time_elapsed))


func _on_highscore_screen_continued():
	print("Highscore screen continued, switching to outro screen now...")
	# https://docs.godotengine.org/en/stable/tutorials/scripting/change_scenes_manually.html
	#get_tree().change_scene_to_file("res://scenes_and_scripts/outro_screen.tscn")
	SceneChanger.change_scene(
			get_tree().get_current_scene().get_name(),
			"res://scenes_and_scripts/outro_screen.tscn",
			0.4
	)


func play_random_bg_music():
	var _rand = randi_range(1, 2)
	if _rand == 1:
		bg_music_player.set_stream(bg_music_stream_1)
		bg_music_player.set_volume_db(bg_music_stream_1_volume)
	else:
		bg_music_player.set_stream(bg_music_stream_2)
		bg_music_player.set_volume_db(bg_music_stream_2_volume)
	bg_music_player.play()
