extends Node2D

var state = 0
var scenes: Array
var instructions: Array

func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	get_tree().set_quit_on_go_back(false)

	state = 0
	$background/Back.disabled = true
	
	instructions = [
		"Tap a tile to\nselect it",
		"Remove matching tiles\nwith at most 3 lines",
		"Remove all tiles\nto win",
		"Remove adjacent tiles\nwith 1 line",
		"Lines cannot pass\nthrough other tiles",
		"Internal tiles can\nbe removed",
		"Hold a tile to highlight\nsimilar tiles"
	]
	scenes = [
		$background/Help_select,
		$background/Help_3_lines,
		null,
		$background/Help_adjacent,
		$background/Help_illegal,
		$background/Help_internal,
		$background/Help_highlight
	]
	
	show_help()

func show_help() -> void:
	if state >= instructions.size():
		get_tree().change_scene("res://src/main_menu/main_menu.tscn")
		return
		
	$background/GridContainer/Instructions.text = instructions[state]
	for i in range(instructions.size()):
		var scene = scenes[i]
		if scene == null:
			continue
		scene.visible = (i == state)

func _on_Back_pressed() -> void:
	if state == 0:
		return
	state -= 1
	$background/Back.disabled = (state == 0)
	show_help()

func _on_Next_pressed() -> void:
	$background/Back.disabled = false
	state += 1
	show_help()

func quit_help() -> void:
	get_tree().change_scene("res://src/main_menu/main_menu.tscn")
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		quit_help()

func _notification(what) -> void:
	match what:
		MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
			quit_help()
		
		MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
			quit_help()

