extends CanvasGroup

#####################################
# Santa Catch, 2024                 #
# A game by Daniel the Fox          #
# https://danielthefox.itch.io      #
# https://github.com/Daniel-The-Fox #
#####################################


# Nodes
@onready var back_button = $Credits/BackButton
@onready var credits_node = $Credits
@onready var credits_button = $CreditsButton
@onready var credits_fade_in = $Credits/CreditsFadeIn
@onready var credits_text = $Credits/CreditsText


# Called when the node enters the scene tree for the first time.
func _ready():
	credits_node.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_credits_button_pressed():
	#print("Credits button pressed")
	if credits_node.is_visible():
		await fade_out()
		Events.credits_screen_continued.emit()
	else:
		await fade_in()
		Events.credits_screen_opened.emit()


func _on_back_button_pressed():
	#print("Close button pressed")
	await fade_out()
	Events.credits_screen_continued.emit()


# RichTextLabel's meta_clicked signal is connected to this function
# to open URLs clicked on in the credits text
# See https://docs.godotengine.org/en/stable/tutorials/ui/bbcode_in_richtextlabel.html
func _on_credits_text_meta_clicked(meta):
	# meta is not guaranteed to be a String, so convert it to a String
	# to avoid script errors at run-time.
	OS.shell_open(str(meta))


func fade_in():
	credits_node.show()
	credits_fade_in.play("fade_in")
	await credits_fade_in.animation_finished


func fade_out():
	credits_fade_in.play_backwards("fade_in")
	await credits_fade_in.animation_finished
	credits_node.hide()
