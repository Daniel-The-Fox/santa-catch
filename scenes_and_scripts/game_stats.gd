extends Node

#####################################
# Santa Catch, 2024                 #
# A game by Daniel the Fox          #
# https://danielthefox.itch.io      #
# https://github.com/Daniel-The-Fox #
#####################################


# Global variables
# (accessible game-wide when added as autoload in Godot project) --> Singleton Pattern! ;-)
var AUDIO_ENABLED: bool = true
var AUDIO_MASTER_BUS_INDEX := AudioServer.get_bus_index("Master")
var GAME_VERSION: String = str("v" + str(ProjectSettings.get_setting("application/config/version")))
var IS_BROWSER_GAME: bool = OS.has_feature("web")
var PLAYER_NAME: String = ""
