extends Node

#####################################
# Santa Catch, 2024                 #
# A game by Daniel the Fox          #
# https://danielthefox.itch.io      #
# https://github.com/Daniel-The-Fox #
#####################################


# Signals used in this game
signal audio_enabled
signal audio_decided
signal audio_muted
signal credits_screen_continued
signal credits_screen_opened
signal game_ended(score)
signal game_started
signal highscore_player_name_saved(player_name)
signal highscore_screen_continued
signal highscore_screen_initialized
signal intro_screen_continued
signal outro_screen_continued
signal present_catched
signal present_crashed_into_ground
signal present_crashed_into_present
signal present_spawned
signal scene_changed(from_scene, to_scene)
signal score_updated(presents_catched, presents_to_catch, game_progress)
signal title_screen_continued
signal time_elapsed_1s(time_elapsed_string)
