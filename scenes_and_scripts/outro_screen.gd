extends Node2D

#####################################
# Santa Catch, 2024                 #
# A game by Daniel the Fox          #
# https://danielthefox.itch.io      #
# https://github.com/Daniel-The-Fox #
#####################################


# Nodes
@onready var bg_sfx_player = $BGSFXPlayer
@onready var continue_animation = $ContinueAnimation
@onready var continue_msg_label = $ContinueLabel
@onready var credits_screen = $CreditsScreen
@onready var merry_christmas = $MerryChristmas
@onready var outro_voice_over = $OutroVoiceOver
@onready var player = $Player
@onready var snow = $Snow


# Export variables
@export var continue_msg_clickable_delay: float = 0.2
@export var continue_msg_show_delay: float = 0.0
@export var voice_over_delay: float = 0.5


# General variables
var handle_input: bool = false
var credits_screen_opened: bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	Events.credits_screen_opened.connect(_on_credits_screen_opened)
	Events.credits_screen_continued.connect(_on_credits_screen_continued)
	outro_voice_over.finished.connect(_on_voice_over_finished)
	continue_msg_label.hide()
	# Let it snow, let it snow, let it snow... :)
	snow.show()
	player.show()
	# This shows the credits screen button (contained in the credits scene).
	# The credits scene itself then manages if the credits text is shown or not (default)
	credits_screen.show()
	if GameStats.AUDIO_ENABLED:
		# Jingle them bells Rudolph! ;p
		bg_sfx_player.play()
		await get_tree().create_timer(voice_over_delay).timeout
		outro_voice_over.play()
		await outro_voice_over.finished
		merry_christmas.play()
	await get_tree().create_timer(continue_msg_show_delay).timeout
	show_continue_msg()
	if not credits_screen_opened:
		handle_input = true


func _input(event):
	if handle_input:
		if (
				# Any keyboard key pressed, except ESC key
				# For reference, see https://docs.godotengine.org/en/stable/tutorials/inputs/input_examples.html#keyboard-events
				(event is InputEventKey and event.pressed and event.keycode != KEY_ESCAPE)
				or
				# Triggered input action "continue" from project input map
				# For reference, see https://docs.godotengine.org/en/stable/tutorials/inputs/input_examples.html#capturing-actions
				event.is_action_pressed("continue")
		):
			Events.title_screen_continued.emit()
			outro_voice_over.stop()
			#get_tree().change_scene_to_file("res://scenes_and_scripts/title_screen.tscn")
			SceneChanger.change_scene(
					get_tree().get_current_scene().get_name(),
					"res://scenes_and_scripts/title_screen.tscn",
					0.5
			)


func _on_credits_screen_opened():
	handle_input = false
	credits_screen_opened = true
	#print("CreditsScreen opened")


func _on_credits_screen_continued():
	handle_input = true
	credits_screen_opened = false
	#print("CreditsScreen closed")


func _on_voice_over_finished():
	print("Outro voice-over finished")


func show_continue_msg():
	continue_msg_label.set_self_modulate(Color(1, 1, 1, 0))
	continue_msg_label.show()
	continue_animation.play("blink_continue_text")
	await get_tree().create_timer(continue_msg_clickable_delay).timeout
