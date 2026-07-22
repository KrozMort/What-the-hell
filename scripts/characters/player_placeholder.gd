extends CharacterBody2D

const PLAYER_SPRITE_DIR := "res://assets/characters/player/main/spritesheets/"
const FRAME_WIDTH := 120
const FRAME_HEIGHT := 80
const SPEED := 260.0
const JUMP_VELOCITY := -520.0
const GRAVITY := 1400.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	SpritesheetFrames.add_animation(frames, "idle", load(PLAYER_SPRITE_DIR + "player_idle.png"), FRAME_WIDTH, FRAME_HEIGHT, 8.0, true)
	SpritesheetFrames.add_animation(frames, "run", load(PLAYER_SPRITE_DIR + "player_run.png"), FRAME_WIDTH, FRAME_HEIGHT, 14.0, true)
	SpritesheetFrames.add_animation(frames, "jump", load(PLAYER_SPRITE_DIR + "player_jump.png"), FRAME_WIDTH, FRAME_HEIGHT, 10.0, false)
	SpritesheetFrames.add_animation(frames, "fall", load(PLAYER_SPRITE_DIR + "player_fall.png"), FRAME_WIDTH, FRAME_HEIGHT, 10.0, true)
	sprite.sprite_frames = frames
	sprite.play("idle")


func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta

	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = direction * SPEED

	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY

	move_and_slide()
	_update_animation(direction)


func _update_animation(direction: float) -> void:
	if not is_on_floor():
		sprite.play("jump" if velocity.y < 0.0 else "fall")
		return
	if direction != 0.0:
		sprite.play("run")
		sprite.flip_h = direction < 0.0
	else:
		sprite.play("idle")
