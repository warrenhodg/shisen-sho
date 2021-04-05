extends Node2D

func _ready() -> void:
	check_for_existing_save()

func check_for_existing_save() -> void:
	var g = File.new()
	$Window/GridContainer/GridContainer/btn_continue.disabled = not g.file_exists(Global.SAVE_FILE_NAME)

func _on_btn_big_pressed() -> void:
	Global.must_load_game = false
	Global.size.x = 18
	Global.size.y = 10
	get_tree().change_scene("res://src/game/game.tscn")

func _on_btn_continue_pressed() -> void:
	Global.must_load_game = true
	get_tree().change_scene("res://src/game/game.tscn")

func _on_btn_small_pressed() -> void:
	Global.must_load_game = false
	Global.size.x = 8
	Global.size.y = 6
	get_tree().change_scene("res://src/game/game.tscn")

func _on_btn_help_pressed() -> void:
	get_tree().change_scene("res://src/help/help.tscn")

func _on_btn_about_pressed() -> void:
	get_tree().change_scene("res://src/about/about.tscn")

func _on_Exit_pressed() -> void:
	get_tree().quit()
