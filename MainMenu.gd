extends Node2D

@onready var music_player = $MusicPlayer

func _ready():
	$TeamSelection.pressed.connect(GameManager._on_button_pressed)
	music_player.stream = load("res://audio/WelcomeTotheArena.mp3")
	music_player.play()


func _on_credits_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Credits.tscn")
