class_name RandomPlayerName
extends GDScript

#####################################
# Santa Catch, 2024                 #
# A game by Daniel the Fox          #
# https://danielthefox.itch.io      #
# https://github.com/Daniel-The-Fox #
#####################################


###
# Inspired by name generator for Docker containers
# See https://github.com/moby/moby/blob/master/pkg/namesgenerator/names-generator.go
###


const NAMES_LEFT_PART = [
	"Admiring",
	"Adoring",
	"Amazing",
	"Angry",
	"Awesome",
	"Beautiful",
	"Bold",
	"Brave",
	"Busy",
	"Charming",
	"Clever",
	"Competent",
	"Confident",
	"Cool",
	"Cranky",
	"Crazy",
	"Dazzling",
	"Determined",
	"Distracted",
	"Dreamy",
	"Eager",
	"Elastic",
	"Elegant",
	"Eloquent",
	"Epic",
	"Exciting",
	"Festive",
	"Focused",
	"Friendly",
	"Frosty",
	"Funny",
	"Gallant",
	"Gifted",
	"Goofy",
	"Gracious",
	"Great",
	"Happy",
	"Hardcore",
	"Heuristic",
	"Hopeful",
	"Hungry",
	"Inspiring",
	"Intelligent",
	"Interesting",
	"Jolly",
	"Keen",
	"Kind",
	"Laughing",
	"Loving",
	"Lucid",
	"Magical",
	"Modest",
	"Naughty",
	"Nervous",
	"Nice",
	"Nifty",
	"Nostalgic",
	"Objective",
	"Optimistic",
	"Peaceful",
	"Pedantic",
	"Pensive",
	"Practical",
	"Priceless",
	"Quirky",
	"Recursing",
	"Relaxed",
	"Reverent",
	"Romantic",
	"Sad",
	"Serene",
	"Sharp",
	"Silly",
	"Sleepy",
	"Stoic",
	"Suspicious",
	"Sweet",
	"Thirsty",
	"Trusting",
	"Upbeat",
	"Vibrant",
	"Vigilant",
	"Vigorous",
	"Wizardly",
	"Wonderful",
	"Youthful",
]

# Christmas-related names
# Names for Santa's reindeers taken from Wikipedia, for details see
# https://en.wikipedia.org/wiki/Santa_Claus%27s_reindeer
const NAMES_RIGHT_PART = [
	"Santa",
	"Angel",
	"Elve",
	"Snowman",
	"Rudoplh",
	"Reindeer",
	"SantaClaus",
	"Claus",
	"Nicholas",
	"SaintNicholas",
	"Dasher",
	"Dancer",
	"Prancer",
	"Vixen",
	"Comet",
	"Cupid",
	"Dunder",
	"Blixem",
	"Donder",
	"Blitzen",
	"Donner",
	"Flossie",
	"Glossie",
	"Racer",
	"Pacer",
	"Reckless",
	"Speckless",
	"Fearless",
	"Peerless",
	"Ready",
	"Steady",
	"Nikolaus",
]


func _init():
	pass


func get_random_player_name():
	var _random_left_part = NAMES_LEFT_PART[randi_range(0, NAMES_LEFT_PART.size()-1)]
	var _random_right_part = NAMES_RIGHT_PART[randi_range(0, NAMES_RIGHT_PART.size()-1)]
	return _random_left_part + _random_right_part
