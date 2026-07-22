extends Node2D

const PLAYER_SPRITE_DIR := "res://assets/characters/player/main/spritesheets/"
const FRAME_WIDTH := 60
const FRAME_HEIGHT := 80
const NEXT_SCENE := "res://scenes/levels/level_01.tscn"

const FINAL_DIR := "res://Final/"
const FOREGROUND_TEXTURE_WIDTH := 352.0
const FOREGROUND_SCALE := 0.72
const FOREGROUND_Y := 800.0
const FOREGROUND_TILE_COUNT := 16
const FOREGROUND_START_X := -800.0

const PLAYER_START := Vector2(320, 640)
const STATUE_POS := Vector2(760, 560)
const GATE_POS := Vector2(1380, 610)
const CAMERA_WAKE_POS := Vector2(320, 480)
const TOUR_POINTS := [Vector2(520, 620), Vector2(320, 540), STATUE_POS]

@onready var graveyard: Sprite2D = $Parallax/GraveyardLayer/Graveyard
@onready var foreground_layer: Node2D = $Parallax/ForegroundLayer/Foreground
@onready var statue: Sprite2D = $World/Statue
@onready var gate: Sprite2D = $World/GateFence
@onready var hole: Sprite2D = $World/Hole
@onready var glow: Sprite2D = $World/Glow
@onready var player: AnimatedSprite2D = $World/Player
@onready var camera: Camera2D = $Camera2D
@onready var ambience: AudioStreamPlayer = $Ambience
@onready var bell: AudioStreamPlayer = $Bell
@onready var breath: AudioStreamPlayer = $Breath
@onready var footsteps: AudioStreamPlayer = $Footsteps
@onready var pad: AudioStreamPlayer = $Pad
@onready var fade: ColorRect = $UI/Fade
@onready var subtitle: Label = $UI/Subtitle
@onready var skip_hint: Label = $UI/SkipHint

var _finished := false


func _ready() -> void:
	print("[INTRO] _ready() arrancó")
	fade.color.a = 1.0
	subtitle.text = ""
	subtitle.modulate.a = 0.0
	skip_hint.text = "Enter para omitir"
	graveyard.modulate.a = 0.0
	glow.modulate.a = 0.0
	player.visible = false
	_apply_font_fallback()
	_build_player_animations()
	_build_foreground()
	if ambience.stream:
		ambience.stream.loop = true
		ambience.play()
	if bell.stream:
		bell.stream.loop = true
		bell.play()
	_run_timeline()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		_finish_intro()


func _apply_font_fallback() -> void:
	for label in [subtitle, skip_hint]:
		var base_font: Font = label.get_theme_font("font")
		if base_font is FontVariation:
			continue
		var variation := FontVariation.new()
		variation.base_font = base_font
		variation.fallbacks = [ThemeDB.fallback_font]
		label.add_theme_font_override("font", variation)


func _build_player_animations() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	SpritesheetFrames.add_animation(frames, "hurt", load(PLAYER_SPRITE_DIR + "player_hurt.png"), FRAME_WIDTH, FRAME_HEIGHT, 6.0, false)
	SpritesheetFrames.add_animation(frames, "idle", load(PLAYER_SPRITE_DIR + "player_idle.png"), FRAME_WIDTH, FRAME_HEIGHT, 8.0, true)
	SpritesheetFrames.add_animation(frames, "run", load(PLAYER_SPRITE_DIR + "player_run.png"), FRAME_WIDTH, FRAME_HEIGHT, 14.0, true)
	player.sprite_frames = frames


func _build_foreground() -> void:
	var plain := load(FINAL_DIR + "Grass_background_1.png")
	var tree := load(FINAL_DIR + "Grass_background_2.png")
	var tile_step := FOREGROUND_TEXTURE_WIDTH * FOREGROUND_SCALE
	var tree_index := int(round((PLAYER_START.x - FOREGROUND_START_X) / tile_step))
	for i in range(FOREGROUND_TILE_COUNT):
		var tile := Sprite2D.new()
		tile.texture = tree if i == tree_index else plain
		tile.scale = Vector2(FOREGROUND_SCALE, FOREGROUND_SCALE)
		tile.position = Vector2(FOREGROUND_START_X + i * tile_step, FOREGROUND_Y)
		foreground_layer.add_child(tile)


func _run_timeline() -> void:
	await _scene_1_black_intro()
	if _finished:
		return
	await _scene_2_reveal_moon()
	if _finished:
		return
	await _scene_3_wake_up()
	if _finished:
		return
	await _scene_4_silent_tour()
	if _finished:
		return
	await _scene_5_walk_and_watch()
	if _finished:
		return
	await _scene_6_arrive_at_gate()
	if _finished:
		return
	await _scene_7_closing_text()
	if _finished:
		return
	_finish_intro()


func _scene_1_black_intro() -> void:
	print("[INTRO] escena 1 iniciada")
	await _show_subtitle("Hubo un tiempo en que la luz protegia estas tierras...", 3.0)
	if _finished:
		return
	await get_tree().create_timer(0.8).timeout
	if _finished:
		return
	await _show_subtitle("Hasta que una sombra la devoro por completo.", 3.0)


func _scene_2_reveal_moon() -> void:
	print("[INTRO] escena 2 iniciada")
	var fade_in := create_tween()
	fade_in.tween_property(fade, "color:a", 0.0, 2.0)
	await get_tree().create_timer(2.0).timeout
	if _finished:
		return
	print("[INTRO] escena 2 - fade_in listo")

	var reveal := create_tween()
	reveal.tween_property(graveyard, "modulate:a", 1.0, 6.0)
	reveal.parallel().tween_property(camera, "position", CAMERA_WAKE_POS, 6.0).set_trans(Tween.TRANS_SINE)

	await _show_subtitle("Los reinos cayeron uno tras otro.", 1.8)
	if _finished:
		return
	await _show_subtitle("Sus guardianes lucharon... y desaparecieron.", 1.8)
	if _finished:
		return
	await _show_subtitle("Solo quedaron ruinas... y silencio.", 2.2)
	if _finished:
		return
	bell.stop()
	print("[INTRO] escena 2 completada")


func _scene_3_wake_up() -> void:
	print("[INTRO] escena 3 iniciada - player.visible = true")
	player.visible = true
	player.play("hurt")
	player.frame = 0
	player.stop()
	if breath.stream:
		breath.play()
	var zoom_in := create_tween()
	zoom_in.tween_property(camera, "zoom", Vector2(1.05, 1.05), 3.0)
	await _show_subtitle("No recuerdas quien eres...", 2.2)
	if _finished:
		return
	player.play("idle")
	await _show_subtitle("Ni por que despertaste aqui.", 2.4)


func _scene_4_silent_tour() -> void:
	print("[INTRO] escena 4 iniciada")
	var lines := ["Muchos caminaron este sendero...", "Ninguno consiguio regresar."]
	for i in range(TOUR_POINTS.size()):
		var tour := create_tween()
		tour.tween_property(camera, "position", TOUR_POINTS[i], 2.2).set_trans(Tween.TRANS_SINE)
		await tour.finished
		if _finished:
			return
		if i < lines.size():
			await _show_subtitle(lines[i], 1.8)
		else:
			await get_tree().create_timer(1.4).timeout
		if _finished:
			return


func _scene_5_walk_and_watch() -> void:
	print("[INTRO] escena 5 iniciada")
	player.play("run")
	if footsteps.stream:
		footsteps.stream.loop = true
		footsteps.play()
	if pad.stream:
		pad.play()
	var walk := create_tween()
	walk.tween_property(player, "position:x", GATE_POS.x, 9.0).set_trans(Tween.TRANS_SINE)

	await _show_subtitle("Pero mientras una llama siga encendida...", 2.2)
	if _finished:
		return
	await _show_subtitle("...la oscuridad nunca habra vencido.", 2.6)
	if _finished:
		return

	var catch_up := create_tween()
	catch_up.tween_property(camera, "position", Vector2(GATE_POS.x, CAMERA_WAKE_POS.y), 3.5).set_trans(Tween.TRANS_SINE)
	catch_up.parallel().tween_property(camera, "zoom", Vector2(1.0, 1.0), 3.5)
	await get_tree().create_timer(3.5).timeout
	if _finished:
		return
	print("[INTRO] escena 5 completada")


func _scene_6_arrive_at_gate() -> void:
	print("[INTRO] escena 6 iniciada")
	player.play("idle")
	footsteps.stop()
	var glow_in := create_tween()
	glow_in.tween_property(glow, "modulate:a", 0.85, 2.5)
	if ambience.stream:
		glow_in.parallel().tween_property(ambience, "volume_db", -2.0, 2.5)
	await _show_subtitle("Si aun respiras...", 2.2)
	if _finished:
		return
	await _show_subtitle("...es porque el destino aun no ha terminado contigo.", 2.8)
	if _finished:
		return
	print("[INTRO] escena 6 completada")


func _scene_7_closing_text() -> void:
	print("[INTRO] escena 7 iniciada")
	await get_tree().create_timer(0.8).timeout
	if _finished:
		return
	await _show_subtitle("Levantate.", 1.8)
	if _finished:
		return
	await _show_subtitle("La ultima esperanza... camina contigo.", 3.0)


func _show_subtitle(text: String, duration: float) -> void:
	subtitle.text = text
	subtitle.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(subtitle, "modulate:a", 1.0, 0.6)
	tween.tween_interval(duration)
	tween.tween_property(subtitle, "modulate:a", 0.0, 0.6)
	await tween.finished


func _finish_intro() -> void:
	if _finished:
		return
	_finished = true
	for tween in get_tree().get_processed_tweens():
		tween.kill()
	var fade_out := create_tween()
	fade_out.tween_property(fade, "color:a", 1.0, 0.8)
	await get_tree().create_timer(0.8).timeout
	print("[INTRO] fade final listo -> cambiando a Nivel 1")
	get_tree().change_scene_to_file(NEXT_SCENE)
