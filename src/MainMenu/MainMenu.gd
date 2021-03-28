extends Node2D

var game = preload("res://src/Game/Game.tscn")

func _ready() -> void:
	check_for_existing_save()

func check_for_existing_save() -> void:
	var g = File.new()
	$Window/GridContainer/GridContainer/btn_continue.disabled = not g.file_exists(Global.SAVE_FILE_NAME)

func _on_btn_big_pressed() -> void:
	Global.tile_count_x = 18
	Global.tile_count_y = 10
	get_tree().change_scene("res://src/Game/Game.tscn")

func _on_btn_continue_pressed() -> void:
	Global.tile_count_x = Global.LOAD_GAME
	Global.tile_count_y = Global.LOAD_GAME
	get_tree().change_scene("res://src/Game/Game.tscn")

func _on_btn_small_pressed() -> void:
	Global.tile_count_x = 8
	Global.tile_count_y = 6
	get_tree().change_scene("res://src/Game/Game.tscn")

func _on_btn_help_pressed() -> void:
	get_tree().change_scene("res://src/Help/Help.tscn")

func _on_btn_about_pressed() -> void:
	get_tree().change_scene("res://src/About/About.tscn")

func _on_Exit_pressed() -> void:
	get_tree().quit()


