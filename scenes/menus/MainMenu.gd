extends Control

@onready var btn_play: Button = $Margin/MenuVBox/ButtonsVBox/BtnPlay
@onready var btn_select_env: Button = $Margin/MenuVBox/ButtonsVBox/BtnSelectEnv
@onready var btn_quit: Button = $Margin/MenuVBox/ButtonsVBox/BtnQuit
@onready var lbl_title: Label = $Margin/MenuVBox/TitleSection/LblTitle
@onready var lbl_subtitle: Label = $Margin/MenuVBox/TitleSection/LblSubtitle

const GAMEPLAY_SCENE_PATH: String = "res://scenes/gameplay/MainGame.tscn"


func _ready() -> void:
	_setup_pro_menu_ui()

	btn_play.pressed.connect(_on_btn_play_pressed)
	btn_select_env.pressed.connect(_on_btn_select_env_pressed)
	btn_quit.pressed.connect(_on_btn_quit_pressed)
	
	_add_button_juice(btn_play)
	_add_button_juice(btn_select_env)
	_add_button_juice(btn_quit)
	
	_update_env_button_text()


func _setup_pro_menu_ui() -> void:
	lbl_title.add_theme_font_size_override("font_size", 72)
	lbl_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	lbl_title.add_theme_constant_override("shadow_offset_x", 4)
	lbl_title.add_theme_constant_override("shadow_offset_y", 6)
	
	lbl_subtitle.add_theme_font_size_override("font_size", 24)
	lbl_subtitle.add_theme_color_override("font_color", Color("#d5e1df"))

	_style_arcade_button(btn_play, Color("#10b981"), Color("#34d399"), Color("#059669"), 36)
	_style_glass_button(btn_select_env, 22)
	_style_ghost_button(btn_quit, 20)


func _style_arcade_button(btn: Button, base_color: Color, highlight: Color, pressed_color: Color, font_sz: int) -> void:
	btn.custom_minimum_size.y = 90
	btn.add_theme_font_size_override("font_size", font_sz)
	
	var norm := StyleBoxFlat.new()
	norm.bg_color = base_color
	norm.corner_radius_top_left = 45
	norm.corner_radius_top_right = 45
	norm.corner_radius_bottom_left = 45
	norm.corner_radius_bottom_right = 45
	norm.border_width_top = 4
	norm.border_width_left = 2
	norm.border_width_right = 2
	norm.border_color = highlight
	norm.shadow_color = Color(0, 0, 0, 0.4)
	norm.shadow_size = 14
	norm.shadow_offset = Vector2(0, 8)
	btn.add_theme_stylebox_override("normal", norm)

	var hov := norm.duplicate()
	hov.bg_color = base_color.lightened(0.12)
	hov.shadow_size = 18
	btn.add_theme_stylebox_override("hover", hov)

	var pres := norm.duplicate()
	pres.bg_color = pressed_color
	pres.shadow_offset = Vector2(0, 3)
	pres.shadow_size = 6
	btn.add_theme_stylebox_override("pressed", pres)


func _style_glass_button(btn: Button, font_sz: int) -> void:
	btn.custom_minimum_size.y = 75
	btn.add_theme_font_size_override("font_size", font_sz)
	
	var norm := StyleBoxFlat.new()
	norm.bg_color = Color(0.12, 0.16, 0.22, 0.75)
	norm.corner_radius_top_left = 24
	norm.corner_radius_top_right = 24
	norm.corner_radius_bottom_left = 24
	norm.corner_radius_bottom_right = 24
	norm.border_width_left = 2
	norm.border_width_top = 2
	norm.border_width_right = 2
	norm.border_width_bottom = 2
	norm.border_color = Color(1.0, 1.0, 1.0, 0.22)
	norm.shadow_color = Color(0, 0, 0, 0.35)
	norm.shadow_size = 8
	btn.add_theme_stylebox_override("normal", norm)

	var hov := norm.duplicate()
	hov.bg_color = Color(0.18, 0.24, 0.32, 0.85)
	hov.border_color = Color(1.0, 1.0, 1.0, 0.45)
	btn.add_theme_stylebox_override("hover", hov)

	var pres := norm.duplicate()
	pres.bg_color = Color(0.08, 0.10, 0.15, 0.9)
	btn.add_theme_stylebox_override("pressed", pres)


func _style_ghost_button(btn: Button, font_sz: int) -> void:
	btn.custom_minimum_size.y = 65
	btn.add_theme_font_size_override("font_size", font_sz)
	
	var norm := StyleBoxFlat.new()
	norm.bg_color = Color(0.1, 0.1, 0.14, 0.5)
	norm.corner_radius_top_left = 20
	norm.corner_radius_top_right = 20
	norm.corner_radius_bottom_left = 20
	norm.corner_radius_bottom_right = 20
	norm.border_width_bottom = 2
	norm.border_color = Color(1.0, 1.0, 1.0, 0.15)
	btn.add_theme_stylebox_override("normal", norm)

	var hov := norm.duplicate()
	hov.bg_color = Color(0.2, 0.2, 0.28, 0.65)
	btn.add_theme_stylebox_override("hover", hov)


func _add_button_juice(btn: Button) -> void:
	btn.pivot_offset = Vector2(btn.custom_minimum_size.x / 2.0, btn.custom_minimum_size.y / 2.0)
	btn.button_down.connect(func():
		var tw := create_tween()
		tw.tween_property(btn, "scale", Vector2(0.96, 0.96), 0.08)
	)
	btn.button_up.connect(func():
		var tw := create_tween()
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)


func _on_btn_play_pressed() -> void:
	GameManager.reset_game_session()
	get_tree().change_scene_to_file(GAMEPLAY_SCENE_PATH)


func _on_btn_select_env_pressed() -> void:
	if GameManager.current_environment == GameManager.GameEnvironment.LOGIC_ACADEMY:
		if GameManager.is_environment_unlocked(GameManager.GameEnvironment.CYBER_CASINO):
			GameManager.set_environment(GameManager.GameEnvironment.CYBER_CASINO)
		else:
			# Efecto de sacudida si está bloqueado
			var tw := create_tween()
			tw.tween_property(btn_select_env, "position:x", btn_select_env.position.x + 6, 0.04)
			tw.tween_property(btn_select_env, "position:x", btn_select_env.position.x - 6, 0.04)
			tw.tween_property(btn_select_env, "position:x", btn_select_env.position.x, 0.04)
	else:
		GameManager.set_environment(GameManager.GameEnvironment.LOGIC_ACADEMY)
	
	_update_env_button_text()


func _update_env_button_text() -> void:
	var brick_unlocked := GameManager.is_environment_unlocked(GameManager.GameEnvironment.CYBER_CASINO)
	
	if GameManager.current_environment == GameManager.GameEnvironment.LOGIC_ACADEMY:
		if brick_unlocked:
			btn_select_env.text = "AMBIENTE: RESORT COSTERO"
		else:
			btn_select_env.text = "RESORT (🔒 VILLA: %d/%d ⭐)" % [GameManager.stars, GameManager.BRICK_TOWN_STAR_REQUIREMENT]
		btn_play.modulate = Color("#e5c158")
	else:
		btn_select_env.text = "AMBIENTE: VILLA DE BLOQUES"
		btn_play.modulate = Color("#ff9900")


func _on_btn_quit_pressed() -> void:
	get_tree().quit()
