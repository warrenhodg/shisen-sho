extends Reference
class_name Shisensho

const CAN_WIN_CALCULATION_MS = 5000

var size: Vector2
var board_indexes: Array
var same_tiles: Dictionary
var remaining: int

var suppress_signals: = false

signal board_created(size)
signal tile_created(tile_type, position)
signal tile_removed(position)
signal no_more_moves()
signal win()

func new_game(_size: Vector2, tile_type_count: int) -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	self.size = _size

	var stop_ticks = OS.get_ticks_msec() + CAN_WIN_CALCULATION_MS

	# Generate random boards until one is made that can be completed
	while true:
		self._generate_random_board(rng, tile_type_count)
		if self._can_win(stop_ticks):
			break

	self._emit_tiles_created()
	self._check_game_over()

func _generate_random_board(rng: RandomNumberGenerator, tile_type_count: int) -> void:
	self._reset_board(tile_type_count)

	self.remaining = 0
	
	var pair_count: = board_indexes.size() / 2
	for _pair in range(pair_count):
		var position: int
		var tile_type = rng.randi_range(0, tile_type_count - 1)

		position = _get_random_empty_tile(rng)
		_create_tile(tile_type, position)
		position = _get_random_empty_tile(rng)
		_create_tile(tile_type, position)

func load_game() -> void:
	var g = File.new()
	if not g.file_exists(Global.SAVE_FILE_NAME):
		return
		
	g.open(Global.SAVE_FILE_NAME, File.READ)
	var data = parse_json(g.get_line())
	self.size = Vector2(data["width"], data["height"])
	var board = data["board"]
	self._reset_board(Global.TILE_TYPE_COUNT)

	self.remaining = 0
	for position in range(board.size()):
		var tile_type = board[position]
		if tile_type == null:
			continue
		self._create_tile(tile_type, position)

	self._emit_tiles_created()
	self._check_game_over()

func _emit_tiles_created() -> void:
	if self.suppress_signals:
		return

	for position in range(self.board_indexes.size()):
		var tile_type = self.board_indexes[position]
		if tile_type == null:
			continue
		emit_signal("tile_created", tile_type, position)

func save_game() -> void:
	var g = File.new()
	g.open(Global.SAVE_FILE_NAME, File.WRITE)
	var data: Dictionary = {}
	data["width"] = int(self.size.x)
	data["height"] = int(self.size.y)
	data["board"] = board_indexes
	g.store_line(to_json(data))
	g.close()

func delete_save_game() -> void:
	var g = File.new()
	if g.file_exists(Global.SAVE_FILE_NAME):
		var d = Directory.new()
		d.remove(Global.SAVE_FILE_NAME)
		return

func _reset_board(tile_type_count: int) -> void:
	var tile_count: = int(self.size.x) * int(self.size.y)
	self.board_indexes.resize(tile_count)

	remaining = 0
	
	for i in range(self.board_indexes.size()):
		self.board_indexes[i] = null

	for i in range(tile_type_count):
		same_tiles[i] = []
		
	if !self.suppress_signals:
		emit_signal("board_created", self.size)

func remove_join(j: Join) -> void:
	self._remove_tile(j.p1)
	self._remove_tile(j.p2)
	self._check_game_over()

func _unremove_join(j: Join) -> void:
	self._create_tile(j.tile_type, j.p1)
	self._create_tile(j.tile_type, j.p2)

# remove_tile removes a tile, and generates the tile_removed signal
func _remove_tile(position: int) -> void:
	var tile_type = self.board_indexes[position]
	self.board_indexes[position] = null
	self.same_tiles[tile_type].erase(position)
	remaining -= 1
	if !self.suppress_signals:
		emit_signal("tile_removed", position)

# join returns the shortest valid way to join two tiles, or null
func try_join(p1: int, p2: int) -> Join:
	var tile_type = self.board_indexes[p1]
	var t1 = self.pos_to_coords(p1)
	var t2 = self.pos_to_coords(p2)

	var delta = 0
	while (t1.x - delta >= -1) or (t1.x + delta <= size.x) or (t1.y - delta >= -1) or (t1.y + delta <= size.y):
		if t1.x - delta >= -1:
			if self._is_c_shape_empty(t1, t2, t1.x - delta):
				return Join.new(tile_type, p1, p2, t1, t2, false, t1.x - delta)
		if t1.x + delta <= size.x:
			if  self._is_c_shape_empty(t1, t2, t1.x + delta):
				return Join.new(tile_type, p1, p2, t1, t2, false, t1.x + delta)
		if t1.y - delta >= -1:
			if  self._is_u_shape_empty(t1, t2, t1.y - delta):
				return Join.new(tile_type, p1, p2, t1, t2, true, t1.y - delta)
		if t1.y + delta <= size.y:
			if  self._is_u_shape_empty(t1, t2, t1.y + delta):
				return Join.new(tile_type, p1, p2, t1, t2, true, t1.y + delta)
		delta += 1
	return null

func pos_to_coords(pos: int) -> Vector2:
	return Vector2(
		pos % int(self.size.x),
		pos / int(self.size.x))

func coords_to_pos(coords: Vector2) -> int:
	return int(coords.x) + int(coords.y) * int(self.size.x)

func in_bounds(coords: Vector2) -> bool:
	return coords.x >= 0 and coords.y >= 0 and coords.x < self.size.x and coords.y < self.size.y

# _get_random_empty_tile generates a random board position, then finds the first open space on or after it
func _get_random_empty_tile(rng: RandomNumberGenerator) -> int:
	var tile_count: = board_indexes.size()
	var i = rng.randi_range(0, tile_count-1)
	while board_indexes[i] != null:
		i += 1
		if i == tile_count:
			i = 0

	return i

func _create_tile(tile_type: int, position: int) -> void:
	self.board_indexes[position] = tile_type
	self.same_tiles[tile_type].append(position)
	self.remaining += 1

# Checks if the "c" shape is empty
func _is_c_shape_empty(t1: Vector2, t2: Vector2, col: int) -> bool:
	if ! self._is_row_empty(int(t1.x), col, int(t1.y), true):
		return false
	if ! self._is_col_empty(col, int(t1.y), int(t2.y), false):
		return false
	if ! self._is_row_empty(int(t2.x), col, int(t2.y), true):
		return false
	return true

# Checks if the "u" shape is empty
func _is_u_shape_empty(t1: Vector2, t2: Vector2, row: int) -> bool:
	if ! self._is_col_empty(int(t1.x), int(t1.y), row, true):
		return false
	if ! self._is_row_empty(int(t1.x), int(t2.x), row, false):
		return false
	if ! self._is_col_empty(int(t2.x), int(t2.y), row, true):
		return false
	return true

# Returns true if all tiles in column x from t1.y (excl) to t2.y (incl)
# are empty
func _is_col_empty(x: int, y1: int, y2: int, include_end: bool) -> bool:
	# Same tile - return true
	if y1 == y2:
		return true
		
	# Outside bounds of board - return true
	if x < 0 || x >= self.size.x:
		return true
	
	var delta = 1 if y1 < y2 else -1
	var y = y1
	while true:
		y += delta
		if y < 0 || y >= self.size.y:
			return true
			
		if !include_end:
			if y == y2:
				return true
				
		if self.board_indexes[x + y * self.size.x] != null:
			return false
			
		if include_end:
			if y == y2:
				return true
	return true

# Returns true if all tiles in row y from x1 (excl) to x2 (incl)
# are empty
func _is_row_empty(x1: int, x2: int, y: int, include_end: bool) -> bool:
	# Same tile - return true
	if x1 == x2:
		return true

	# Outside bounds of board - return true
	if y < 0 || y >= self.size.y:
		return true
		
	var delta = 1 if x1 < x2 else -1
	var x = x1
	while true:
		x += delta
		if x < 0 || x >= size.x:
			return true
		
		if !include_end:
			if x == x2:
				return true
			
		if self.board_indexes[x + y * self.size.x] != null:
			return false
		
		if include_end:
			if x == x2:
				return true
	return true

func _can_move() -> bool:
	for pos1 in range(self.board_indexes.size()):
		var tile_type = self.board_indexes[pos1]
		if tile_type == null:
			continue
		
		var tiles = self.same_tiles[tile_type]
		for i in range(tiles.size()):
			var pos2 = tiles[i]

			if pos2 <= pos1:
				# We would already have checked this combo, so skip it
				continue

			if self.try_join(pos1, pos2) != null:
				return true
	return false

func _check_game_over() -> void:
	if self.remaining == 0:
		if !self.suppress_signals:
			emit_signal("win")
		return
		
	if not self._can_move():
		if !self.suppress_signals:
			emit_signal("no_more_moves")
		return

# Calculates whether the board as it stands can be completed
func _can_win(stop_ticks: int) -> bool:
	self.suppress_signals = true
	var states_already_calculated = {}
	var result = self._recursive_can_win(states_already_calculated, stop_ticks)
	if !result:
		print("can-win: ", result)
	self.suppress_signals = false
	return result
	
func _recursive_can_win(states_already_calculated: Dictionary, stop_ticks: int) -> bool:
	if remaining == 0:
		return true
		
	if OS.get_ticks_msec() > stop_ticks:
		return true

	var h = self._hash()
	if states_already_calculated.has(h):
		return false

	for p1 in range(self.board_indexes.size()):
		var tile_type = self.board_indexes[p1]
		if tile_type == null:
			continue

		var similar_tiles = self.same_tiles[tile_type]
		for i in range(similar_tiles.size()):
			var p2 = similar_tiles[i]
			if p2 <= p1:
				continue

			var j = self.try_join(p1, p2)
			if j == null:
				continue

			self.remove_join(j)
			var w = self._recursive_can_win(states_already_calculated, stop_ticks)
			self._unremove_join(j)
			if w:
				return true

	states_already_calculated[h] = false
	return false

func _hash() -> String:
	return to_json(self.board_indexes)
