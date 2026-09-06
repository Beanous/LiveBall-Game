extends Node2D

var winner_team: String
var logo_path: String

@onready var music_player = $MusicPlayer

func _ready():
	await get_tree().process_frame
	await get_tree().process_frame
	
	var vc = get_node_or_null("ColorRect/VBoxContainer")
	var winner_label = vc.get_node("WinnerLabel")
	var logo_rect = vc.get_node("TextureRect")
	
	print("TextureRect resovled:", logo_rect)
	
	winner_team = GameManager.winner_team
	logo_path = GameManager.logo_path
	
	if winner_label:
		winner_label.text = "%s Wins!" % GameManager.winner_team
	else:
		print("WinnerLabel not found at runtime")
	
	if GameManager.logo_path != "":
		logo_rect.texture = load(GameManager.logo_path)
	else:
		print("Warning: Logo not found", winner_team)
	
	music_player.stream = load("res://audio/Taketheball.mp3")
	music_player.play()
	
func _on_button_pressed() -> void:
	GameManager.reset_game()
	get_tree().change_scene_to_file("res://main.tscn")
