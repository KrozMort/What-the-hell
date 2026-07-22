class_name Enemy
extends CharacterBody2D

const HEALTH_HEART_PICKUP_SCENE := preload("res://scenes/items/health_heart_pickup.tscn")

enum State {
	IDLE,
	CHASE,
	ATTACK,
	HURT,
	DEATH,
}

const FRAME_SIZE := Vector2(150.0, 150.0)
const ATTACK_NAMES: Array[StringName] = [&"Attack1", &"Attack2"]

@export_category("Sprites existentes")
@export var idle_texture: Texture2D
@export var move_texture: Texture2D
@export var attack_texture: Texture2D
@export var attack_alt_texture: Texture2D
@export var hurt_texture: Texture2D
@export var death_texture: Texture2D

@export_category("Comportamiento")
@export var move_speed: float = 120.0
@export var detection_range: float = 320.0
@export var attack_range: float = 145.0
@export var attack_cooldown: float = 0.8
@export var attack_damage: int = 10
@export var max_health: int = 60
@export var uses_gravity: bool = true
@export var gravity: float = 1800.0
@export var sprite_faces_right: bool = true
@export_range(0.0, 1.0, 0.01) var health_drop_chance: float = 0.35
@export var health_drop_amount: int = 20

@export_category("Animación")
@export_range(1.0, 4.0, 0.1) var visual_scale: float = 2.8
@export var idle_fps: float = 8.0
@export var move_fps: float = 12.0
@export var attack_fps: float = 12.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var current_state: State = State.IDLE
var target: Node2D
var attack_cooldown_remaining: float = 0.0
var next_attack_index: int = 0
var current_health: int
var death_animation_finished: bool = false
var is_disappearing: bool = false
var attack_has_dealt_damage: bool = false


func _ready() -> void:
	current_health = max_health
	_configure_animations()
	animated_sprite.scale = Vector2.ONE * visual_scale
	animated_sprite.frame_changed.connect(_on_frame_changed)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	target = get_tree().get_first_node_in_group("player") as Node2D
	_change_state(State.IDLE)


func _physics_process(delta: float) -> void:
	attack_cooldown_remaining = maxf(attack_cooldown_remaining - delta, 0.0)
	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player") as Node2D

	_apply_vertical_movement(delta)
	_process_state()
	move_and_slide()
	_finish_death_if_ready()


func _process_state() -> void:
	match current_state:
		State.ATTACK:
			velocity.x = move_toward(velocity.x, 0.0, move_speed)
		State.HURT, State.DEATH:
			velocity.x = 0.0
		State.IDLE, State.CHASE:
			_choose_action()


func _choose_action() -> void:
	if not is_instance_valid(target):
		velocity.x = 0.0
		_change_state(State.IDLE)
		return

	var horizontal_distance := absf(target.global_position.x - global_position.x)
	var vertical_distance := absf(target.global_position.y - global_position.y)
	var distance_to_target := global_position.distance_to(target.global_position)
	if horizontal_distance <= attack_range and vertical_distance <= 150.0 and is_zero_approx(attack_cooldown_remaining):
		_start_attack()
	elif distance_to_target <= detection_range:
		_chase_target()
	else:
		velocity.x = 0.0
		_change_state(State.IDLE)


func _chase_target() -> void:
	var direction := signf(target.global_position.x - global_position.x)
	velocity.x = direction * move_speed
	animated_sprite.flip_h = direction < 0.0 if sprite_faces_right else direction > 0.0
	_change_state(State.CHASE)


func _start_attack() -> void:
	current_state = State.ATTACK
	velocity.x = 0.0
	attack_has_dealt_damage = false
	animated_sprite.play(ATTACK_NAMES[next_attack_index])
	next_attack_index = (next_attack_index + 1) % ATTACK_NAMES.size()


func _apply_vertical_movement(delta: float) -> void:
	if uses_gravity or current_state == State.DEATH:
		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			velocity.y = 0.0
	else:
		if current_state in [State.CHASE, State.ATTACK] and is_instance_valid(target):
			var desired_height := target.global_position.y - 80.0
			velocity.y = clampf((desired_height - global_position.y) * 2.0, -move_speed, move_speed)
		else:
			velocity.y = 0.0


func _change_state(new_state: State) -> void:
	if current_state == new_state and animated_sprite.is_playing():
		return

	current_state = new_state
	animated_sprite.play(&"Move" if current_state == State.CHASE else &"Idle")


func take_damage(amount: int) -> void:
	if current_state == State.DEATH or amount <= 0:
		return

	current_health = maxi(current_health - amount, 0)
	velocity.x = 0.0
	if current_health == 0:
		current_state = State.DEATH
		death_animation_finished = false
		animated_sprite.play(&"Death")
	else:
		current_state = State.HURT
		animated_sprite.play(&"Hurt")


func _on_frame_changed() -> void:
	if current_state != State.ATTACK or attack_has_dealt_damage:
		return

	var frame_count := animated_sprite.sprite_frames.get_frame_count(animated_sprite.animation)
	var hit_frame := maxi(int(floor(frame_count * 0.5)), 1)
	if animated_sprite.frame >= hit_frame:
		_apply_attack_damage()


func _on_animation_finished() -> void:
	match current_state:
		State.ATTACK:
			if not attack_has_dealt_damage:
				_apply_attack_damage()
			attack_cooldown_remaining = attack_cooldown
			_change_state(State.IDLE)
		State.HURT:
			_change_state(State.IDLE)
		State.DEATH:
			death_animation_finished = true


## Espera a que el enemigo haya caído y terminado su animación antes de borrarlo.
func _apply_attack_damage() -> void:
	attack_has_dealt_damage = true
	if not is_instance_valid(target) or not target.has_method("take_damage"):
		return

	var offset := target.global_position - global_position
	var facing_direction := -1.0 if animated_sprite.flip_h == sprite_faces_right else 1.0
	var is_in_front := offset.x * facing_direction >= -8.0
	if is_in_front and absf(offset.x) <= attack_range + 35.0 and absf(offset.y) <= 150.0:
		target.call("take_damage", attack_damage)


func _finish_death_if_ready() -> void:
	if current_state != State.DEATH or not death_animation_finished or not is_on_floor() or is_disappearing:
		return

	is_disappearing = true
	_spawn_health_drop()
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	var disappear_tween := create_tween()
	disappear_tween.set_parallel(true)
	disappear_tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.45)
	disappear_tween.tween_property(animated_sprite, "scale", animated_sprite.scale * 0.8, 0.45)
	disappear_tween.chain().tween_callback(queue_free)


func _spawn_health_drop() -> void:
	if health_drop_chance <= 0.0 or randf() > health_drop_chance:
		return

	var pickup := HEALTH_HEART_PICKUP_SCENE.instantiate() as Area2D
	pickup.set("heal_amount", health_drop_amount)
	var parent := get_tree().current_scene
	if is_instance_valid(parent):
		parent.add_child(pickup)
		pickup.global_position = global_position + Vector2(0.0, -42.0)


func _configure_animations() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var idle_source := idle_texture if idle_texture else move_texture
	_add_animation(frames, &"Idle", idle_source, _get_frame_count(idle_source), idle_fps, true)
	_add_animation(frames, &"Move", move_texture, _get_frame_count(move_texture), move_fps, true)
	_add_animation(frames, &"Attack1", attack_texture, _get_frame_count(attack_texture), attack_fps, false)
	_add_animation(frames, &"Attack2", attack_alt_texture, _get_frame_count(attack_alt_texture), attack_fps, false)
	_add_animation(frames, &"Hurt", hurt_texture, _get_frame_count(hurt_texture), attack_fps, false)
	_add_animation(frames, &"Death", death_texture, _get_frame_count(death_texture), attack_fps, false)
	animated_sprite.sprite_frames = frames


func _get_frame_count(texture: Texture2D) -> int:
	return maxi(int(texture.get_width() / FRAME_SIZE.x), 1)


func _add_animation(frames: SpriteFrames, name: StringName, texture: Texture2D, count: int, fps: float, loops: bool) -> void:
	frames.add_animation(name)
	frames.set_animation_speed(name, fps)
	frames.set_animation_loop(name, loops)
	for frame_index in count:
		var frame := AtlasTexture.new()
		frame.atlas = texture
		frame.region = Rect2(Vector2(FRAME_SIZE.x * frame_index, 0.0), FRAME_SIZE)
		frames.add_frame(name, frame)
