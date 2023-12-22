extends Node2D

#####################################
# Santa Catch, 2024                 #
# A game by Daniel the Fox          #
# https://danielthefox.itch.io      #
# https://github.com/Daniel-The-Fox #
#####################################


# Constants
const SILENT_WOLF_KEY_FILE = "res://silent_wolf_api_key.dat"
const HIGHSCORE_FILE_PATH = "user://highscore.dat"
const NUMBER_OF_PLAYERS = 10


# Nodes
@onready var continue_button = $Highscore/HighscorePanel/ContinueButton
@onready var highscore = $Highscore
@onready var highscore_fade_anim = $Highscore/HighscoreFadeAnim
@onready var highscore_title_label = $Highscore/HighscorePanel/HighScoreTitleLabel
@onready var loading = $Loading
@onready var player_name_input = $PlayerNameInput
@onready var player_name_input_field = $PlayerNameInput/PlayerNameInputPanel/CanvasGroup/PlayerNameInputField
@onready var player_name_save_button = $PlayerNameInput/PlayerNameInputPanel/CanvasGroup/SaveButton
@onready var player_name_v_box = $Highscore/HighscorePanel/BoxContainer/HighscoreHBox/PlayerNameVBox
@onready var position_v_box = $Highscore/HighscorePanel/BoxContainer/HighscoreHBox/PositionVBox
@onready var score_v_box = $Highscore/HighscorePanel/BoxContainer/HighscoreHBox/ScoreVBox


# Export variables
@export var debug_mode_highscore: bool = false
@export var debug_mode_delay_sec: float = 2.0
@export var enforce_online_highscore: bool = false
@export var highscore_fade_delay_sec: float = 0.2
@export var online_highscore_save_delay_sec: float = 0.01
@export var wipe_online_highscore_before_save: bool = false
@export var wipe_online_highscore_delay_sec: float = 0.1


# General variables
var highscore_dict: Dictionary = {}
var is_new_highscore: bool = false
var handle_input: bool = false
var player_name: String = ""
var online_highscore: bool = GameStats.IS_BROWSER_GAME
var online_highscore_config_success: bool = false
var online_str: String = (" online ") if online_highscore else (" local ")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	highscore_fade_anim.set_current_animation("fade_in")
	highscore_fade_anim.stop()
	highscore.hide()
	continue_button.hide()
	player_name_input.hide()
	await _enable_loading()
	if debug_mode_highscore:
		print("DEBUG MODE ENABLED!")
	if enforce_online_highscore:
		print("ONLINE HIGHSCORE ENFORCED!")
		online_highscore = true
		online_str = (" online ") if online_highscore else (" local ")
	await init_highscore()
	if debug_mode_highscore:
		await get_tree().create_timer(debug_mode_delay_sec).timeout
		await _enable_loading()
		print("Overwriting current highscore with dummy values")
		await set_dummy_values()
		await save_highscore()
		await get_tree().create_timer(debug_mode_delay_sec).timeout
		await load_highscore()
		await update_highscore_screen()
		await _disable_loading()
	await fade_in()
	continue_button.show()
	handle_input = true
	# Attention:
	# This signal is crucial in avoiding a race condition
	# when loading an online highscore.
	# Calling the load function of the SilentWolf online highscore provider addon
	# with "await" is not enough as it seems... :-/
	Events.highscore_screen_initialized.emit()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	pass


func _input(event):
	if handle_input:
		if (
				# Enter or Space keyboard key pressed
				# For reference, see https://docs.godotengine.org/en/stable/tutorials/inputs/input_examples.html#keyboard-events
				(
						event is InputEventKey
						and event.pressed
						and (
								event.keycode == KEY_ENTER
								or
								event.keycode == KEY_SPACE
						)
				)
				or
				# Triggered input action "continue" from project input map
				# For reference, see https://docs.godotengine.org/en/stable/tutorials/inputs/input_examples.html#capturing-actions
				event.is_action_pressed("continue")
		):
			# Save button for player name
			if highscore.is_visible() and player_name_input.is_visible():
				player_name_save_button.pressed.emit()
			# Continue button of highscore screen
			elif highscore.is_visible() and not player_name_input.is_visible():
				continue_button.pressed.emit()


func init_highscore():
	await set_position_defaults()
	await reset_highscore()
	await update_highscore_screen()
	if online_highscore:
		print("Game is running in a web browser!")
		highscore_title_label.text = "Online " + highscore_title_label.text
		await configure_online_highscore()
		print("online_highscore_config_success: " + str(online_highscore_config_success))
	else:
		highscore_title_label.text = "Local " + highscore_title_label.text
	if (
			(online_highscore and online_highscore_config_success)
			or not online_highscore
	):
		await load_highscore()
		await update_highscore_screen()
	await _disable_loading()


func check_if_new_highscore(_score: int = 0):
	if online_highscore and not online_highscore_config_success:
		print(
				"Skipping check for new online highscore ",
				"as online highscore doesn't seem to be configured!",
		)
		return false
	print(
			"Checking if timing is a new" + online_str +
			"highscore: " + str(_score)
	)
	if _score != 0:
		# Attention:
		# Scores (in this case timings) have to be stored as negative integers,
		# so that the lowest timing is best
		_score *= -1
		var _highscore_dict_new: Dictionary = {}
		for _i in range(1, NUMBER_OF_PLAYERS + 1):
			if highscore_dict.has("player_" + str(_i)):
				# Highscore entry seems empty
				# -> Add new highscore entry
				if (
						not is_new_highscore
						and len(highscore_dict["player_" + str(_i)]["name"]) == 0
						and highscore_dict["player_" + str(_i)]["score"] == 0
				):
					print("Highscore entry #" + str(_i) + " seemed empty")
					_highscore_dict_new["player_" + str(_i)] = (
						await _get_new_highscore_entry(_i, _score)
					)
				# Better score than currently looped existing highscore entry
				# -> Add new highscore entry
				elif (
						not is_new_highscore
						and _score > highscore_dict["player_" + str(_i)]["score"]
				):
					print("New" + online_str + "highscore! :)")
					_highscore_dict_new["player_" + str(_i)] = (
						await _get_new_highscore_entry(_i, _score)
					)
				# New highscore entry has been added,
				# so pick previous highscore entry now to move all entries one down
				elif is_new_highscore:
					_highscore_dict_new["player_" + str(_i)] = (
							highscore_dict["player_" + str(_i - 1)]
					)
				# Not a new highscore (yet), continue looking/looping
				else:
					_highscore_dict_new["player_" + str(_i)] = (
							highscore_dict["player_" + str(_i)]
					)
		if is_new_highscore:
			highscore_dict = _highscore_dict_new.duplicate()
			await _enable_loading()
			await save_highscore()
			await update_highscore_screen()
			await _disable_loading()
		else:
			print("No highscore this time! :(")


func _get_new_highscore_entry(_i: int, _score: int) -> Dictionary:
	var _dict: Dictionary
	is_new_highscore = true
	await _get_player_name_input()
	_dict = {
		"name": player_name,
		"score": _score,
	}
	print("New highscore entry:")
	print(
			"player_" + str(_i) + ": ",
			str(_dict),
	)
	return _dict


# Format score as mm:ss
func format_score(_score: int) -> String:
	#print("Formatting " + str(_score))
	# Inspired by https://ask.godotengine.org/3641/how-display-elapsed-time-in-game
	var _min: int = int(float(_score) / 60.0)
	var _sec: int = int(_score % 60)
	# For details on GDScript string formatting, see
	# https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_format_string.html#padding
	var _timing_str = str("%02d:%02d") % [_min, _sec]
	return str(_timing_str)


func load_highscore():
	if online_highscore:
		await load_online_highscore()
	else:
		await load_offline_highscore()
	await print_highscore()


func load_offline_highscore():
	var _highscore_file: FileAccess
	if not FileAccess.file_exists(HIGHSCORE_FILE_PATH):
		print("Highscore file didn't exist yet. Creating it at '" + HIGHSCORE_FILE_PATH + "'")
		_highscore_file = FileAccess.open(HIGHSCORE_FILE_PATH, FileAccess.WRITE)
		_highscore_file.close()
		await reset_highscore()
		return true
	print("Loading highscore from '" + HIGHSCORE_FILE_PATH + "'")
	_highscore_file = FileAccess.open(HIGHSCORE_FILE_PATH, FileAccess.READ)
	var _json_string = _highscore_file.get_as_text()
	var json = JSON.new()
	var _parse_result = json.parse(_json_string)
	if not _parse_result == OK:
		print(
				"JSON Parse Error: ", json.get_error_message(), " in ",
				_json_string, " at line ", json.get_error_line()
		)
	var _json_data = json.get_data()
	if _json_data:
		for _i in range(1, NUMBER_OF_PLAYERS + 1):
			if _json_data.has("player_" + str(_i)):
				highscore_dict["player_" + str(_i)] = _json_data["player_" + str(_i)]
			else:
				highscore_dict["player_" + str(_i)] = {
					"name": "",
					"score": 0,
				}
	else:
		print(
				"Resetting highscore as highscore file '",
				HIGHSCORE_FILE_PATH,
				"' is empty.",
		)
		await reset_highscore()
	_highscore_file.close()


func load_online_highscore():
	print("Loading online highscore...")
	var sw_result: Dictionary = (
			await SilentWolf.Scores.
			get_scores(NUMBER_OF_PLAYERS).sw_get_scores_complete
	)
	print("SilentWolf Scores: " + str(sw_result.scores))
	var _i = 1
	var _entries = sw_result.scores.size()
	if _entries >= 1:
		print("Current entries in online highscore: " + str(_entries))
		for score in sw_result.scores:
			if len(score.player_name) > 1:
				highscore_dict["player_" + str(_i)] = {
					"name": score.player_name,
					"score": score.score,
				}
			else:
				highscore_dict["player_" + str(_i)] = {
					"name": "",
					"score": 0,
				}
			_i += 1
	else:
		print("Resetting highscore as answer from online highscore server was empty.")
		await reset_highscore()


func reset_highscore():
	print("Resetting highscore_dict")
	highscore_dict.clear()
	for _i in range(1, NUMBER_OF_PLAYERS + 1):
		highscore_dict["player_" + str(_i)] = {
			"name": "",
			"score": 0,
		}


func save_highscore():
	if online_highscore:
		if wipe_online_highscore_before_save:
			if debug_mode_highscore:
				await get_tree().create_timer(wipe_online_highscore_delay_sec).timeout
			print("ATTENTION: Wiping online highscore before saving new online highscore, as configured!")
			await do_wipe_online_highscore()
		await save_online_highscore()
	else:
		await save_offline_highscore()
	await print_highscore()


func save_offline_highscore():
	print("Saving highscore to '" + HIGHSCORE_FILE_PATH + "'")
	var _highscore_file = FileAccess.open(HIGHSCORE_FILE_PATH, FileAccess.WRITE)
	var _json_string = JSON.stringify(highscore_dict)
	_highscore_file.store_line(_json_string)
	_highscore_file.close()


func save_online_highscore():
	print("Saving online highscore")
	for _i in range(1, NUMBER_OF_PLAYERS + 1):
		if highscore_dict.has("player_" + str(_i)):
			if (
					len(highscore_dict["player_" + str(_i)]["name"]) > 1
					and highscore_dict["player_" + str(_i)]["score"] != 0
			):
				print(
						"Saving highscore entry #",
						_i,
						" on server: ",
						str(highscore_dict["player_" + str(_i)]),
				)
				await SilentWolf.Scores.save_score(
						highscore_dict["player_" + str(_i)]["name"],
						highscore_dict["player_" + str(_i)]["score"],
				)
				await get_tree().create_timer(online_highscore_save_delay_sec).timeout


func set_position_defaults():
	print("Initializing highscore position numbers")
	for _i in range(1, NUMBER_OF_PLAYERS + 1):
		var _txt: String = ""
		if _i < 10:
			_txt += "0"
		_txt += str(_i)
		position_v_box.get_node("Position" + str(_i)).text = _txt


func update_highscore_screen():
	print("Updating" + online_str + "highscore screen...")
	for _i in range(1, NUMBER_OF_PLAYERS + 1):
		if highscore_dict.has("player_" + str(_i)):
			player_name_v_box.get_node("Name" + str(_i)).text = (
					highscore_dict["player_" + str(_i)]["name"]
			)
			score_v_box.get_node("Score" + str(_i)).text = (
					format_score(abs(highscore_dict["player_" + str(_i)]["score"]))
			)


func print_highscore():
	for _i in range(1, NUMBER_OF_PLAYERS + 1):
		if highscore_dict.has("player_" + str(_i)):
			print(
					"player_" + str(_i) + ": " +
					str(highscore_dict["player_" + str(_i)])
			)


func _get_player_name_input():
	continue_button.hide()
	player_name_input.show()
	if len(GameStats.PLAYER_NAME) > 0:
		player_name_input_field.text = GameStats.PLAYER_NAME
	else:
		player_name_input_field.text = get_random_player_name()
	await Events.highscore_player_name_saved
	player_name_input.hide()
	continue_button.show()


func get_random_player_name():
	var _rnd_name = RandomPlayerName.new()
	var _random_player_name = _rnd_name.get_random_player_name()
	print("random player name: " + _random_player_name)
	return _random_player_name


func _on_continue_button_pressed() -> void:
	#print("Continue button pressed")
	Events.highscore_screen_continued.emit()


func _on_regenerate_name_pressed() -> void:
	player_name_input_field.text = get_random_player_name()


func _on_save_button_pressed() -> void:
	player_name = player_name_input_field.text
	GameStats.PLAYER_NAME = player_name
	Events.highscore_player_name_saved.emit(player_name)


# Expects Silent Wolf key file at SILENT_WOLF_KEY_FILE (i.e. res://silent_wolf_key.dat)
# The key file should contain two key, value pairs
# "silent_wolf_api_key": "<Your Silent Wolf API key>",
# "silent_wolf_game_id": "<Your Silent Wolf game id>"
func configure_online_highscore():
	var _sw_api_key = ""
	var _sw_game_id = ""
	if not FileAccess.file_exists(SILENT_WOLF_KEY_FILE):
		print(
				"ERROR: Silent Wolf key file expected at '" +
				SILENT_WOLF_KEY_FILE + "' doesn't exist!"
		)
		return false
	var _sw_key_file = FileAccess.open(SILENT_WOLF_KEY_FILE, FileAccess.READ)
	var _sw_key_json_str = _sw_key_file.get_as_text()
	var _sw_json = JSON.new()
	var _sw_key_parse_res = _sw_json.parse(_sw_key_json_str)
	if not _sw_key_parse_res == OK:
		print(
				"JSON Parse Error: ", _sw_json.get_error_message(), " in ",
				_sw_key_json_str, " at line ", _sw_json.get_error_line()
		)
	var _sw_key_json_data = _sw_json.get_data()
	if _sw_key_json_data:
		if _sw_key_json_data.has("silent_wolf_api_key"):
			_sw_api_key = _sw_key_json_data["silent_wolf_api_key"]
		else:
			print(
					"ERROR: Silent Wolf key file located at '" +
					SILENT_WOLF_KEY_FILE +
					"' doesn't contain the key 'silent_wolf_api_key'!"
			)
			return false
		if _sw_key_json_data.has("silent_wolf_game_id"):
			_sw_game_id = _sw_key_json_data["silent_wolf_game_id"]
		else:
			print(
					"ERROR: Silent Wolf key file located at '" +
					SILENT_WOLF_KEY_FILE +
					"' doesn't contain the key 'silent_wolf_game_id'!"
			)
			return false
	else:
		print(
				"ERROR: Silent Wolf key file located at '" +
				SILENT_WOLF_KEY_FILE + "' is empty!"
		)
		return false
	# See https://silentwolf.com/leaderboard
	# amount of logging in the console from SilentWolf
	# 0 for errors only,
	# 1 for info-level logging and
	# 2 for debug logging
	if debug_mode_highscore:
		print("Printing SilentWolf key data only when debug mode is enabled:")
		print("    SW API Key: " + _sw_api_key)
		print("    SW Game ID: " + _sw_game_id)
	if len(_sw_api_key) > 3 and len(_sw_game_id) > 3:
		var _sw_auth_success = await SilentWolf.configure({
				"api_key": _sw_api_key,
				"game_id": _sw_game_id,
				"log_level": 0,
		})
		if debug_mode_highscore:
			print("_sw_auth_success: " + str(_sw_auth_success))
	else:
		print(
				"Unexpected error while reading and applying Silent Wolf key file at '" +
				SILENT_WOLF_KEY_FILE + "'!"
		)
		return false
	online_highscore_config_success = true
	return true


func do_wipe_online_highscore():
	await SilentWolf.Scores.wipe_leaderboard()
	await get_tree().create_timer(wipe_online_highscore_delay_sec).timeout


func fade_in():
	await get_tree().create_timer(highscore_fade_delay_sec).timeout
	highscore.show()
	highscore_fade_anim.play("fade_in")
	await highscore_fade_anim.animation_finished


func fade_out():
	highscore_fade_anim.play_backwards("fade_in")
	await highscore_fade_anim.animation_finished
	highscore.hide()


func _enable_loading():
	#highscore.hide()
	loading.show()


func _disable_loading():
	loading.hide()
	#highscore.show()


func set_dummy_values():
	highscore_dict.clear()
	highscore_dict = {
		"player_1": {
			"name": get_random_player_name(),		#"InterestingRudolph",
			"score": -4,
		},
		"player_2": {
			"name": get_random_player_name(),		#"InterestingSantaClaus",
			"score": -60,
		},
		"player_3": {
			"name": get_random_player_name(),		#"InterestingDonner",
			"score": -190,
		},
		"player_4": {
			"name": get_random_player_name(),		#"InterestingBlitzer",
			"score": -1800,
		},
		"player_5": {
			"name": get_random_player_name(),		#"InterestingDapper",
			"score": -1900,
		},
		"player_6": {
			"name": get_random_player_name(),		#"InterestingAngel",
			"score": -2000,
		},
		"player_7": {
			"name": get_random_player_name(),		#"InterestingElve",
			"score": -2100,
		},
		"player_8": {
			"name": get_random_player_name(),		#"InterestingSnowman",
			"score": -2200,
		},
		"player_9": {
			"name": get_random_player_name(),		#"InterestingDonder",
			"score": -2300,
		},
		"player_10": {
			"name": get_random_player_name(),		#"InterestingFlossie",
			"score": -5000,
		},
	}
	await print_highscore()
