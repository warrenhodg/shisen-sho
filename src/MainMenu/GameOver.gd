extends Node2D

func _ready() -> void:
	$ShisenWindow/GridContainer/Button.text = Global.game_status

func _on_Button_pressed() -> void:
	get_tree().change_scene("res://src/MainMenu/MainMenu.tscn")