extends Node2D

func _on_OK_pressed() -> void:
	get_tree().change_scene("res://src/MainMenu/MainMenu.tscn")
