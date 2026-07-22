class_name SpritesheetFrames

static func add_animation(frames: SpriteFrames, anim_name: String, texture: Texture2D, frame_width: int, frame_height: int, fps: float, loop: bool) -> void:
	if frames.has_animation(anim_name):
		frames.remove_animation(anim_name)
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, fps)
	frames.set_animation_loop(anim_name, loop)
	@warning_ignore("integer_division")
	var frame_count := texture.get_width() / frame_width
	for i in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
		frames.add_frame(anim_name, atlas)
