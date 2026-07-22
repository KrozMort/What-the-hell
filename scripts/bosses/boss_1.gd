class_name BossOne
extends CharacterBody2D

signal phase_changed(phase: int, current_health: int, maximum_health: int)
signal health_changed(current_health: int, maximum_health: int)
signal defeated

enum State {
	IDLE,
	CHASE,
	ATTACK,
	HURT,
	TRANSFORM,
	DEATH,
}

const FRAME_SIZE := Vector2(72.0, 72.0)
const PHASE_HEALTH := [100, 150, 200]
const PHASE_SPEED := [95.0, 120.0, 150.0]
const PHASE_DAMAGE := [15, 20, 25]

const PHASE_TEXTURES := [
	{
		"idle": preload("res://assets/characters/bosses/boss_1/1/Idle.png"),
		"walk": preload("res://assets/characters/bosses/boss_1/1/Walk.png"),
		"hurt": preload("res://assets/characters/bosses/boss_1/1/Hurt.png"),
		"death": preload("res://assets/characters/bosses/boss_1/1/Death.png"),
		"intro": preload("res://assets/characters/bosses/boss_1/1/Out.png"),
		"attacks": [preload("res://assets/characters/bosses/boss_1/1/Attack.png")],
	},
	{
		"idle": preload("res://assets/characters/bosses/boss_1/2/Idle.png"),
		"walk": preload("res://assets/characters/bosses/boss_1/2/Walk.png"),
		"hurt": preload("res://assets/characters/bosses/boss_1/2/Hurt.png"),
		"death": preload("res://assets/characters/bosses/boss_1/2/Death.png"),
		"intro": preload("res://assets/characters/bosses/boss_1/2/Sneer.png"),
		"attacks": [
			preload("res://assets/characters/bosses/boss_1/2/Attack1.png"),
			preload("res://assets/characters/bosses/boss_1/2/Attack2.png"),
			preload("res://assets/characters/bosses/boss_1/2/Attack3.png"),
			preload("res://assets/characters/bosses/boss_1/2/Attack4.png"),
		],
	},
	{
		"idle": preload("res://assets/characters/bosses/boss_1/3/Idle.png"),
		"walk": preload("res://assets/characters/bosses/boss_1/3/Walk.png"),
		"hurt": preload("res://assets/characters/bosses/boss_1/3/Hurt.png"),
		"death": preload("res://assets/characters/bosses/boss_1/3/Death.png"),
		"intro": preload("res://assets/characters/bosses/boss_1/3/Sneer.png"),
		"attacks": [
			preload("res://assets/characters/bosses/boss_1/3/Attack1.png"),
			preload("res://assets/characters/bosses/boss_1/3/Attack2.png"),
			preload("res://assets/characters/bosses/boss_1/3/Attack3.png"),
			preload("res://assets/characters/bosses/boss_1/3/Attack4.png"),
		],
	},
]

@export_category("Combate")
@export var detection_range: float = 520.0
@export var attack_range: float = 175.0
@export var attack_cooldown: float = 0.7
@export var gravity: float = 1800.0

@export_category("Animación")
@export_range(1.0, 6.0, 0.1) var visual_scale: float = 4.0
@export var idle_fps: float = 8.0
@export var walk_fps: float = 10.0
@export var action_fps: float = 12.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var current_phase: int = 1
var current_health: int = PHASE_HEALTH[0]
var current_state: State = State.IDLE
var target: Node2D
var attack_cooldown_remaining: float = 0.0
var next_attack_index: int = 0
var final_death_animation_finished: bool = false
var is_disappearing: bool = false
var attack_has_dealt_damage: bool = false


func _ready() -> void:
	animated_sprite.scale = Vector2.ONE * visual_scale
	animated_sprite.frame_changed.connect(_on_frame_changed)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	target = get_tree().get_first_node_in_group("player") as Node2D
	_configure_phase_animations()
	_change_state(State.IDLE)
	phase_changed.emit(current_phase, current_health, _get_max_health())


func _physics_process(delta: float) -> void:
	attack_cooldown_remaining = maxf(attack_cooldown_remaining - delta, 0.0)
	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player") as Node2D

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	_process_state()
	move_and_slide()
	_finish_final_death_if_ready()


func _process_state() -> void:
	match current_state:
		State.IDLE, State.CHASE:
			_choose_action()
		State.ATTACK, State.HURT, State.TRANSFORM, State.DEATH:
			velocity.x = 0.0


func _choose_action() -> void:
	if not is_instance_valid(target):
		velocity.x = 0.0
		_change_state(State.IDLE)
		return

	var offset := target.global_position - global_position
	var distance := offset.length()
	if absf(offset.x) <= attack_range and absf(offset.y) <= 150.0 and is_zero_approx(attack_cooldown_remaining):
		_start_attack()
	elif distance <= detection_range:
		var direction := signf(offset.x)
		velocity.x = direction * PHASE_SPEED[current_phase - 1]
		animated_sprite.flip_h = direction < 0.0
		_change_state(State.CHASE)
	else:
		velocity.x = 0.0
		_change_state(State.IDLE)


func _start_attack() -> void:
	current_state = State.ATTACK
	velocity.x = 0.0
	attack_has_dealt_damage = false
	var attack_count: int = PHASE_TEXTURES[current_phase - 1]["attacks"].size()
	animated_sprite.play(StringName("Attack%d" % (next_attack_index + 1)))
	next_attack_index = (next_attack_index + 1) % attack_count


func take_damage(amount: int) -> void:
	if current_state in [State.TRANSFORM, State.DEATH] or amount <= 0:
		return

	current_health = maxi(current_health - amount, 0)
	health_changed.emit(current_health, _get_max_health())
	velocity.x = 0.0
	if current_health == 0:
		current_state = State.TRANSFORM if current_phase < 3 else State.DEATH
		final_death_animation_finished = false
		animated_sprite.play(&"Death")
	else:
		current_state = State.HURT
		animated_sprite.play(&"Hurt")


func _change_state(new_state: State) -> void:
	if current_state == new_state and animated_sprite.is_playing():
		return
	current_state = new_state
	animated_sprite.play(&"Walk" if current_state == State.CHASE else &"Idle")


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
		State.TRANSFORM:
			_advance_phase()
		State.DEATH:
			final_death_animation_finished = true


func _advance_phase() -> void:
	current_phase += 1
	current_health = _get_max_health()
	next_attack_index = 0
	_configure_phase_animations()
	current_state = State.HURT
	animated_sprite.play(&"Intro")
	phase_changed.emit(current_phase, current_health, _get_max_health())
	health_changed.emit(current_health, _get_max_health())


func _apply_attack_damage() -> void:
	attack_has_dealt_damage = true
	if not is_instance_valid(target) or not target.has_method("take_damage"):
		return

	var offset := target.global_position - global_position
	var facing_direction := -1.0 if animated_sprite.flip_h else 1.0
	var is_in_front := offset.x * facing_direction >= -10.0
	if is_in_front and absf(offset.x) <= attack_range + 45.0 and absf(offset.y) <= 155.0:
		target.call("take_damage", PHASE_DAMAGE[current_phase - 1])


func _finish_final_death_if_ready() -> void:
	if current_state != State.DEATH or not final_death_animation_finished or not is_on_floor() or is_disappearing:
		return
	is_disappearing = true
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.8)
	tween.tween_callback(defeated.emit)
	tween.tween_callback(queue_free)


func _configure_phase_animations() -> void:
	var data: Dictionary = PHASE_TEXTURES[current_phase - 1]
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_animation(frames, &"Idle", data["idle"], idle_fps, true)
	_add_animation(frames, &"Walk", data["walk"], walk_fps, true)
	_add_animation(frames, &"Hurt", data["hurt"], action_fps, false)
	_add_animation(frames, &"Death", data["death"], action_fps, false)
	_add_animation(frames, &"Intro", data["intro"], action_fps, false)
	var attacks: Array = data["attacks"]
	for index in attacks.size():
		_add_animation(frames, StringName("Attack%d" % (index + 1)), attacks[index], action_fps, false)
	animated_sprite.sprite_frames = frames


func _add_animation(frames: SpriteFrames, name: StringName, texture: Texture2D, fps: float, loops: bool) -> void:
	frames.add_animation(name)
	frames.set_animation_speed(name, fps)
	frames.set_animation_loop(name, loops)
	var frame_count := maxi(int(texture.get_width() / FRAME_SIZE.x), 1)
	for frame_index in frame_count:
		var frame := AtlasTexture.new()
		frame.atlas = texture
		frame.region = Rect2(Vector2(FRAME_SIZE.x * frame_index, 0.0), FRAME_SIZE)
		frames.add_frame(name, frame)


func _get_max_health() -> int:
	return PHASE_HEALTH[current_phase - 1]
