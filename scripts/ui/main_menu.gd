extends Node2D

@onready var music: AudioStreamPlayer = $AudioStreamPlayer
@onready var menu: VBoxContainer = $MainMenu/Root/Menu
@onready var title: TextureRect = $MainMenu/Root/Menu/Title
@onready var subtitle: Label = $MainMenu/Root/Menu/Subtitle
@onready var buttons: Control = $MainMenu/Root/Menu/Buttons
@onready var menu_option_images: Array[TextureRect] = [
	$MainMenu/Root/Menu/Buttons/NewGameArt,
	$MainMenu/Root/Menu/Buttons/ChapterArt,
	$MainMenu/Root/Menu/Buttons/CreditsArt,
	$MainMenu/Root/Menu/Buttons/ExitArt,
]
@onready var new_game_button: Button = $MainMenu/Root/Menu/Buttons/NewGame
@onready var chapter_button: Button = $MainMenu/Root/Menu/Buttons/Chapter
@onready var credits_button: Button = $MainMenu/Root/Menu/Buttons/Credits
@onready var exit_button: Button = $MainMenu/Root/Menu/Buttons/Exit
@onready var background_layers: Array[TextureRect] = [
	$BackFixedTuxture,
	$TextureRectFarClouds,
	$TextureRectNearClouds,
	$TextureRectFarMountains,
	$TextureRectMountains,
	$TextureRectTrees,
]
var menu_buttons: Array[Button] = []
var time_alive := 0.0


func _ready() -> void:
	menu_buttons = [new_game_button, chapter_button, credits_button, exit_button]
	subtitle.visible = false
	get_viewport().size_changed.connect(_apply_responsive_layout)
	music.finished.connect(_on_music_finished)
	new_game_button.pressed.connect(_on_new_game_pressed)
	chapter_button.pressed.connect(_on_chapter_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	if not music.playing:
		music.play()

	_apply_responsive_layout()


func _process(delta: float) -> void:
	time_alive += delta
	title.modulate = Color(1.0, 0.94 + sin(time_alive * 3.0) * 0.04, 0.72 + sin(time_alive * 4.4) * 0.04, 1.0)
	title.pivot_offset = title.size * 0.5
	title.scale = Vector2.ONE * (1.0 + sin(time_alive * 1.8) * 0.018)

	for index in range(menu_buttons.size()):
		var button := menu_buttons[index]
		var option_image := menu_option_images[index]
		var hovered := button.is_hovered()
		var idle_scale := 1.0 + sin(time_alive * 1.8 + float(index) * 0.4) * 0.012
		var target_scale := Vector2.ONE * (1.08 if hovered else idle_scale)
		var warm_color := 0.73 + sin(time_alive * 3.1 + float(index) * 0.35) * 0.03

		button.modulate = Color(1, 1, 1, 0.0)
		option_image.pivot_offset = option_image.size * 0.5
		option_image.scale = option_image.scale.lerp(target_scale, delta * 8.0)
		option_image.modulate = Color(1.0, 1.0 if hovered else 0.96, 0.82 if hovered else warm_color, 1.0)


func _apply_responsive_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var scale_factor: float = clamp(min(viewport_size.x / 1600.0, viewport_size.y / 900.0), 0.55, 1.25)
	var menu_width: float = viewport_size.x * 0.86
	var options_width: float = min(viewport_size.x * 0.3, 420.0 * scale_factor)
	var options_height: float = options_width * 1.15
	var background_texture_size := Vector2(320.0, 240.0)
	var texture_aspect: float = background_texture_size.x / background_texture_size.y
	var viewport_aspect: float = viewport_size.x / viewport_size.y
	var background_repeat := Vector2(1.0, 1.0)

	if viewport_aspect >= texture_aspect:
		background_repeat.x = viewport_aspect / texture_aspect
	else:
		background_repeat.y = texture_aspect / viewport_aspect

	for layer in background_layers:
		layer.position = Vector2.ZERO
		layer.size = viewport_size
		layer.stretch_mode = TextureRect.STRETCH_SCALE
		if layer.material is ShaderMaterial:
			layer.material.set_shader_parameter("repeat", background_repeat)

	menu.set_anchors_preset(Control.PRESET_TOP_LEFT)
	menu.position = Vector2((viewport_size.x - menu_width) * 0.5, viewport_size.y * 0.045)
	menu.size = Vector2(menu_width, viewport_size.y * 0.9)
	menu.add_theme_constant_override("separation", int(10.0 * scale_factor))

	var title_width: float = min(viewport_size.x * 0.74, 1120.0 * scale_factor)
	var title_height: float = title_width * 0.235
	title.custom_minimum_size = Vector2(title_width, title_height)
	title.size = Vector2(title_width, title_height)
	subtitle.custom_minimum_size = Vector2.ZERO
	subtitle.add_theme_font_size_override("font_size", int(18.0 * scale_factor))

	buttons.custom_minimum_size = Vector2(options_width, options_height)
	buttons.size = Vector2(options_width, options_height)
	var option_sizes := [
		Vector2(options_width * 0.96, options_height * 0.2),
		Vector2(options_width * 0.7, options_height * 0.2),
		Vector2(options_width * 0.72, options_height * 0.2),
		Vector2(options_width * 0.53, options_height * 0.24),
	]
	var option_positions := [
		Vector2(options_width * 0.02, options_height * 0.02),
		Vector2(options_width * 0.15, options_height * 0.27),
		Vector2(options_width * 0.14, options_height * 0.52),
		Vector2(options_width * 0.235, options_height * 0.75),
	]

	for index in range(menu_buttons.size()):
		var button := menu_buttons[index]
		var option_image := menu_option_images[index]
		option_image.position = option_positions[index]
		option_image.size = option_sizes[index]
		button.position = option_positions[index]
		button.size = option_sizes[index]
		button.custom_minimum_size = Vector2.ZERO
		button.text = ""

func _on_music_finished() -> void:
	music.play()


func _on_new_game_pressed() -> void:
	pass


func _on_chapter_pressed() -> void:
	pass


func _on_credits_pressed() -> void:
	pass


func _on_exit_pressed() -> void:
	get_tree().quit()
