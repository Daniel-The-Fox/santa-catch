extends CanvasLayer

#####################################
# Santa Catch, 2024                 #
# A game by Daniel the Fox          #
# https://danielthefox.itch.io      #
# https://github.com/Daniel-The-Fox #
#####################################


# Nodes
@onready var color_rect = $Control/ColorRect
@onready var animation_player = $AnimationPlayer


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func change_scene(from_scene: String, to_scene: String, delay_sec: float = 0.5):
	print(
			"Switching from ",
			from_scene,
			" scene to \"",
			to_scene,
			"\" after a delay of ",
			str(delay_sec),
			" seconds",
	)
	await get_tree().create_timer(delay_sec).timeout
	animation_player.play("fade")
	await animation_player.animation_finished
	assert(get_tree().change_scene_to_file(to_scene) == OK)
	animation_player.play_backwards("fade")
	await animation_player.animation_finished
	Events.scene_changed.emit(from_scene, to_scene)
