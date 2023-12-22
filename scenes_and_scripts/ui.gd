extends CanvasGroup

#####################################
# Santa Catch, 2024                 #
# A game by Daniel the Fox          #
# https://danielthefox.itch.io      #
# https://github.com/Daniel-The-Fox #
#####################################


# Nodes
@onready var progress_bar = $UIBox/ProgressBar
@onready var time_elapsed_label = $UIBox/TimeElapsedLabel
@onready var ui_box = $UIBox


# Called when the node enters the scene tree for the first time.
func _ready():
	progress_bar.value = 0
	time_elapsed_label.text = "00:00"
	Events.score_updated.connect(_on_score_updated)
	Events.time_elapsed_1s.connect(_on_time_elapsed_1s)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_score_updated(presents_catched, presents_to_catch, _game_progress):
	progress_bar.value = int(_game_progress * 100)
	#print("game_progress in UI(): " + str(game_progress))


func _on_time_elapsed_1s(time_elapsed_string):
	time_elapsed_label.text = time_elapsed_string
	#print("time_elapsed_string in UI(): " + str(time_elapsed_string))
