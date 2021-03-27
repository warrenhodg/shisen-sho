extends Node2D

var game = preload("res://src/Game/Game.tscn")

func _ready() -> void:
	pass # Replace with function body.

func _on_Exit_pressed() -> void:
	get_tree().quit()

func _on_btn_big_pressed() -> void:
	Global.tile_count_x = 24
	Global.tile_count_y = 14
	get_tree().change_scene("res://src/Game/Game.tscn")

func _on_btn_small_pressed() -> void:
	Global.tile_count_x = 12
	Global.tile_count_y = 7
	get_tree().change_scene("res://src/Game/Game.tscn")


func _on_btn_help_pressed() -> void:
	get_tree().change_scene("res://src/Help/Help.tscn")