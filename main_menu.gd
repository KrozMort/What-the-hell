extends Node2D

@onready var music: AudioStreamPlayer = $AudioStreamPlayer
@onready var menu: VBoxContainer = $MainMenu/Root/Menu
@onready var title: TextureRect = $MainMenu/Root/Menu/Title
@onready var subtitle_scroll: ScrollContainer = $MainMenu/Root/Menu/SubtitleScroll
@onready var subtitle: Label = $MainMenu/Root/Menu/SubtitleScroll/Subtitle
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
var time_alive: float = 0.0
var credits_transition_time: float = 0.0
var credits_visible: bool = false
var credits_close_button: Button = null
var subtitle_base_y: float = 0.0
var subtitle_offset: Vector2 = Vector2(72.0, 4.0)
var scale_factor: float = 1.0


func _ready() -> void:
	menu_buttons = [new_game_button, chapter_button, credits_button, exit_button]
	subtitle_scroll.visible = false
	subtitle.visible = false
	var existing_close_button: Node = get_node_or_null("MainMenu/Root/Menu/CreditsCloseButton")
	if existing_close_button is Button:
		credits_close_button = existing_close_button as Button
	else:
		credits_close_button = Button.new()
		credits_close_button.name = "CreditsCloseButton"
		credits_close_button.text = "Volver"
		credits_close_button.visible = false
		credits_close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		credits_close_button.custom_minimum_size = Vector2(140.0, 44.0)
		credits_close_button.size = Vector2(140.0, 44.0)
		credits_close_button.flat = false
		credits_close_button.focus_mode = Control.FOCUS_NONE
		credits_close_button.add_theme_color_override("font_color", Color(0.95, 0.78, 0.15, 1.0))
		credits_close_button.add_theme_font_size_override("font_size", 22)
		menu.add_child(credits_close_button)
	credits_close_button.pressed.connect(_on_credits_close_pressed)
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

	if credits_visible:
		credits_transition_time += delta
		var t: float = clamp(credits_transition_time / 0.45, 0.0, 1.0)
		var eased_t: float = t * t * (3.0 - 2.0 * t)
		subtitle.modulate = Color(1.0, 0.9, 0.3, lerp(0.0, 1.0, eased_t))
		subtitle.scale = Vector2.ONE * lerp(0.8, 1.02, eased_t)
		# Animate using menu-local coordinates and subtitle_offset
		var target_x: float = (menu.size.x - subtitle_scroll.size.x) * 0.5 + subtitle_offset.x * self.scale_factor
		var start_y: float = subtitle_base_y + 24.0
		subtitle_scroll.position = Vector2(target_x, lerp(start_y * (1.0 - eased_t) + subtitle_base_y * eased_t, subtitle_base_y, eased_t))
		buttons.visible = false
		credits_close_button.visible = true
	else:
		credits_transition_time = 0.0
		subtitle_scroll.visible = false
		subtitle.visible = false
		subtitle.position = Vector2.ZERO
		subtitle.scale = Vector2.ONE
		subtitle.modulate = Color(1.0, 0.9, 0.3, 0.0)
		buttons.visible = true
		credits_close_button.visible = false


func _apply_responsive_layout() -> void:
	var viewport_size := get_viewport_rect().size
	# update class-level scale factor for use in animations
	self.scale_factor = clamp(min(viewport_size.x / 1600.0, viewport_size.y / 900.0), 0.55, 1.25)
	var menu_width: float = viewport_size.x * 0.86
	var options_width: float = min(viewport_size.x * 0.3, 420.0 * self.scale_factor)
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
	menu.size = Vector2(menu_width, min(viewport_size.y * 0.85, 900.0 * self.scale_factor))

	# Center the menu container in the viewport
	menu.position = (viewport_size - menu.size) * 0.5
	menu.add_theme_constant_override("separation", int(10.0 * self.scale_factor))

	# Position the credits close button at the bottom of the screen, centered horizontally
	if credits_close_button:
		credits_close_button.custom_minimum_size = Vector2(140.0, 44.0)
		credits_close_button.size = credits_close_button.custom_minimum_size
		var button_x: float = (viewport_size.x - credits_close_button.size.x) * 0.5 - menu.position.x
		var button_y: float = viewport_size.y - credits_close_button.size.y - 4.0 * self.scale_factor - menu.position.y
		credits_close_button.position = Vector2(button_x, button_y)

	var title_width: float = min(viewport_size.x * 0.60, 1120.0 * self.scale_factor) * 0.92
	var title_height: float = title_width * 0.245
	title.custom_minimum_size = Vector2(title_width, title_height)
	title.size = Vector2(title_width, title_height)

	# Title: center inside menu
	title.position = Vector2((menu.size.x - title.size.x) * 0.5, 8.0 * self.scale_factor)

	# Subtitle sizing: width limited to viewport with paddings, font scales with scale_factor
	var subtitle_width: float = clamp(menu.size.x * 0.9, 280.0, menu.size.x - 40.0)
	var subtitle_font_size: int = int(clamp(20.0 * self.scale_factor, 10.0, 28.0))
	var subtitle_height: float = float(subtitle_font_size) * 16.0
	subtitle.custom_minimum_size = Vector2(subtitle_width, subtitle_height)
	subtitle.size = Vector2(subtitle_width, subtitle_height)
	subtitle_scroll.custom_minimum_size = Vector2(subtitle_width, clamp(menu.size.y * 0.38, 180.0, 300.0))
	subtitle_scroll.size = subtitle_scroll.custom_minimum_size
	# center the credits text inside the scroll container
	subtitle.pivot_offset = Vector2.ZERO
	subtitle.add_theme_font_size_override("font_size", subtitle_font_size)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Reduce subtitle text scale for better fit
	subtitle.scale = Vector2.ONE * 0.62
	# Place subtitle centered below the title with more rightward offset
	subtitle_base_y = title.position.y + title.size.y + subtitle_offset.y * self.scale_factor
	var pos_x: float = (menu.size.x - subtitle_scroll.size.x) * 0.5 + subtitle_offset.x * self.scale_factor
	var pos_y: float = max(subtitle_base_y, 8.0 * self.scale_factor)
	subtitle_scroll.position = Vector2(pos_x, pos_y)
	subtitle.position = Vector2((subtitle_scroll.size.x - subtitle.size.x) * 0.5, 0)

	# Position the buttons container below the subtitle container, centered
	buttons.position = Vector2((menu.size.x - buttons.size.x) * 0.5, subtitle_scroll.position.y + subtitle_scroll.size.y + 12.0 * self.scale_factor)

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
	subtitle.text = """WHAT THE HELL

Este proyecto se hizo realidad gracias al talento, la dedicación y el trabajo en equipo de sus integrantes:

- Adrián Moran
- Christopher Montoya
- Cristopher Prado
- Dylan Rojas
- Iker Quilumbaquin
- Johan Saico
- Kevin Bone
- Marlon Pijal
- Mateo Castro
- Steven Rodríguez

A cada uno de ustedes, nuestro más profundo agradecimiento por aportar su esfuerzo, creatividad y compromiso. Sin su colaboración, este proyecto no habría sido posible."""
	subtitle_scroll.visible = true
	subtitle.visible = true
	subtitle_scroll.scroll_vertical = 0
	subtitle.add_theme_color_override("font_color", Color(0.95, 0.78, 0.15, 1.0))
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_constant_override("line_spacing", 5)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# reduce overall label scale slightly for better fit on small screens
	subtitle.scale = Vector2.ONE * 0.64
	# keep left alignment for scrolling content
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	subtitle.modulate = Color(1.0, 0.9, 0.3, 0.0)
	credits_visible = true
	credits_transition_time = 0.0


func _on_credits_close_pressed() -> void:
	credits_visible = false
	credits_transition_time = 0.0


func _on_exit_pressed() -> void:
	get_tree().quit()
