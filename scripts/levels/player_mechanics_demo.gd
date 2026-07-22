extends Node2D

const MAIN_MENU_SCENE := "res://scenes/backgrounds/mountain_dusk_auto_scroller.tscn"
const NEXT_LEVEL_SCENE := "res://scenes/story/capitulo_1.tscn"
const BOSS_ONE_SCENE := preload("res://scenes/bosses/boss_1.tscn")
const HEALTH_HEART_PICKUP_SCENE := preload("res://scenes/items/health_heart_pickup.tscn")
const INSTRUCTIONS_VISIBLE_TIME := 3.0
const INSTRUCTIONS_FADE_TIME := 0.35
const WELCOME_FADE_IN_TIME := 2.0
const WELCOME_HOLD_TIME := 2.5
const WELCOME_FADE_OUT_TIME := 2.0
const END_FADE_TIME := 1.5
const BOSS_SPAWN_POSITION := Vector2(3400.0, 684.0)
const BOSS_TRIGGER_X := 2800.0
const HEART_SCENE_POSITIONS: Array[Vector2] = [
	Vector2(520.0, 660.0),
	Vector2(980.0, 640.0),
	Vector2(1660.0, 675.0),
	Vector2(2240.0, 640.0),
	Vector2(3020.0, 660.0),
]
const HEART_SCENE_MIN_SPAWNS := 2
const HEART_SCENE_MAX_SPAWNS := 3

const FLOOR_TEXTURE := preload("res://assets/environments/tutorial/floor_dirt.png")
const FLOOR_TOP_Y := 740.0
const FLOOR_BOTTOM_Y := 900.0
const FLOOR_WIDTH := 4200.0
const FLOOR_TILE_WIDTH := 280.0

@onready var player: Player = $Player
@onready var welcome_message: Label = $Interface/WelcomeMessage
@onready var fade: ColorRect = $Transition/Fade
@onready var objective_label: Label = $Interface/Objective
@onready var instructions_panel: PanelContainer = $Interface/Instructions
@onready var health_bar: TextureProgressBar = $Interface/Hud/Bars/HealthBar
@onready var stamina_bar: TextureProgressBar = $Interface/Hud/Bars/StaminaBar
@onready var boss_gate_collision: CollisionShape2D = $BossGate/CollisionShape2D
@onready var boss_gate_visual: Line2D = $BossGateVisual
@onready var ambience: AudioStreamPlayer = $Ambience

var initial_wave_cleared: bool = false
var boss_spawned: bool = false


func _ready() -> void:
	randomize()
	objective_label.text = "OBJETIVO: Derrota a todos los enemigos"
	player.health_changed.connect(_on_player_health_changed)
	player.stamina_changed.connect(_on_player_stamina_changed)
	player.died.connect(_on_player_died)
	_on_player_health_changed(player.current_health, player.max_health)
	_on_player_stamina_changed(player.current_stamina, player.max_stamina)
	_build_floor()
	_spawn_scene_hearts()
	_hide_instructions_after_delay()
	_show_welcome_message()
	if ambience.stream:
		ambience.stream.loop = true
		ambience.play()


func _process(_delta: float) -> void:
	if not initial_wave_cleared and _get_living_regular_enemies() == 0:
		_open_path_to_boss()

	if initial_wave_cleared and not boss_spawned and player.global_position.x >= BOSS_TRIGGER_X:
		_spawn_boss_one()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _show_welcome_message() -> void:
	var tween := create_tween()
	tween.tween_property(welcome_message, "modulate:a", 1.0, WELCOME_FADE_IN_TIME)
	tween.tween_interval(WELCOME_HOLD_TIME)
	tween.tween_property(welcome_message, "modulate:a", 0.0, WELCOME_FADE_OUT_TIME)


func _hide_instructions_after_delay() -> void:
	instructions_panel.show()
	instructions_panel.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(INSTRUCTIONS_VISIBLE_TIME)
	tween.tween_property(instructions_panel, "modulate:a", 0.0, INSTRUCTIONS_FADE_TIME)
	tween.tween_callback(instructions_panel.hide)


func _get_living_regular_enemies() -> int:
	var count := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.is_in_group("bosses"):
			count += 1
	return count


func _open_path_to_boss() -> void:
	initial_wave_cleared = true
	boss_gate_collision.set_deferred("disabled", true)
	boss_gate_visual.visible = false
	objective_label.text = "OBJETIVO: Avanza para encontrar al Jefe 1"


func _spawn_boss_one() -> void:
	boss_spawned = true
	var boss := BOSS_ONE_SCENE.instantiate() as BossOne
	add_child(boss)
	boss.global_position = BOSS_SPAWN_POSITION
	boss.defeated.connect(_on_boss_defeated)
	objective_label.text = "JEFE 1 - FASE 1"
	boss.phase_changed.connect(_on_boss_phase_changed)


func _on_boss_phase_changed(phase: int, _health: int, _maximum_health: int) -> void:
	objective_label.text = "JEFE 1 - FASE %d" % phase


func _on_boss_defeated() -> void:
	objective_label.text = "JEFE 1 DERROTADO"
	_finish_tutorial()


func _finish_tutorial() -> void:
	var fade_out := create_tween()
	fade_out.tween_property(fade, "color:a", 1.0, END_FADE_TIME)
	await fade_out.finished
	get_tree().change_scene_to_file(NEXT_LEVEL_SCENE)


func _on_player_died() -> void:
	objective_label.text = "Has caido..."
	await get_tree().create_timer(0.8).timeout
	var fade_out := create_tween()
	fade_out.tween_property(fade, "color:a", 1.0, END_FADE_TIME)
	await fade_out.finished
	get_tree().reload_current_scene()


func _on_player_health_changed(current_health: int, maximum_health: int) -> void:
	health_bar.max_value = maximum_health
	health_bar.value = current_health


func _on_player_stamina_changed(current_stamina: float, maximum_stamina: float) -> void:
	stamina_bar.max_value = maximum_stamina
	stamina_bar.value = current_stamina


func _build_floor() -> void:
	var tile_height := FLOOR_BOTTOM_Y - FLOOR_TOP_Y
	var scale_x := FLOOR_TILE_WIDTH / FLOOR_TEXTURE.get_width()
	var scale_y := tile_height / FLOOR_TEXTURE.get_height()
	var tile_count := int(ceil(FLOOR_WIDTH / FLOOR_TILE_WIDTH))

	for i in range(tile_count):
		var tile := Sprite2D.new()
		tile.texture = FLOOR_TEXTURE
		tile.centered = false
		tile.scale = Vector2(scale_x, scale_y)
		tile.position = Vector2(i * FLOOR_TILE_WIDTH, FLOOR_TOP_Y)
		tile.z_index = -1
		add_child(tile)


func _spawn_scene_hearts() -> void:
	var heart_count := randi_range(HEART_SCENE_MIN_SPAWNS, HEART_SCENE_MAX_SPAWNS)
	var available_positions := HEART_SCENE_POSITIONS.duplicate()
	available_positions.shuffle()

	for heart_index in mini(heart_count, available_positions.size()):
		var heart := HEALTH_HEART_PICKUP_SCENE.instantiate() as Node2D
		add_child(heart)
		heart.global_position = available_positions[heart_index]
