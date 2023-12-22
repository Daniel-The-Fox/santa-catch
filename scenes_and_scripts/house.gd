extends AnimatedSprite2D

#####################################
# Santa Catch, 2024                 #
# A game by Daniel the Fox          #
# https://danielthefox.itch.io      #
# https://github.com/Daniel-The-Fox #
#####################################


# Nodes
@onready var house_animated_sprite = $"."


# General variables
var house_animations


# Called when the node enters the scene tree for the first time.
func _ready():
	house_animations = house_animated_sprite.sprite_frames.get_animation_names()
	#print("house_animations: " + str(house_animations))
	await set_random_animation()
	house_animated_sprite.animation_finished.connect(set_random_animation)
	house_animated_sprite.animation_looped.connect(set_random_animation)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func set_random_animation():
	var _rnd_anim = house_animations[randi_range(0,house_animations.size() - 1)]
	#print("random house animation: " + _rnd_anim)
	house_animated_sprite.play(_rnd_anim)
