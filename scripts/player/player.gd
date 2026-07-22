class_name Player
extends CharacterBody2D

signal health_changed(current_health: int, maximum_health: int)
signal stamina_changed(current_stamina: float, maximum_stamina: float)
signal died

## Estados de locomoción y combate disponibles para el personaje.
enum State {
	IDLE,
	WALK,
	JUMP,
	FALL,
	ATTACK,
	DODGE,
	DEATH,
}

const FRAME_SIZE := Vector2(120.0, 80.0)
const ANIMATION_NAMES := {
	State.IDLE: &"Idle",
	State.WALK: &"Walk",
	State.JUMP: &"Jump",
	State.FALL: &"Fall",
}
const NORMAL_ATTACK_ANIMATIONS: Array[StringName] = [&"Attack1", &"Attack2"]
const SPECIAL_ATTACK_ANIMATION: StringName = &"AttackCombo"

const IDLE_TEXTURE := preload("res://assets/characters/player/main/spritesheets/player_idle.png")
const WALK_TEXTURE := preload("res://assets/characters/player/main/spritesheets/player_run.png")
const JUMP_TEXTURE := preload("res://assets/characters/player/main/spritesheets/player_jump.png")
const FALL_TEXTURE := preload("res://assets/characters/player/main/spritesheets/player_fall.png")
const ATTACK_1_TEXTURE := preload("res://assets/characters/player/main/spritesheets/player_attack_1_stationary.png")
const ATTACK_2_TEXTURE := preload("res://assets/characters/player/main/spritesheets/player_attack_2_stationary.png")
const ATTACK_COMBO_TEXTURE := preload("res://assets/characters/player/main/spritesheets/player_attack_combo_stationary.png")
const DODGE_TEXTURE := preload("res://assets/characters/player/main/spritesheets/player_roll.png")
const DEATH_TEXTURE := preload("res://assets/characters/player/main/spritesheets/player_death_stationary.png")

const JUMP_SOUND := preload("res://assets/audio/sfx/jump.mp3")
const DODGE_SOUND := preload("res://assets/audio/sfx/dodge.mp3")
const SWORD_1_SOUND := preload("res://assets/audio/sfx/sword_1.mp3")
const SWORD_2_SOUND := preload("res://assets/audio/sfx/sword_2.mp3")
const HURT_SOUND := preload("res://assets/audio/sfx/player_hurt.mp3")
const DEATH_SOUND := preload("res://assets/audio/sfx/player_death.mp3")
const SPECIAL_ATTACK_COMBO_DELAY := 0.18

@export_category("Movimiento")
@export var move_speed: float = 300.0
@export var jump_velocity: float = -650.0
@export var gravity: float = 1800.0
@export var ground_deceleration: float = 1800.0

@export_category("Vida")
@export var max_health: int = 100

@export_category("Combate")
@export var normal_attack_damage: int = 20
@export var special_attack_damage: int = 40
@export var normal_attack_range: float = 190.0
@export var special_attack_range: float = 250.0
@export var hurt_invulnerability_time: float = 0.45

@export_category("Esquiva")
@export var dodge_speed: float = 650.0
@export var dodge_cooldown: float = 0.45
@export var max_stamina: float = 100.0
@export var dodge_stamina_cost: float = 35.0
@export var stamina_recovery_speed: float = 28.0

@export_category("Animación")
@export_range(1.0, 4.0, 0.1) var visual_scale: float = 2.8
@export var idle_fps: float = 10.0
@export var walk_fps: float = 14.0
@export var jump_fps: float = 10.0
@export var fall_fps: float = 10.0
@export var attack_fps: float = 14.0
@export var dodge_fps: float = 20.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var movement_sfx: AudioStreamPlayer = $MovementSfx
@onready var combat_sfx: AudioStreamPlayer = $CombatSfx
@onready var status_sfx: AudioStreamPlayer = $StatusSfx

var current_state: State = State.IDLE
var is_dead: bool = false
var input_direction: float = 0.0
var next_normal_attack_index: int = 0
var dodge_direction: float = 1.0
var dodge_cooldown_remaining: float = 0.0
var is_invulnerable: bool = false
var hurt_invulnerability_remaining: float = 0.0
var attack_has_dealt_damage: bool = false
var current_health: int
var current_stamina: float


func _ready() -> void:
	current_health = max_health
	current_stamina = max_stamina
	_configure_existing_animations()
	animated_sprite.scale = Vector2.ONE * visual_scale
	animated_sprite.frame_changed.connect(_on_frame_changed)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	_change_state(_get_locomotion_state())
	health_changed.emit(current_health, max_health)
	stamina_changed.emit(current_stamina, max_stamina)


## Punto de entrada para el daño enemigo; la esquiva lo bloquea por completo.
func take_damage(amount: int) -> void:
	if is_invulnerable or amount <= 0 or is_dead:
		return

	current_health = maxi(current_health - amount, 0)
	health_changed.emit(current_health, max_health)

	if current_health == 0:
		_die()
		return

	is_invulnerable = true
	hurt_invulnerability_remaining = hurt_invulnerability_time
	animated_sprite.modulate = Color(1.0, 0.35, 0.35)
	var recovery_tween := create_tween()
	recovery_tween.tween_property(animated_sprite, "modulate", Color.WHITE, hurt_invulnerability_time)
	_play_sound(status_sfx, HURT_SOUND)


## Detiene todo control del jugador y reproduce la animación de muerte.
func _die() -> void:
	is_dead = true
	is_invulnerable = true
	current_state = State.DEATH
	velocity.x = 0.0
	animated_sprite.modulate = Color.WHITE
	animated_sprite.play(&"Death")
	_play_sound(status_sfx, DEATH_SOUND)


func heal(amount: int) -> bool:
	if amount <= 0 or current_health >= max_health:
		return false

	current_health = mini(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)
	return true


func _physics_process(delta: float) -> void:
	dodge_cooldown_remaining = maxf(dodge_cooldown_remaining - delta, 0.0)
	_update_hurt_invulnerability(delta)
	_recover_stamina(delta)
	_read_movement_input()
	_apply_gravity(delta)
	_process_current_state(delta)
	move_and_slide()
	_update_state_after_movement()


## Delega el comportamiento al estado activo y mantiene Attack como estado exclusivo.
func _process_current_state(delta: float) -> void:
	match current_state:
		State.ATTACK:
			_process_attack(delta)
		State.DODGE:
			_process_dodge()
		State.IDLE, State.WALK, State.JUMP, State.FALL:
			_process_locomotion()


func _process_locomotion() -> void:
	_apply_horizontal_movement()

	if Input.is_action_just_pressed("dodge") and is_on_floor() and _can_dodge():
		_start_dodge()
		return

	if Input.is_action_just_pressed("special_attack"):
		_start_special_attack()
		return

	if Input.is_action_just_pressed("attack"):
		_start_normal_attack()
		return

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		_change_state(State.JUMP)
		_play_sound(movement_sfx, JUMP_SOUND)
		return

	_change_state(_get_locomotion_state())


## El ataque no admite interrupciones ni movimiento horizontal nuevo.
func _process_attack(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, ground_deceleration * delta)


func _process_dodge() -> void:
	velocity.x = dodge_direction * dodge_speed


func _read_movement_input() -> void:
	input_direction = Input.get_axis("move_left", "move_right")


func _apply_horizontal_movement() -> void:
	velocity.x = input_direction * move_speed
	if not is_zero_approx(input_direction):
		animated_sprite.flip_h = input_direction < 0.0


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta


## Reevalúa el suelo después de move_and_slide(), sin interrumpir un ataque.
func _update_state_after_movement() -> void:
	if current_state != State.ATTACK and current_state != State.DODGE and current_state != State.DEATH:
		_change_state(_get_locomotion_state())


func _get_locomotion_state() -> State:
	if not is_on_floor():
		return State.JUMP if velocity.y < 0.0 else State.FALL
	if not is_zero_approx(input_direction):
		return State.WALK
	return State.IDLE


func _change_state(new_state: State) -> void:
	if current_state == new_state and animated_sprite.is_playing():
		return

	current_state = new_state
	animated_sprite.play(ANIMATION_NAMES[current_state])


## Alterna los dos golpes normales disponibles con el clic izquierdo.
func _start_normal_attack() -> void:
	current_state = State.ATTACK
	attack_has_dealt_damage = false
	animated_sprite.play(NORMAL_ATTACK_ANIMATIONS[next_normal_attack_index])
	_play_sound(combat_sfx, SWORD_1_SOUND if next_normal_attack_index == 0 else SWORD_2_SOUND)
	next_normal_attack_index = (next_normal_attack_index + 1) % NORMAL_ATTACK_ANIMATIONS.size()


## Ejecuta el combo existente como poder especial con el clic derecho.
func _start_special_attack() -> void:
	current_state = State.ATTACK
	attack_has_dealt_damage = false
	animated_sprite.play(SPECIAL_ATTACK_ANIMATION)
	_play_sound(combat_sfx, SWORD_1_SOUND)
	var combo_tween := create_tween()
	combo_tween.tween_interval(SPECIAL_ATTACK_COMBO_DELAY)
	combo_tween.tween_callback(_play_sound.bind(combat_sfx, SWORD_2_SOUND))


## Inicia una voltereta hacia la entrada actual o hacia donde mira el personaje.
func _start_dodge() -> void:
	current_stamina = maxf(current_stamina - dodge_stamina_cost, 0.0)
	stamina_changed.emit(current_stamina, max_stamina)
	dodge_direction = input_direction
	if is_zero_approx(dodge_direction):
		dodge_direction = -1.0 if animated_sprite.flip_h else 1.0

	animated_sprite.flip_h = dodge_direction < 0.0
	current_state = State.DODGE
	is_invulnerable = true
	dodge_cooldown_remaining = dodge_cooldown
	animated_sprite.play(&"Dodge")
	_play_sound(movement_sfx, DODGE_SOUND)


func _can_dodge() -> bool:
	return is_zero_approx(dodge_cooldown_remaining) and current_stamina >= dodge_stamina_cost


func _play_sound(player: AudioStreamPlayer, stream: AudioStream) -> void:
	player.stream = stream
	player.play()


func _on_frame_changed() -> void:
	if current_state != State.ATTACK or attack_has_dealt_damage:
		return

	var frame_count := animated_sprite.sprite_frames.get_frame_count(animated_sprite.animation)
	var hit_frame := maxi(int(floor(frame_count * 0.45)), 1)
	if animated_sprite.frame >= hit_frame:
		_deal_attack_damage()


func _on_animation_finished() -> void:
	if current_state == State.ATTACK:
		if not attack_has_dealt_damage:
			_deal_attack_damage()
		_change_state(_get_locomotion_state())
	elif current_state == State.DODGE:
		is_invulnerable = false
		velocity.x = 0.0
		_change_state(_get_locomotion_state())
	elif current_state == State.DEATH:
		died.emit()


## Daña solamente a los enemigos situados delante del personaje.
func _deal_attack_damage() -> void:
	attack_has_dealt_damage = true
	var is_special := animated_sprite.animation == SPECIAL_ATTACK_ANIMATION
	var damage := special_attack_damage if is_special else normal_attack_damage
	var attack_range := special_attack_range if is_special else normal_attack_range
	var facing_direction := -1.0 if animated_sprite.flip_h else 1.0

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy is Node2D or not enemy.has_method("take_damage"):
			continue

		var offset: Vector2 = enemy.global_position - global_position
		var is_in_front := offset.x * facing_direction >= 0.0
		if is_in_front and absf(offset.x) <= attack_range and absf(offset.y) <= 150.0:
			enemy.call("take_damage", damage)


func _update_hurt_invulnerability(delta: float) -> void:
	if current_state == State.DODGE or is_zero_approx(hurt_invulnerability_remaining):
		return

	hurt_invulnerability_remaining = maxf(hurt_invulnerability_remaining - delta, 0.0)
	if is_zero_approx(hurt_invulnerability_remaining):
		is_invulnerable = false


func _recover_stamina(delta: float) -> void:
	if current_state == State.DODGE or is_equal_approx(current_stamina, max_stamina):
		return

	current_stamina = minf(current_stamina + stamina_recovery_speed * delta, max_stamina)
	stamina_changed.emit(current_stamina, max_stamina)


## Registra como SpriteFrames las secuencias ya dibujadas en los spritesheets.
func _configure_existing_animations() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_animation(frames, &"Idle", IDLE_TEXTURE, 10, idle_fps, true)
	_add_animation(frames, &"Walk", WALK_TEXTURE, 10, walk_fps, true)
	_add_animation(frames, &"Jump", JUMP_TEXTURE, 3, jump_fps, true)
	_add_animation(frames, &"Fall", FALL_TEXTURE, 3, fall_fps, true)
	_add_animation(frames, &"Attack1", ATTACK_1_TEXTURE, 4, attack_fps, false)
	_add_animation(frames, &"Attack2", ATTACK_2_TEXTURE, 6, attack_fps, false)
	_add_animation(frames, &"AttackCombo", ATTACK_COMBO_TEXTURE, 10, attack_fps, false)
	_add_animation(frames, &"Dodge", DODGE_TEXTURE, 12, dodge_fps, false)
	_add_animation(frames, &"Death", DEATH_TEXTURE, 10, attack_fps, false)
	animated_sprite.sprite_frames = frames


func _add_animation(
	frames: SpriteFrames,
	animation_name: StringName,
	texture: Texture2D,
	frame_count: int,
	fps: float,
	loops: bool
) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, loops)

	for frame_index in frame_count:
		var frame := AtlasTexture.new()
		frame.atlas = texture
		frame.region = Rect2(Vector2(FRAME_SIZE.x * frame_index, 0.0), FRAME_SIZE)
		frames.add_frame(animation_name, frame)
