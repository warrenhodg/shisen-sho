extends Node2D
class_name Game

const TILE_TYPE_COUNT = 42
const SCREEN_SIZE_X = 800
const SCREEN_SIZE_Y = 600
const TILE_SIZE_X = 30
const TILE_SIZE_Y = 37
const GRID_SIZE_X = 24
const GRID_SIZE_Y = 14
const GRID_MARGINS_X = (SCREEN_SIZE_X - TILE_SIZE_X * GRID_SIZE_X) / 2
const GRID_MARGINS_Y = (SCREEN_SIZE_Y - TILE_SIZE_Y * GRID_SIZE_Y) / 2
const CANNOT_JOIN = -2

var rng = RandomNumberGenerator.new()
var tile_blueprint: = preload("res://src/Game/Tile.tscn")
var tile_textures: Array
var board_size_x: int
var board_size_y: int
var board_indexes: Array
var board_tiles: Array
var selected = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_tile_textures()
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

	board_size_x = GRID_SIZE_X
	board_size_y = GRID_SIZE_Y
	reset_board()

	var pair_count: = board_indexes.size() / 2
	for pair in range(pair_count):
		tile_type = rng.randi_range(0, TILE_TYPE_COUNT - 1)

		position = get_random_empty_tile()
		create_tile(tile_type, position)
		position = get_random_empty_tile()
		create_tile(tile_type, position)

func reset_board() -> void:
	var tile_count: = board_size_x * board_size_y
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
	var x: = position % board_size_x
	var y: = position / board_size_x

	var tile_instance: = tile_blueprint.instance()
	tile_instance.texture = tile_textures[tile_type]
	tile_instance.position = Vector2(GRID_MARGINS_X + TILE_SIZE_X * x, GRID_MARGINS_Y + TILE_SIZE_Y * y)

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

func join_col(x1: int, y1: int, x2: int, y2: int) -> int:
	var delta = 0
	while x1 - delta >= -1 || x1 + delta <= board_size_x:
		if x1 - delta >= -1:
			if is_c_shape_empty(x1, y1, x2, y2, x1 - delta):
				return x1 - delta
		if x1 + delta <= board_size_x:
			if is_c_shape_empty(x1, y1, x2, y2, x1 + delta):
				return x1 + delta
		delta += 1
	return CANNOT_JOIN

func join_row(x1: int, y1: int, x2: int, y2: int) -> int:
	var delta = 0
	while y1 - delta >= -1 || y1 + delta <= board_size_y:
		if y1 - delta >= -1:
			if is_u_shape_empty(x1, y1, x2, y2, y1 - delta):
				return y1 - delta
		if y1 + delta <= board_size_y:
			if is_u_shape_empty(x1, y1, x2, y2, y1 + delta):
				return y1 + delta
		delta += 1
	return CANNOT_JOIN

# Checks if the "c" shape is empty
func is_c_shape_empty(x1: int, y1: int, x2: int, y2: int, col: int) -> bool:
	if !is_row_empty(x1, col, y1):
		return false
	if !is_col_empty(col, y1, y2):
		return false
	if !is_row_empty(x2, col, y2):
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
	if x < 0 || x >= board_size_x:
		return true
	
	var delta = 1 if y1 < y2 else -1
	var y = y1
	while true:
		y += delta
		if y < 0 || y >= board_size_y:
			return true
			
		if !include_end:
			if y == y2:
				return true
				
		if board_indexes[x + y * board_size_x] != null:
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
	if y < 0 || y >= board_size_y:
		return true
		
	var delta = 1 if x1 < x2 else -1
	var x = x1
	while true:
		x += delta
		if x < 0 || x >= board_size_x:
			return true
		
		if !include_end:
			if x == x2:
				return true
			
		if board_indexes[x + y * board_size_x] != null:
			return false
		
		if include_end:
			if x == x2:
				return true
	return true
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: = event as InputEventMouseButton

		if mouse_event.button_index == BUTTON_LEFT && mouse_event.pressed:
			var x: int = (mouse_event.position.x - GRID_MARGINS_X) / TILE_SIZE_X
			var y: int = (mouse_event.position.y - GRID_MARGINS_Y) / TILE_SIZE_Y
			if x < 0 || y < 0 || x >= board_size_x || y >= board_size_y:
				return

			var position: = x + y * board_size_x
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

			var x1 = selected % board_size_x
			var y1 = selected / board_size_x
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
				return
			
			j = join_col(x1, y1, x2, y2)
			if j != CANNOT_JOIN:
				print("Joining on col ", j)
				dehighlight_tile(selected)
				remove_tile(selected)
				remove_tile(position)
				selected = null
				return
			
			print("Cannot join")
