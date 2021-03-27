extends Node2D

var game = preload("res://src/Game/Game.tscn")

func _ready() -> void:
	pass # Replace with function body.

func _on_btn_big_pressed() -> void:
	Global.tile_count_x = 24
	Global.tile_count_y = 14
	get_tree().change_scene("res://src/Game/Game.tscn")

func _on_btn_small_pressed() -> void:
	Global.tile_count_x = 8
	Global.tile_count_y = 4
	get_tree().change_scene("res://src/Game/Game.tscn")

func _on_btn_help_pressed() -> void:
	get_tree().change_scene("res://src/Help/Help.tscn")

func _on_btn_about_pressed() -> void:
	get_tree().change_scene("res://src/About/About.tscn")

func _on_Exit_pressed() -> void:
	get_tree().quit()
