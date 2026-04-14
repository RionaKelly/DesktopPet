## This script loads the pet's data from a save file for the game to use

extends Node

# Establish starting variables to be used globally
var nickname: String # Pet's name, shows in UI and as Window title
var fullness: int # Pet's hunger, 100 = full
var happiness: int # Pet's happiness, 100 = happy
var age: int # How old the pet is in minutes
var stage: int # How many evolution's the pet has undergone
var money: int # How much money the player/pet has
var type: int # What species the pet is
var pattern: int # Current pattern of Pet 
var personality: int # Current personality of Pet
var main_screen: int # Screen for pet to be confined to, will be changed later
var shader_on: bool # Whether the pet should use the distortion shade or not, changed in settings
var large_hitbox: bool # Whether the pet should keep the default window-size hitbox for accesibility


func _ready() -> void:
	var config := ConfigFile.new()
	if config.load("user://data.cfg") != OK: # Load file and check if it is loaded ok
		print("No data found, using default")
	# Set the variables to the found data, final argument is the default for if no Config File is found
	nickname = config.get_value("pet", "nickname", "Pet")
	fullness = config.get_value("pet", "fullness", 100)
	happiness = config.get_value("pet", "happiness", 100)
	age = config.get_value("pet", "age", 0)
	stage = config.get_value("pet", "stage", 0)
	money = config.get_value("pet", "money", 0)
	type = config.get_value("pet", "type", randi_range(0, 2))
	pattern = config.get_value("pet", "pattern", 0)
	personality = config.get_value("pet", "personality", 0)
	main_screen = config.get_value("settings", "main_screen", DisplayServer.get_primary_screen())
	shader_on = config.get_value("settings", "shader_on", false)
	large_hitbox = config.get_value("settings", "large_hitbox", false)
