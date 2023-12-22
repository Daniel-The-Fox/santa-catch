extends Area2D

#####################################
# Santa Catch, 2024                 #
# A game by Daniel the Fox          #
# https://danielthefox.itch.io      #
# https://github.com/Daniel-The-Fox #
#####################################


# Nodes
@onready var catched_sfx_player = $CatchedSFXPlayer
@onready var player_collision_shape = $CollisionShape2D
@onready var player_node = $"."
@onready var player_sprite = $AnimatedSprite2D


# Export variables
@export var catched_sfx_stream_1: AudioStream
@export var catched_sfx_stream_2: AudioStream
@export var catched_sfx_stream_3: AudioStream
@export var catched_sfx_stream_4: AudioStream
@export var catched_sfx_stream_5: AudioStream

@export var player_movable: bool = true
@export var player_speed: int = 1250	# (pixels/second)


# General variables
var player_height
var player_width
var screen_size
var velocity = Vector2.ZERO


func _ready():
	screen_size = get_viewport_rect().size
	player_width = ceil(player_collision_shape.get_shape().get_rect().size.x * player_node.scale.x)
	player_height = ceil(player_collision_shape.get_shape().get_rect().size.y * player_node.scale.y)
	hide()
	Events.present_catched.connect(_on_present_catched)


func _process(delta):
	if player_movable:
		# For reference, see https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html
		if Input.is_action_pressed("move_left"):
			velocity = Vector2.LEFT
		elif Input.is_action_pressed("move_right"):
			velocity = Vector2.RIGHT
		else:
			velocity = Vector2.ZERO
		if velocity.length() > 0:
			velocity = velocity.normalized() * player_speed
		if velocity.x != 0:
			player_sprite.flip_h = velocity.x < 0
		position += velocity * delta
		position = position.clamp(
				Vector2.ZERO + Vector2(roundi(player_width/2), 0),
				screen_size - Vector2(roundi(player_width/2), 0),
		)


func play_random_catched_sfx():
	var _rand = randi_range(1, 5)
	if _rand == 1:
		catched_sfx_player.set_stream(catched_sfx_stream_1)
	elif _rand == 2:
		catched_sfx_player.set_stream(catched_sfx_stream_2)
	elif _rand == 3:
		catched_sfx_player.set_stream(catched_sfx_stream_3)
	elif _rand == 4:
		catched_sfx_player.set_stream(catched_sfx_stream_4)
	elif _rand == 5:
		catched_sfx_player.set_stream(catched_sfx_stream_5)
	else:
		catched_sfx_player.set_stream(catched_sfx_stream_1)
	catched_sfx_player.play()


func start(pos):
	position = pos
	show()
	if player_collision_shape:
		player_collision_shape.disabled = false


func _on_area_entered(_area):
	#if area.is_in_group("presents"):
	#	print("Catched a present! :)")
	pass


func _on_present_catched():
	await play_random_catched_sfx()
