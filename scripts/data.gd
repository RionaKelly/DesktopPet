## This script loads the pet's data from a save file for the game to use

extends Node

# Establish starting variables to be used globally
var nickname: String # Pet's name, shows in UI and as Window title
var fullness: float # Pet's hunger, 100 = full
var happiness: float # Pet's happiness, 100 = happy
var age: int # How old the pet is in minutes
var stage: int # How many evolution's the pet has undergone
var money: int # How much money the player/pet has
var type: int # What species the pet is
var pattern: int # Current pattern of Pet 
var personality: int # Current personality of Pet
var most_bounces: int # The most times the pet has bounced off of the wall without touching the ground
var leave_count: int # How many updates the pet has been at 0 of a stat for, when too high they will leave
var silent: bool # Whether the app should not send alerts as to bother less
var main_screen: int # Screen for pet to be confined to, will be changed later
var shader_on: bool # Whether the pet should use the distortion shade or not, changed in settings
var large_hitbox: bool # Whether the pet should keep the default window-size hitbox for accesibility
var open_menu: bool # Whether the menu should open automatically on start
var keep_pattern: bool # When enabled, pet won't change pattern when evolving
var save_game: bool # Whether the game should save


func _ready() -> void:
	var config := ConfigFile.new()
	if config.load("user://data.cfg") != OK: # Load file and check if it is loaded ok
		print("No data found, using default")
	# Set the variables to the found data, final argument is the default for if no Config File is found
	nickname = config.get_value("pet", "nickname", "Pet")
	fullness = config.get_value("pet", "fullness", 80.0)
	happiness = config.get_value("pet", "happiness", 80.0)
	age = config.get_value("pet", "age", 0)
	stage = config.get_value("pet", "stage", 0)
	money = config.get_value("pet", "money", 0)
	type = config.get_value("pet", "type", -1) # default value isn't a valid type, so that it is randomised in pet.gd later
	pattern = config.get_value("pet", "pattern", 0)
	personality = config.get_value("pet", "personality", 0)
	most_bounces = config.get_value("pet", "most_bounces", 0)
	leave_count = config.get_value("pet", "leave_count", 0)
	silent = config.get_value("settings", "silent", false)
	main_screen = config.get_value("settings", "main_screen", DisplayServer.get_primary_screen())
	shader_on = config.get_value("settings", "shader_on", false)
	large_hitbox = config.get_value("settings", "large_hitbox", false)
	open_menu = config.get_value("settings", "open_menu", true)
	keep_pattern = config.get_value("settings", "keep_pattern", false)
	save_game = config.get_value("settings", "save_game", true)
