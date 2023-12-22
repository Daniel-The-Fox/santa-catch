extends Node2D

#####################################
# Santa Catch, 2024                 #
# A game by Daniel the Fox          #
# https://danielthefox.itch.io      #
# https://github.com/Daniel-The-Fox #
#####################################


# Nodes
@onready var audio_enable_fade_anim = $AudioEnableScreen/AudioEnableFadeAnim
@onready var audio_enable_screen = $AudioEnableScreen
@onready var bg_sfx_player = $BGSFXPlayer
@onready var continue_animation = $ContinueAnimation
@onready var continue_msg_label = $ContinueLabel
@onready var credits_screen = $CreditsScreen
@onready var enable_audio_button = $AudioEnableScreen/AudioEnablePanel/AudioEnableMargin/HBoxContainer/EnableAudio/EnableAudioButton
@onready var intro_message = $IntroMessage
@onready var intro_message_fade_anim = $IntroMessage/IntroMessageFadeAnim
@onready var intro_voice_over = $IntroVoiceOver
@onready var mute_audio_button = $AudioEnableScreen/AudioEnablePanel/AudioEnableMargin/HBoxContainer/MuteAudio/MuteAudioButton
@onready var snow = $Snow
@onready var version_label = $VersionLabel


# Export variables
@export var continue_msg_clickable_delay: float = 0.5
@export var continue_msg_show_delay: float = 2.0
@export var voice_over_delay: float = 1.5


# General variables
var handle_input: bool = false
var credits_screen_opened: bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	update_version_label()
	intro_message_fade_anim.set_current_animation("fade_in")
	intro_message_fade_anim.stop()
	intro_message.hide()
	credits_screen.hide()
	continue_msg_label.hide()
	# Let it snow, let it snow, let it snow... :)
	snow.show()
	audio_enable_fade_anim.set_current_animation("fade_in")
	audio_enable_fade_anim.stop()
	audio_enable_screen.hide()
	if GameStats.IS_BROWSER_GAME:
		Events.audio_enabled.connect(_on_audio_decided)
		Events.audio_muted.connect(_on_audio_decided)
		await audio_enable_fade_in()
		await Events.audio_decided
	Events.credits_screen_opened.connect(_on_credits_screen_opened)
	Events.credits_screen_continued.connect(_on_credits_screen_continued)
	intro_voice_over.finished.connect(_on_voice_over_finished)
	# This shows the credits screen button (contained in the credits scene).
	# The credits scene itself then manages if the credits text is shown or not (default)
	credits_screen.show()
	if GameStats.AUDIO_ENABLED:
		# Jingle them bells Rudolph! ;p
		bg_sfx_player.play()
		await get_tree().create_timer(voice_over_delay).timeout
		intro_voice_over.play()
	await fade_in_intro_message()
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
			intro_voice_over.stop()
			#get_tree().change_scene_to_file("res://scenes_and_scripts/main.tscn")
			SceneChanger.change_scene(
					get_tree().get_current_scene().get_name(),
					"res://scenes_and_scripts/main.tscn",
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
	print("Intro voice-over finished")


func show_continue_msg():
	continue_msg_label.set_self_modulate(Color(1, 1, 1, 0))
	continue_msg_label.show()
	continue_animation.play("blink_continue_text")
	await get_tree().create_timer(continue_msg_clickable_delay).timeout


func update_version_label():
	version_label.text = GameStats.GAME_VERSION
	version_label.show()
	print("Version info: " + version_label.text)


func _on_enable_audio_button_pressed():
	print("AudioEnable button pressed -> Audio enabled! :)")
	AudioServer.set_bus_mute(GameStats.AUDIO_MASTER_BUS_INDEX, false)
	GameStats.AUDIO_ENABLED = true
	Events.audio_enabled.emit()


func _on_enable_audio_button_mouse_entered():
	enable_audio_button.set_modulate("e43b44")


func _on_enable_audio_button_mouse_exited():
	enable_audio_button.set_modulate("ffffff")


func _on_mute_audio_button_pressed():
	print("MuteEnable button pressed -> Audio muted! :(")
	AudioServer.set_bus_mute(GameStats.AUDIO_MASTER_BUS_INDEX, true)
	GameStats.AUDIO_ENABLED = false
	Events.audio_muted.emit()


func _on_mute_audio_button_mouse_entered():
	mute_audio_button.set_modulate("e43b44")


func _on_mute_audio_button_mouse_exited():
	mute_audio_button.set_modulate("ffffff")


func _on_audio_decided():
	Events.audio_decided.emit()
	await audio_enable_fade_out()


func audio_enable_fade_in():
	audio_enable_screen.show()
	audio_enable_fade_anim.play("fade_in")
	await audio_enable_fade_anim.animation_finished


func audio_enable_fade_out():
	audio_enable_fade_anim.play_backwards("fade_in")
	await audio_enable_fade_anim.animation_finished
	audio_enable_screen.hide()


func fade_in_intro_message():
	intro_message.show()
	intro_message_fade_anim.play("fade_in")
	await intro_message_fade_anim.animation_finished
