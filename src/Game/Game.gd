extends Node2D
class_name Game

const TILE_TYPE_COUNT = 42
const SCREEN_SIZE_X = 1024
const SCREEN_SIZE_Y = 768
const ORIGINAL_TILE_WIDTH = 617
const ORIGINAL_TILE_HEIGHT = 760
const GRID_MARGIN_WIDTH = 20
const GRID_MARGIN_HEIGHT = 20
const CANNOT_JOIN = -2
const LINE_BASE_WIDTH = 50

var rng = RandomNumberGenerator.new()
var tile_blueprint: = preload("res://src/Game/Tile.tscn")
var tile_textures: Array
var tile_count_x: int
var tile_count_y: int
var tile_zoom: float
var tile_width: float
var tile_height: float
var tile_left: float
var tile_top: float
var board_indexes: Array
var board_tiles: Array
var selected = null
var remaining: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_tile_textures()
	
	tile_count_x = Global.tile_count_x
	tile_count_y = Global.tile_count_y
	var desired_tile_width = float((SCREEN_SIZE_X - (2 * GRID_MARGIN_WIDTH)) / tile_count_x)
	var desired_tile_height = float((SCREEN_SIZE_Y - (2 * GRID_MARGIN_HEIGHT)) / tile_count_y)
	var zoom_width = desired_tile_width / ORIGINAL_TILE_WIDTH
	var zoom_height = desired_tile_height / ORIGINAL_TILE_HEIGHT
	tile_zoom = zoom_width if zoom_width < zoom_height else zoom_height
	tile_width = ORIGINAL_TILE_WIDTH * tile_zoom
	tile_height = ORIGINAL_TILE_HEIGHT * tile_zoom
	tile_left = (SCREEN_SIZE_X - (tile_width * tile_count_x)) / 2
	tile_top = (SCREEN_SIZE_Y - (tile_height * tile_count_y)) / 2
	generate_random_board()
	
func load_tile_textures() -> void:
	for i in range(TILE_TYPE_COUNT):
		var file_name = "res://assets/tiles/%s.png" % (i+1)
		var texture: = load(file_name)
		tile_textures.append(texture)

func generate_random_board() -> void:
	var tile_type: int
	var position: int
	rng.randomize()

	reset_board()

	remaining = board_indexes.size()
	
	var pair_count: = board_indexes.size() / 2
	for pair in range(pair_count):
		tile_type = rng.randi_range(0, TILE_TYPE_COUNT - 1)

		position = get_random_empty_tile()
		create_tile(tile_type, position)
		position = get_random_empty_tile()
		create_tile(tile_type, position)

func reset_board() -> void:
	var tile_count: = tile_count_x * tile_count_y
	board_indexes.resize(tile_count)
	board_tiles.resize(tile_count)

	for i in range(tile_count):
		board_indexes[i] = null
		board_tiles[i] = null
	
func get_random_empty_tile() -> int:
	var tile_count: = board_indexes.size()  
	var i = rng.randi_range(0, tile_count-1)
	while board_indexes[i] != null:
		i += 1
		if i == tile_count:
			i = 0

	return i

func create_tile(tile_type: int, position: int) -> void:
	var x: = position % tile_count_x
	var y: = position / tile_count_x

	var tile_instance: Sprite = tile_blueprint.instance()
	tile_instance.texture = tile_textures[tile_type]
	tile_instance.position = Vector2(tile_left + tile_width * x, tile_top + tile_height * y)
	tile_instance.scale = Vector2(tile_zoom, tile_zoom)
	
	board_indexes[position] = tile_type
	board_tiles[position] = tile_instance 
	add_child(tile_instance)

func highlight_tile(position) -> void:
	if position == null:
		return

	var tile = board_tiles[position]
	if tile == null:
		return

	tile.modulate.g8 = 196
	tile.modulate.b8 = 196

func dehighlight_tile(position) -> void:
	if position == null:
		return

	var tile = board_tiles[position]
	if tile == null:
		return

	tile.modulate.g8 = 255
	tile.modulate.b8 = 255

func remove_tile(position: int) -> void:
	var tile = board_tiles[position]
	if tile == null:
		return
	tile.queue_free()
	board_indexes[position] = null
	board_tiles[position] = null
	remaining -= 1

func join_col(x1: int, y1: int, x2: int, y2: int) -> int:
	var delta = 0
	while x1 - delta >= -1 || x1 + delta <= tile_count_x:
		if x1 - delta >= -1:
			if is_c_shape_empty(x1, y1, x2, y2, x1 - delta):
				return x1 - delta
		if x1 + delta <= tile_count_x:
			if is_c_shape_empty(x1, y1, x2, y2, x1 + delta):
				return x1 + delta
		delta += 1
	return CANNOT_JOIN

func join_row(x1: int, y1: int, x2: int, y2: int) -> int:
	var delta = 0
	while y1 - delta >= -1 || y1 + delta <= tile_count_y:
		if y1 - delta >= -1:
			if is_u_shape_empty(x1, y1, x2, y2, y1 - delta):
				return y1 - delta
		if y1 + delta <= tile_count_y:
			if is_u_shape_empty(x1, y1, x2, y2, y1 + delta):
				return y1 + delta
		delta += 1
	return CANNOT_JOIN

# Checks if the "c" shape is empty
func is_c_shape_empty(x1: int, y1: int, x2: int, y2: int, col: int) -> bool:
	if !is_row_empty(x1, col, y1, true):
		return false
	if !is_col_empty(col, y1, y2, false):
		return false
	if !is_row_empty(x2, col, y2, true):
		return false
	return true

# Checks if the "u" shape is empty
func is_u_shape_empty(x1: int, y1: int, x2: int, y2: int, row: int) -> bool:
	if !is_col_empty(x1, y1, row, true):
		return false
	if !is_row_empty(x1, x2, row, false):
		return false
	if !is_col_empty(x2, y2, row, true):
		return false
	return true

# Returns true if all tiles in column x from y1 (excl) to y2 (incl)
# are empty
func is_col_empty(x: int, y1: int, y2: int, include_end: bool) -> bool:
	# Same tile - return true
	if y1 == y2:
		return true
		
	# Outside bounds of board - return true
	if x < 0 || x >= tile_count_x:
		return true
	
	var delta = 1 if y1 < y2 else -1
	var y = y1
	while true:
		y += delta
		if y < 0 || y >= tile_count_y:
			return true
			
		if !include_end:
			if y == y2:
				return true
				
		if board_indexes[x + y * tile_count_x] != null:
			return false
			
		if include_end:
			if y == y2:
				return true
	return true

# Returns true if all tiles in row y from x1 (excl) to x2 (incl)
# are empty
func is_row_empty(x1: int, x2: int, y: int, include_end: bool) -> bool:
	# Same tile - return true
	if x1 == x2:
		return true

	# Outside bounds of board - return true
	if y < 0 || y >= tile_count_y:
		return true
		
	var delta = 1 if x1 < x2 else -1
	var x = x1
	while true:
		x += delta
		if x < 0 || x >= tile_count_x:
			return true
		
		if !include_end:
			if x == x2:
				return true
			
		if board_indexes[x + y * tile_count_x] != null:
			return false
		
		if include_end:
			if x == x2:
				return true
	return true

func _hide_joiner(joiner, timer: Timer) -> void:
	joiner.queue_free()
	timer.queue_free()
	
# Converts the provided tile coords to pixel coords
# and shows the line
func show_joiner(points: Array) -> void:
	var joiner = Line2D.new()
	joiner.width = LINE_BASE_WIDTH * tile_zoom
	for i in range(points.size()):
		var point = points[i]
		joiner.add_point(Vector2(
				tile_left + (point.x + 0.5) * tile_width,
				tile_top + (point.y + 0.5) * tile_height))
	add_child(joiner)
	
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 1.0
	timer.autostart = true
	timer.connect("timeout", self, "_hide_joiner", [joiner, timer])
	add_child(timer)

func check_game_over() -> void:
	if remaining == 0:
		Global.game_status = "You WIN!"
		get_tree().change_scene("res://src/MainMenu/GameOver.tscn")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene("res://src/MainMenu/MainMenu.tscn")
		
	if event is InputEventMouseButton:
		var mouse_event: = event as InputEventMouseButton

		if mouse_event.button_index == BUTTON_LEFT && mouse_event.pressed:
			var x: int = (mouse_event.position.x - tile_left) / tile_width
			var y: int = (mouse_event.position.y - tile_top) / tile_height
			if x < 0 || y < 0 || x >= tile_count_x || y >= tile_count_y:
				return

			var position: = x + y * tile_count_x
			if board_indexes[position] == null:
				return

			if selected == null:
				selected = position
				highlight_tile(selected)
				return
			
			if selected == position:
				dehighlight_tile(selected)
				selected = null
				return
				
			if board_indexes[selected] != board_indexes[position]:
				dehighlight_tile(selected)
				selected = position
				highlight_tile(selected)
				return

			var x1 = selected % tile_count_x
			var y1 = selected / tile_count_x
			var x2 = x
			var y2 = y
			
			var j: int
			j = join_row(x1, y1, x2, y2)
			if j != CANNOT_JOIN:
				print("Joining on row ", j)
				dehighlight_tile(selected)
				remove_tile(selected)
				remove_tile(position)
				selected = null
				show_joiner([
					Vector2(x1, y1),
					Vector2(x1, j),
					Vector2(x2, j),
					Vector2(x2, y2)])
				check_game_over()
				return
			
			j = join_col(x1, y1, x2, y2)
			if j != CANNOT_JOIN:
				print("Joining on col ", j)
				dehighlight_tile(selected)
				remove_tile(selected)
				remove_tile(position)
				selected = null
				show_joiner([
					Vector2(x1, y1),
					Vector2(j, y1),
					Vector2(j, y2),
					Vector2(x2, y2)])
				check_game_over()
				return
			
			print("Cannot join")
			
func _notification(what) -> void:
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		get_tree().set_auto_accept_quit(false)
		get_tree().change_scene("res://src/MainMenu/MainMenu.tscn")
