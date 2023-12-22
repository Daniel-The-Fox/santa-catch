extends Area2D
class_name Present

#####################################
# Santa Catch, 2024                 #
# A game by Daniel the Fox          #
# https://danielthefox.itch.io      #
# https://github.com/Daniel-The-Fox #
#####################################


# States
enum State {STILL, FALLING, CATCHED, CRASHED}
enum FallingSpeedCategory {NONE, SLOW, MEDIUM, FAST}


# Nodes
@onready var present_node = $"."
@onready var present_sprite = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer
@onready var collision_shape = $CollisionShape2D
@onready var crash_sfx_player = $CrashSFXPlayer


# Export variables
@export var random_colors: bool = true
@export var paper_color_overwrite: Color = Color("265c42")
@export var ribbon_color_overwrite: Color = Color("e43b44")
@export var default_present_animation: String = "default"

@export var crash_animation_slow: String = "crash_slow"
@export var crash_animation_fast: String = "crash_fast"
@export var crash_animation_delay: float = 0.50

@export var crash_sfx_stream_1: AudioStream
@export var crash_sfx_stream_2: AudioStream
@export var crash_sfx_stream_3: AudioStream
@export var crash_sfx_stream_4: AudioStream
@export var crash_sfx_stream_5: AudioStream
@export var crash_sfx_stream_6: AudioStream
@export var crash_sfx_stream_7: AudioStream

@export var falling_automatically: bool = true
@export var falling_speed_slow: int = 250
@export var falling_speed_medium: int = 400
@export var falling_speed_fast: int = 700


# General variables
var height
var state := State.FALLING
var width
var falling_speed: int = falling_speed_medium
var falling_speed_category := FallingSpeedCategory.MEDIUM
var paper_color: Color
var ribbon_color: Color

# Present color combinations
# [paper_color, ribbon_color]
var color_combinations: Array = [
	[Color(0.753, 0.796, 0.863, 1.0), Color(0.894, 0.231, 0.267, 1.0)],		# c0cbdc, e43b44
	[Color(0.710, 0.306, 0.537, 1.0), Color(0.894, 0.231, 0.267, 1.0)],		# 124e89, e43b44
	[Color(0.000, 0.600, 0.859, 1.0), Color(0.894, 0.231, 0.267, 1.0)],		# 0099db, e43b44
	[Color(1.000, 0.000, 0.267, 1.0), Color(0.243, 0.537, 0.282, 1.0)],		# ff0044, 3e8948
	[Color(0.710, 0.306, 0.537, 1.0), Color(0.996, 0.906, 0.380, 1.0)],		# 124e89, fee761
	[Color(0.710, 0.314, 0.533, 1.0), Color(0.996, 0.906, 0.380, 1.0)],		# b55088, fee761
	[Color(0.722, 0.435, 0.314, 1.0), Color(0.388, 0.780, 0.302, 1.0)],		# b86f50, 63c74d
	[Color(0.149, 0.361, 0.259, 1.0), Color(0.894, 0.231, 0.267, 1.0)],		# 265c42, e43b44
	[Color(1.000, 1.000, 1.000, 1.0), Color(0.894, 0.231, 0.267, 1.0)],		# ffffff, e43b44
	[Color(0.918, 0.831, 0.667, 1.0), Color(0.969, 0.463, 0.133, 1.0)],		# ead4aa, f77622
	[Color(0.965, 0.459, 0.478, 1.0), Color(0.918, 0.831, 0.667, 1.0)],		# f6757a, ead4aa
	[Color(0.388, 0.780, 0.302, 1.0), Color(0.965, 0.459, 0.478, 1.0)],		# 63c74d, f6757a
	[Color(0.353, 0.412, 0.533, 1.0), Color(0.894, 0.231, 0.267, 1.0)],		# 5a6988, e43b44
	[Color(0.996, 0.682, 0.204, 1.0), Color(0.894, 0.231, 0.267, 1.0)],		# feae34, e43b44
	[Color(0.635, 0.149, 0.200, 1.0), Color(1.000, 1.000, 1.000, 1.0)],		# a22633, ffffff
	[Color(0.996, 0.906, 0.380, 1.0), Color(0.894, 0.231, 0.267, 1.0)],		# fee761, e43b44
	[Color(0.408, 0.220, 0.424, 1.0), Color(1.000, 1.000, 1.000, 1.0)],		# 68386c, ffffff
	[Color(0.980, 0.235, 0.243, 1.0), Color(1.000, 1.000, 1.000, 1.0)],		# 193c3e, ffffff
	[Color(0.710, 0.306, 0.537, 1.0), Color(1.000, 1.000, 1.000, 1.0)],		# 124e89, ffffff
	[Color(0.745, 0.290, 0.184, 1.0), Color(0.996, 0.682, 0.204, 1.0)],		# be4a2f, feae34
	[Color(0.000, 0.600, 0.859, 1.0), Color(0.710, 0.306, 0.537, 1.0)],		# 0099db, 124e89
	[Color(0.149, 0.361, 0.259, 1.0), Color(0.388, 0.780, 0.302, 1.0)],		# 265c42, 63c74d
	[Color(0.894, 0.231, 0.267, 1.0), Color(0.243, 0.153, 0.192, 1.0)],		# e43b44, 3e2731
]


func _ready():
	if falling_automatically:
		state = State.FALLING
		await set_random_fall_speed()
	else:
		state = State.STILL
		falling_speed = 0
		falling_speed_category = FallingSpeedCategory.NONE
	width = ceil(collision_shape.get_shape().get_rect().size.x * present_node.scale.x)
	height = ceil(collision_shape.get_shape().get_rect().size.y * present_node.scale.y)
	if random_colors:
		await set_random_colors()
	else:
		await change_colors(paper_color_overwrite, ribbon_color_overwrite)
	Events.game_ended.connect(_on_game_ended)


func _physics_process(delta):
	if state == State.FALLING:
		var velocity := Vector2.DOWN
		position += velocity * delta * falling_speed


func change_colors(color_1_new: Color, color_2_new: Color):
	self.material.set_shader_parameter("color_1_new", color_1_new)
	self.material.set_shader_parameter("color_2_new", color_2_new)
	paper_color = color_1_new
	ribbon_color = color_2_new


func get_random_crash_animation():
	var _anims = present_sprite.get_sprite_frames().get_animation_names()
	var _crash_animations:= []
	for _anim in _anims:
		#print("_anim: " + _anim)
		if _anim.match("crash*"):
			_crash_animations.append(_anim)
	var _crash_anim_to_play = _crash_animations[randi_range(0, _crash_animations.size()-1)]
	#print("random crash animation: " + _crash_anim_to_play)
	return _crash_anim_to_play


func play_crash_animation():
	#print("falling_speed_category: " + str(falling_speed_category))
	var _crash_anim_to_play: String
	if (
			falling_speed_category == FallingSpeedCategory.SLOW and
			present_sprite.get_sprite_frames().has_animation(crash_animation_slow)
	):
		_crash_anim_to_play = crash_animation_slow
	elif (
			falling_speed_category == FallingSpeedCategory.FAST and
			present_sprite.get_sprite_frames().has_animation(crash_animation_fast)
	):
		_crash_anim_to_play = crash_animation_fast
	else:
		_crash_anim_to_play = get_random_crash_animation()
	present_sprite.set_animation(_crash_anim_to_play)
	present_sprite.play(_crash_anim_to_play)
	await play_random_crash_sfx()
	await get_tree().create_timer(crash_animation_delay).timeout


func play_random_crash_sfx():
	var _rand = randi_range(1, 7)
	if _rand == 1:
		crash_sfx_player.set_stream(crash_sfx_stream_1)
	elif _rand == 2:
		crash_sfx_player.set_stream(crash_sfx_stream_2)
	elif _rand == 3:
		crash_sfx_player.set_stream(crash_sfx_stream_3)
	elif _rand == 4:
		crash_sfx_player.set_stream(crash_sfx_stream_4)
	elif _rand == 5:
		crash_sfx_player.set_stream(crash_sfx_stream_5)
	elif _rand == 6:
		crash_sfx_player.set_stream(crash_sfx_stream_6)
	elif _rand == 7:
		crash_sfx_player.set_stream(crash_sfx_stream_7)
	else:
		crash_sfx_player.set_stream(crash_sfx_stream_1)
	crash_sfx_player.play()


func set_random_colors():
	var _rand = randi_range(0, color_combinations.size())
	var color_1_new: Color
	var color_2_new: Color
	if _rand <= color_combinations.size()-1:
		#print(
		#		"picked random color combination #",
		#		_rand,
		#		": ",
		#		str(color_combinations[_rand]),
		#)
		color_1_new = color_combinations[_rand][0]
		color_2_new = color_combinations[_rand][1]
	else:
		color_1_new = Color(
			randf_range(0.0, 1.0),
			randf_range(0.0, 1.0),
			randf_range(0.0, 1.0),
			1.0
		)
		color_2_new = Color(
			randf_range(0.0, 1.0),
			randf_range(0.0, 1.0),
			randf_range(0.0, 1.0),
			1.0
		)
		#print(
		#		"generated random color combination: ",
		#		str(color_1_new),
		#		", ",
		#		str(color_2_new),
		#)
	change_colors(color_1_new, color_2_new)


func set_random_fall_speed():
	if animation_player:
		var fall_speeds = animation_player.get_animation_list()
		var _rst_anim = fall_speeds.find("RESET")
		if _rst_anim > -1:
			fall_speeds.remove_at(_rst_anim)
		animation_player.play(fall_speeds[randi() % fall_speeds.size()])
		var _curr_anim = animation_player.current_animation
		if _curr_anim.match("*slow"):
			falling_speed = falling_speed_slow
			falling_speed_category = FallingSpeedCategory.SLOW
		elif _curr_anim.match("*medium"):
			falling_speed = falling_speed_medium
			falling_speed_category = FallingSpeedCategory.MEDIUM
		elif _curr_anim.match("*fast"):
			falling_speed = falling_speed_fast
			falling_speed_category = FallingSpeedCategory.FAST
		else:
			falling_speed = falling_speed_medium
			falling_speed_category = FallingSpeedCategory.MEDIUM


func _on_area_entered(area):
	if state == State.FALLING and area.is_in_group("players"):
		state = State.CATCHED
		#print("Present got catched by player! :)")
		Events.present_catched.emit()
		queue_free()
	elif area.is_in_group("boundaries") and area.is_in_group("ground"):
		state = State.CRASHED
		collision_shape.set_deferred("disabled", true)
		#print("current rotation: " + str(rotation_degrees) + "°")
		# stopping animation here resets rotation angle to 0°
		# pausing animation here freezes current rotation angle as is
		# TODO: Rethink which option is better/nicer some time in the future, but let's keep stop() for now
		animation_player.stop()
		await play_crash_animation()
		Events.present_crashed_into_ground.emit()
		#print("Present crashed into the ground! :(")
		queue_free()
	elif area.is_in_group("presents"):
		#print("Presents crashed into each other... :-/")
		Events.present_crashed_into_present.emit()
	# Silently remove any other kind of unexpected crashes
	else:
		queue_free()


func _on_game_ended(_score):
	queue_free()
