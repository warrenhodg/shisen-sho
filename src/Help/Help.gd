extends Node2D

const instructions_0 = "Remove matching tiles\nwith at most 3 lines"
const instructions_1 = "Remove adjacent tiles\nwith 1 line"
const instructions_2 = "Lines cannot pass\nthrough other tiles"
const instructions_3 = "Remove all tiles\nto win"

var state = 0

func _ready() -> void:
	state = 0
	show_help()

func show_help() -> void:
	match state:
		0:
			$background/GridContainer/Instructions.text = instructions_0
			$background/Help_0.visible = true
			$background/Help_1.visible = false
			$background/Help_2.visible = false
		1:
			$background/GridContainer/Instructions.text = instructions_1
			$background/Help_0.visible = false
			$background/Help_1.visible = true
			$background/Help_2.visible = false
		2:
			$background/GridContainer/Instructions.text = instructions_2
			$background/Help_0.visible = false
			$background/Help_1.visible = false
			$background/Help_2.visible = true
		3:
			$background/GridContainer/Instructions.text = instructions_3
			$background/Help_0.visible = false
			$background/Help_1.visible = false
			$background/Help_2.visible = false
		_:
			get_tree().change_scene("res://src/MainMenu/MainMenu.tscn")

func _on_Next_pressed() -> void:
	state = state + 1
	show_help()
