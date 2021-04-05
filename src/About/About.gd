extends Node2D

func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	get_tree().set_quit_on_go_back(false)

func _on_OK_pressed() -> void:
	get_tree().change_scene("res://src/main_menu/main_menu.tscn")

func quit_about() -> void:
	get_tree().change_scene("res://src/main_menu/main_menu.tscn")
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		quit_about()

func _notification(what) -> void:
	match what:
		MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
			quit_about()
		
		MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
			quit_about()
