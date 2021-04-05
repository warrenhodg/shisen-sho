extends Reference
class_name Join

export var tile_type: int
export var p1: int
export var p2: int
export var t1: Vector2
export var t2: Vector2
export var is_row: bool
export var value: int

func _init(_tile_type: int, _p1: int, _p2: int, _t1: Vector2, _t2: Vector2, _is_row: bool, _value: int) -> void:
	self.tile_type = _tile_type
	self.p1 = _p1
	self.p2 = _p2
	self.t1 = _t1
	self.t2 = _t2
	self.is_row = _is_row
	self.value = _value
