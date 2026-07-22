class_name HealthHeartPickup
extends Area2D

@export var heal_amount: int = 20

var _collected: bool = false

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	sprite.texture = _create_heart_texture()
	z_index = 200
	sprite.z_index = 200


func _on_body_entered(body: Node) -> void:
	if _collected or not body.has_method("heal"):
		return

	if body.call("heal", heal_amount):
		_collected = true
		monitoring = false
		monitorable = false
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.18)
		tween.tween_callback(queue_free)


func _create_heart_texture() -> Texture2D:
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	var heart_color := Color8(190, 58, 48, 255)
	var shadow_color := Color8(116, 34, 28, 255)
	var highlight_color := Color8(232, 146, 124, 255)

	var pixels := {
		Vector2i(7, 4): shadow_color,
		Vector2i(8, 4): shadow_color,
		Vector2i(9, 4): shadow_color,
		Vector2i(12, 4): shadow_color,
		Vector2i(13, 4): shadow_color,
		Vector2i(14, 4): shadow_color,
		Vector2i(6, 5): heart_color,
		Vector2i(7, 5): heart_color,
		Vector2i(8, 5): heart_color,
		Vector2i(9, 5): heart_color,
		Vector2i(10, 5): heart_color,
		Vector2i(11, 5): heart_color,
		Vector2i(12, 5): heart_color,
		Vector2i(13, 5): heart_color,
		Vector2i(14, 5): heart_color,
		Vector2i(15, 5): shadow_color,
		Vector2i(5, 6): heart_color,
		Vector2i(6, 6): heart_color,
		Vector2i(7, 6): heart_color,
		Vector2i(8, 6): heart_color,
		Vector2i(9, 6): heart_color,
		Vector2i(10, 6): heart_color,
		Vector2i(11, 6): heart_color,
		Vector2i(12, 6): heart_color,
		Vector2i(13, 6): heart_color,
		Vector2i(14, 6): heart_color,
		Vector2i(15, 6): heart_color,
		Vector2i(16, 6): shadow_color,
		Vector2i(5, 7): shadow_color,
		Vector2i(6, 7): heart_color,
		Vector2i(7, 7): heart_color,
		Vector2i(8, 7): heart_color,
		Vector2i(9, 7): heart_color,
		Vector2i(10, 7): heart_color,
		Vector2i(11, 7): heart_color,
		Vector2i(12, 7): heart_color,
		Vector2i(13, 7): heart_color,
		Vector2i(14, 7): heart_color,
		Vector2i(15, 7): heart_color,
		Vector2i(16, 7): heart_color,
		Vector2i(4, 8): heart_color,
		Vector2i(5, 8): heart_color,
		Vector2i(6, 8): heart_color,
		Vector2i(7, 8): heart_color,
		Vector2i(8, 8): heart_color,
		Vector2i(9, 8): heart_color,
		Vector2i(10, 8): heart_color,
		Vector2i(11, 8): heart_color,
		Vector2i(12, 8): heart_color,
		Vector2i(13, 8): heart_color,
		Vector2i(14, 8): heart_color,
		Vector2i(15, 8): heart_color,
		Vector2i(16, 8): heart_color,
		Vector2i(17, 8): shadow_color,
		Vector2i(4, 9): shadow_color,
		Vector2i(5, 9): heart_color,
		Vector2i(6, 9): heart_color,
		Vector2i(7, 9): heart_color,
		Vector2i(8, 9): heart_color,
		Vector2i(9, 9): heart_color,
		Vector2i(10, 9): heart_color,
		Vector2i(11, 9): heart_color,
		Vector2i(12, 9): heart_color,
		Vector2i(13, 9): heart_color,
		Vector2i(14, 9): heart_color,
		Vector2i(15, 9): heart_color,
		Vector2i(16, 9): heart_color,
		Vector2i(17, 9): shadow_color,
		Vector2i(5, 10): heart_color,
		Vector2i(6, 10): heart_color,
		Vector2i(7, 10): heart_color,
		Vector2i(8, 10): heart_color,
		Vector2i(9, 10): heart_color,
		Vector2i(10, 10): heart_color,
		Vector2i(11, 10): heart_color,
		Vector2i(12, 10): heart_color,
		Vector2i(13, 10): heart_color,
		Vector2i(14, 10): heart_color,
		Vector2i(15, 10): heart_color,
		Vector2i(16, 10): highlight_color,
		Vector2i(6, 11): heart_color,
		Vector2i(7, 11): heart_color,
		Vector2i(8, 11): heart_color,
		Vector2i(9, 11): heart_color,
		Vector2i(10, 11): heart_color,
		Vector2i(11, 11): heart_color,
		Vector2i(12, 11): heart_color,
		Vector2i(13, 11): heart_color,
		Vector2i(14, 11): heart_color,
		Vector2i(15, 11): highlight_color,
		Vector2i(7, 12): heart_color,
		Vector2i(8, 12): heart_color,
		Vector2i(9, 12): heart_color,
		Vector2i(10, 12): heart_color,
		Vector2i(11, 12): heart_color,
		Vector2i(12, 12): heart_color,
		Vector2i(13, 12): heart_color,
		Vector2i(14, 12): highlight_color,
		Vector2i(8, 13): heart_color,
		Vector2i(9, 13): heart_color,
		Vector2i(10, 13): heart_color,
		Vector2i(11, 13): heart_color,
		Vector2i(12, 13): heart_color,
		Vector2i(13, 13): highlight_color,
		Vector2i(9, 14): heart_color,
		Vector2i(10, 14): heart_color,
		Vector2i(11, 14): heart_color,
		Vector2i(12, 14): highlight_color,
		Vector2i(10, 15): heart_color,
		Vector2i(11, 15): heart_color,
		Vector2i(12, 15): highlight_color,
	}

	for pos in pixels.keys():
		image.set_pixelv(pos, pixels[pos])

	for y in range(4, 16):
		for x in range(4, 18):
			if image.get_pixel(x, y).a > 0.0 and x + 1 < 32 and image.get_pixel(x + 1, y).a == 0.0:
				image.set_pixel(x + 1, y, Color(0, 0, 0, 0))

	return ImageTexture.create_from_image(image)
