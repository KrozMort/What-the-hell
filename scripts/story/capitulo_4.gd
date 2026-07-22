extends Node2D

const NEXT_SCENE := "res://scenes/story/capitulo_5.tscn"
const TITLE_FADE_IN_TIME := 1.0
const TITLE_HOLD_TIME := 1.5
const TITLE_FADE_OUT_TIME := 1.0
const SCENE_FADE_IN_TIME := 1.5
const SCENE_FADE_OUT_TIME := 1.0

@onready var fade: ColorRect = $Transition/Fade
@onready var chapter_title: Label = $Transition/ChapterTitle
@onready var button_texture: TextureRect = $CanvasLayer/Control/ButtonTexture
@onready var continue_button: Button = $CanvasLayer/Control/Button

var time_alive := 0.0


func _ready() -> void:
	fade.color.a = 1.0
	chapter_title.modulate.a = 0.0
	continue_button.pressed.connect(_on_continue_pressed)
	_play_intro()


func _process(delta: float) -> void:
	time_alive += delta
	var hovered := continue_button.is_hovered()
	var idle_scale := 1.0 + sin(time_alive * 1.8) * 0.012
	var target_scale := Vector2.ONE * (1.1 if hovered else idle_scale)
	var warm_color := 0.85 + sin(time_alive * 3.1) * 0.03

	button_texture.pivot_offset = button_texture.size * 0.5
	button_texture.scale = button_texture.scale.lerp(target_scale, delta * 8.0)
	button_texture.modulate = Color(1.0, 1.0 if hovered else 0.96, 0.82 if hovered else warm_color, 1.0)


## Muestra el titulo del capitulo sobre negro y luego revela la escena.
func _play_intro() -> void:
	var intro_tween := create_tween()
	intro_tween.tween_property(chapter_title, "modulate:a", 1.0, TITLE_FADE_IN_TIME)
	intro_tween.tween_interval(TITLE_HOLD_TIME)
	intro_tween.tween_property(chapter_title, "modulate:a", 0.0, TITLE_FADE_OUT_TIME)
	intro_tween.tween_property(fade, "color:a", 0.0, SCENE_FADE_IN_TIME)


func _on_continue_pressed() -> void:
	var fade_out := create_tween()
	fade_out.tween_property(fade, "color:a", 1.0, SCENE_FADE_OUT_TIME)
	await fade_out.finished
	get_tree().change_scene_to_file(NEXT_SCENE)
