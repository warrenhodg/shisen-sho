extends Node2D
class_name Game

const SCREEN_SIZE_X = 1920
const SCREEN_SIZE_Y = 1080
const ORIGINAL_TILE_WIDTH = 617
const ORIGINAL_TILE_HEIGHT = 760
const GRID_MARGIN_WIDTH = 20
const GRID_MARGIN_HEIGHT = 20
const LINE_BASE_WIDTH = 50
const LONG_PRESS_MS = 500
const NORMAL_COLOR = Color(1, 1, 1)
const SELECT_COLOR = Color(1, 0.5, 0.5)
const HIGHLIGHT_COLOR = Color(1, 1, 0.5)

var shisensho: = Shisensho.new()
var tile_blueprint: = preload("res://src/game/tile.tscn")
var tile_textures: Array
var tile_zoom: = 1.0
var tile_size: = Vector2(0, 0)
var tile_origin: = Vector2(0, 0)
var board_tiles: Array
var selected = null
var highlighted = null
var mouse_down_time = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	get_tree().set_quit_on_go_back(false)

	self._load_tile_textures()
	
	self.shisensho.connect("board_created", self, "_on_board_created") 
	self.shisensho.connect("tile_created", self, "_on_tile_created") 
	self.shisensho.connect("tile_removed", self, "_on_tile_removed") 
	self.shisensho.connect("no_more_moves", self, "_on_no_more_moves") 
	self.shisensho.connect("win", self, "_on_win") 

	if Global.must_load_game:
		self.shisensho.load_game()
		return
		
	self.shisensho.new_game(Global.size, Global.TILE_TYPE_COUNT)
	
func _on_board_created(size: Vector2) -> void:
	var desired_tile_size_x = float((SCREEN_SIZE_X - (2 * GRID_MARGIN_WIDTH)) / size.x)
	var desired_tile_size_y = float((SCREEN_SIZE_Y - (2 * GRID_MARGIN_HEIGHT)) / size.y)
	var zoom_width = desired_tile_size_x / ORIGINAL_TILE_WIDTH
	var zoom_height = desired_tile_size_y / ORIGINAL_TILE_HEIGHT
	self.tile_zoom = zoom_width if zoom_width < zoom_height else zoom_height
	self.tile_size.x = ORIGINAL_TILE_WIDTH * self.tile_zoom
	self.tile_size.y = ORIGINAL_TILE_HEIGHT * self.tile_zoom
	self.tile_origin.x = (SCREEN_SIZE_X - (self.tile_size.x * size.x)) / 2
	self.tile_origin.y = (SCREEN_SIZE_Y - (self.tile_size.y * size.y)) / 2

	var tile_count = size.x * size.y
	self.board_tiles.resize(tile_count)
	for i in range(tile_count):
		self.board_tiles[i] = null

func _on_tile_created(tile_type: int, position: int) -> void:
	var coords = self.shisensho.pos_to_coords(position)

	var tile_instance: Sprite = tile_blueprint.instance()
	tile_instance.texture = tile_textures[tile_type]
	tile_instance.position = Vector2(
		self.tile_origin.x + self.tile_size.x * coords.x,
		self.tile_origin.y + self.tile_size.y * coords.y)
	tile_instance.scale = Vector2(self.tile_zoom, self.tile_zoom)
	
	self.board_tiles[position] = tile_instance 
	add_child(tile_instance)

func _on_tile_removed(position: int) -> void:
	var tile = self.board_tiles[position]
	if tile == null:
		return
	tile.queue_free()
	self.board_tiles[position] = null

func _on_no_more_moves() -> void:
	self.shisensho.delete_save_game()
	Global.game_status = "No more moves"
	get_tree().change_scene("res://src/main_menu/game_over.tscn")

func _on_win() -> void:
	self.shisensho.delete_save_game()
	Global.game_status = "You WIN!"
	get_tree().change_scene("res://src/main_menu/game_over.tscn")

func _load_tile_textures() -> void:
	for i in range(Global.TILE_TYPE_COUNT):
		var file_name = "res://assets/tiles/%s.png" % (i+1)
		var texture: = load(file_name)
		tile_textures.append(texture)

func _highlight_tile_type(tile_type: int, color: Color) -> void:
	var tiles = self.shisensho.same_tiles[tile_type]
	if tiles == null || tiles.size() == 0:
		return
		
	for i in range(tiles.size()):
		var position = tiles[i]
		var tile = self.board_tiles[position]
		if tile == null:
			continue

		tile.modulate = color

func _select_tile(position) -> void:
	if position == null:
		return

	var tile = self.board_tiles[position]
	if tile == null:
		return

	tile.modulate = SELECT_COLOR

func _deselect_tile(position) -> void:
	if position == null:
		return

	var tile = self.board_tiles[position]
	if tile == null:
		return

	tile.modulate = NORMAL_COLOR

func _hide_joiner(joiner, timer: Timer) -> void:
	joiner.queue_free()
	timer.queue_free()
	
# Converts the provided tile coords to pixel coords
# and shows the line
func _show_joiner(j: Join) -> void:
	var points: Array
	if j.is_row:
		points = [
			Vector2(j.t1.x, j.t1.y),
			Vector2(j.t1.x, j.value),
			Vector2(j.t2.x, j.value),
			Vector2(j.t2.x, j.t2.y)]
	else:
		points = [
			Vector2(j.t1.x, j.t1.y),
			Vector2(j.value, j.t1.y),
			Vector2(j.value, j.t2.y),
			Vector2(j.t2.x, j.t2.y)]

	var joiner = Line2D.new()
	joiner.width = LINE_BASE_WIDTH * tile_zoom
	for i in range(points.size()):
		var point = points[i]
		joiner.add_point(self._logical_to_ui_coords(point))
	add_child(joiner)
	
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 1.0
	timer.autostart = true
	timer.connect("timeout", self, "_hide_joiner", [joiner, timer])
	add_child(timer)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_quit_game()
		
	if event is InputEventMouseButton:
		var mouse_event: = event as InputEventMouseButton

		if mouse_event.pressed:
			mouse_down_time = OS.get_ticks_msec()
			return
			
		else:
			match mouse_event.button_index:
				BUTTON_LEFT:
					var delta_msec = OS.get_ticks_msec() - mouse_down_time
					if delta_msec > LONG_PRESS_MS:
						_handle_right_click(mouse_event)
						return
					
					_handle_left_click(mouse_event)
					return
					
				BUTTON_RIGHT:
					_handle_right_click(mouse_event)
					return

func _quit_game() -> void:
	self.shisensho.save_game()
	get_tree().change_scene("res://src/main_menu/main_menu.tscn")

func _logical_to_ui_coords(coords: Vector2) -> Vector2:
	return Vector2(
		(coords.x + 0.5) * tile_size.x + tile_origin.x,
		(coords.y + 0.5) * tile_size.y + tile_origin.y)

func _ui_to_logical_coords(ui: Vector2) -> Vector2:
	return Vector2(
		int((ui.x - tile_origin.x) / tile_size.x),
		int((ui.y - tile_origin.y) / tile_size.y))

func _handle_right_click(mouse_event: InputEventMouseButton) -> void:
	var coords = _ui_to_logical_coords(mouse_event.position)
	if !self.shisensho.in_bounds(coords):
		return

	if highlighted != null:
		_highlight_tile_type(highlighted, NORMAL_COLOR)
		
	var position: = self.shisensho.coords_to_pos(coords)
	var b = self.shisensho.board_indexes[position]
	if b == null or b == highlighted:
		highlighted = null
		return
		
	highlighted = b
	_highlight_tile_type(highlighted, HIGHLIGHT_COLOR)

func _handle_left_click(mouse_event: InputEventMouseButton) -> void:
	var coords = self._ui_to_logical_coords(mouse_event.position)
	if !self.shisensho.in_bounds(coords):
		return

	var position: = self.shisensho.coords_to_pos(coords)
	# Check if clicked on nothing
	if self.shisensho.board_indexes[position] == null:
		return

	# If nothing has been selected yet, then select it
	if self.selected == null:
		selected = position
		self._select_tile(selected)
		return
	
	# If clicked on the selected tile, deselect it
	if selected == position:
		self._deselect_tile(selected)
		selected = null
		return
		
	# If clicked on a tile of different type, select it instead
	if self.shisensho.board_indexes[selected] != self.shisensho.board_indexes[position]:
		self._deselect_tile(selected)
		selected = position
		self._select_tile(selected)
		return

	# Try join and remove this tile, and the previously selected one
	var j: = self.shisensho.try_join(selected, position)
	if j != null:
		self.shisensho.remove_join(j)
		selected = null
		self._show_joiner(j)
		return
	
func _notification(what) -> void:
	match what:
		MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
			self._quit_game()
		
		MainLoop.NOTIFICATION_WM_FOCUS_OUT:
			self.shisensho.save_game()
			
		MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
			self._quit_game()
