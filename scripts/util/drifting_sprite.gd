extends Sprite2D

@export var amplitude := 60.0
@export var speed := 0.15

var _base_x := 0.0
var _t := 0.0


func _ready() -> void:
	_base_x = position.x


func _process(delta: float) -> void:
	_t += delta * speed
	position.x = _base_x + sin(_t) * amplitude
