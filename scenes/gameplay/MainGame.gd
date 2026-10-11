extends Control

const DRAW_INTERVAL: float = 7.0
var draw_timer: float = 3.0
var is_auto_running: bool = true

const MAIN_MENU_PATH: String = "res://scenes/menus/MainMenu.tscn"

# Referencias UI resueltas dinámicamente
var background: TextureRect
var blur_overlay: ColorRect

var hud: Control
var btn_back_menu: Button
var lbl_lives: Label
var lbl_coins: Label
var lbl_stars: Label

var tombola_section: PanelContainer
var ball_circle: PanelContainer
var lbl_ball_letter: Label
var lbl_ball_number: Label
var recent_balls_rack: HBoxContainer
var btn_draw_ball: Button

var card_grid: GridContainer
var btn_bingo: Button
var btn_change_env: Button

var trivia_modal: Control
var end_game_modal: Control
var sfx_player: AudioStreamPlayer

# Efectos de audio cargados de forma segura
var sfx_trivia_correct: AudioStream
var sfx_trivia_wrong: AudioStream
var sfx_ball_draw: AudioStream
var sfx_pencil: AudioStream

var tombola: BingoTombola
var card: BingoCard
var trivia_manager: TriviaManager

var cell_buttons: Array = []
var recent_balls: Array[int] = []


func _ready() -> void:
	tombola = BingoTombola.new()
	card = BingoCard.new()
	trivia_manager = TriviaManager.new()

	_bind_ui_nodes()
	_load_all_audio_safely()

	# Conexiones con GameManager
	GameManager.lives_changed.connect(_update_hud)
	GameManager.coins_changed.connect(_update_hud)
	GameManager.stars_changed.connect(_update_hud)
	GameManager.game_over.connect(_on_game_over)
	GameManager.game_revived.connect(_on_game_revived)
	GameManager.environment_changed.connect(_on_environment_changed)

	# Conexiones de botones seguras
	if btn_draw_ball:
		btn_draw_ball.pressed.connect(_on_toggle_auto_draw_pressed)
	if btn_bingo:
		btn_bingo.pressed.connect(_on_btn_bingo_pressed)
	if btn_change_env:
		btn_change_env.pressed.connect(_on_btn_change_env_pressed)
	if btn_back_menu:
		btn_back_menu.pressed.connect(_on_btn_back_menu_pressed)
	if trivia_modal:
		trivia_modal.trivia_answered.connect(_on_trivia_answered)

	_setup_pro_styles()
	_build_visual_grid()
	_apply_environment(GameManager.current_environment)
	_update_hud()


## Localiza los nodos en cualquier lugar del árbol sin depender de rutas rígidas
func _bind_ui_nodes() -> void:
	background = find_child("Background", true, false) as TextureRect
	blur_overlay = find_child("BlurOverlay", true, false) as ColorRect
	hud = find_child("HUD", true, false) as Control

	btn_back_menu = find_child("BtnBackMenu", true, false) as Button
	lbl_lives = find_child("LblLives", true, false) as Label
	lbl_coins = find_child("LblCoins", true, false) as Label
	lbl_stars = find_child("LblStars", true, false) as Label

	tombola_section = find_child("TombolaSection", true, false) as PanelContainer
	ball_circle = find_child("BallCircle", true, false) as PanelContainer
	lbl_ball_letter = find_child("LblBallLetter", true, false) as Label
	lbl_ball_number = find_child("LblBallNumber", true, false) as Label
	recent_balls_rack = find_child("RecentBallsRack", true, false) as HBoxContainer
	btn_draw_ball = find_child("BtnDrawBall", true, false) as Button

	card_grid = find_child("CardGrid", true, false) as GridContainer
	btn_bingo = find_child("BtnBingo", true, false) as Button
	btn_change_env = find_child("BtnChangeEnv", true, false) as Button

	trivia_modal = find_child("TriviaModal", true, false) as Control
	end_game_modal = find_child("EndGameModal", true, false) as Control
	sfx_player = find_child("SFXPlayer", true, false) as AudioStreamPlayer


func _load_all_audio_safely() -> void:
	sfx_trivia_correct = _find_audio([
		"res://assets/audio/liecio-collect-points-190037.mp3",
		"res://assets/audio/trivia_correct.mp3",
		"res://assets/audio/trivia_correct.wav"
	])
	sfx_trivia_wrong = _find_audio([
		"res://assets/audio/trivia_wrong.mp3",
		"res://assets/audio/u_31vnwfmzt6-error-126627.mp3"
	])
	sfx_ball_draw = _find_audio([
		"res://assets/audio/ball_draw.mp3",
		"res://assets/audio/soundreality-bell-sound-effect-613873.mp3"
	])
	sfx_pencil = _find_audio([
		"res://assets/audio/pencil_mark.mp3",
		"res://assets/audio/u_xg7ssi08yr-writing-with-pencil-371358.mp3"
	])


func _find_audio(possible_paths: Array[String]) -> AudioStream:
	for p in possible_paths:
		if ResourceLoader.exists(p):
			return load(p) as AudioStream
	return null


func _process(delta: float) -> void:
	if not is_auto_running:
		return
	
	draw_timer -= delta
	if btn_draw_ball:
		btn_draw_ball.text = "PAUSAR TÓMBOLA  (%.1fs)" % max(draw_timer, 0.0)

	if draw_timer <= 0.0:
		draw_timer = DRAW_INTERVAL
		_draw_next_ball()


func _on_toggle_auto_draw_pressed() -> void:
	is_auto_running = not is_auto_running
	if not btn_draw_ball:
		return

	if not is_auto_running:
		btn_draw_ball.text = "REANUDAR TÓMBOLA"
		btn_draw_ball.modulate = Color("#f39c12")
	else:
		btn_draw_ball.modulate = Color("#ffffff")


func _draw_next_ball() -> void:
	var ball: int = tombola.draw_next_ball()
	if ball == -1:
		if lbl_ball_number:
			lbl_ball_number.text = "FIN"
		is_auto_running = false
		if btn_draw_ball:
			btn_draw_ball.disabled = true
			btn_draw_ball.text = "TÓMBOLA VACÍA"
		if end_game_modal:
			end_game_modal.show_game_over(false, "Se agotaron todas las balotas disponibles.")
		return

	if sfx_player:
		if sfx_ball_draw:
			sfx_player.volume_db = 0.0
			sfx_player.stream = sfx_ball_draw
			sfx_player.play()
		else:
			_play_tone(440.0, 0.08)

	var info: Dictionary = _get_ball_info(ball)
	if lbl_ball_letter:
		lbl_ball_letter.text = info["letter"]
	if lbl_ball_number:
		lbl_ball_number.text = "%02d" % ball
	if ball_circle:
		_style_ball(ball_circle, info["color"], info["border"])
		var tween := create_tween()
		ball_circle.scale = Vector2(0.4, 0.4)
		tween.tween_property(ball_circle, "scale", Vector2(1.18, 1.18), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(ball_circle, "scale", Vector2(1.0, 1.0), 0.12)

	recent_balls.push_front(ball)
	if recent_balls.size() > 5:
		recent_balls.pop_back()
	_update_recent_balls_rack()

	if randf() <= 0.20:
		is_auto_running = false
		if btn_draw_ball:
			btn_draw_ball.text = "¡TRIVIA EN CURSO!"
		_trigger_trivia()


func _trigger_trivia() -> void:
	var question_data: Dictionary = trivia_manager.get_random_question()
	if not question_data.is_empty() and trivia_modal:
		trivia_modal.open_trivia(question_data)


func _on_trivia_answered(success: bool) -> void:
	is_auto_running = true
	draw_timer = DRAW_INTERVAL
	if btn_draw_ball:
		btn_draw_ball.modulate = Color("#ffffff")
	
	if success:
		if sfx_player:
			if sfx_trivia_correct:
				sfx_player.volume_db = 0.0
				sfx_player.stream = sfx_trivia_correct
				sfx_player.play()
			else:
				_play_tone(880.0, 0.15)
		if lbl_ball_letter:
			lbl_ball_letter.text = "¡BONUS!"
	else:
		if sfx_player:
			if sfx_trivia_wrong:
				sfx_player.volume_db = 5.0
				sfx_player.stream = sfx_trivia_wrong
				sfx_player.play()
			else:
				_play_tone(200.0, 0.25)


func _play_pencil_sfx() -> void:
	if not sfx_pencil:
		_play_tone(660.0, 0.12)
		return

	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = sfx_pencil
	player.volume_db = 0.0
	var start_pos: float = randf_range(0.0, 18.0)
	player.play(start_pos)
	
	var tw := create_tween()
	tw.tween_interval(1.7)
	tw.tween_property(player, "volume_db", -40.0, 0.3)
	tw.tween_callback(player.queue_free)


func _on_btn_back_menu_pressed() -> void:
	is_auto_running = false
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func _on_btn_change_env_pressed() -> void:
	if GameManager.current_environment == GameManager.GameEnvironment.LOGIC_ACADEMY:
		if GameManager.is_environment_unlocked(GameManager.GameEnvironment.CYBER_CASINO):
			GameManager.set_environment(GameManager.GameEnvironment.CYBER_CASINO)
		else:
			_play_tone(220.0, 0.15)
			if btn_change_env:
				var tw := create_tween()
				tw.tween_property(btn_change_env, "position:x", btn_change_env.position.x + 6, 0.04)
				tw.tween_property(btn_change_env, "position:x", btn_change_env.position.x - 6, 0.04)
				tw.tween_property(btn_change_env, "position:x", btn_change_env.position.x, 0.04)
	else:
		GameManager.set_environment(GameManager.GameEnvironment.LOGIC_ACADEMY)


func _on_environment_changed(_env_name: String) -> void:
	_apply_environment(GameManager.current_environment)


func _apply_environment(env: GameManager.GameEnvironment) -> void:
	if env == GameManager.GameEnvironment.LOGIC_ACADEMY:
		if background:
			background.texture = load("res://assets/sprites/env_resort.jpeg")
		if blur_overlay and blur_overlay.material:
			blur_overlay.material.set_shader_parameter("tint_color", Color(0.06, 0.14, 0.10, 0.72))
		if btn_bingo:
			btn_bingo.modulate = Color("#e5c158")
		if btn_change_env:
			btn_change_env.modulate = Color("#ffffff")
	elif env == GameManager.GameEnvironment.CYBER_CASINO:
		if background:
			background.texture = load("res://assets/sprites/env_brick_town.png")
		if blur_overlay and blur_overlay.material:
			blur_overlay.material.set_shader_parameter("tint_color", Color(0.12, 0.08, 0.04, 0.72))
		if btn_bingo:
			btn_bingo.modulate = Color("#ff9900")
		if btn_change_env:
			btn_change_env.modulate = Color("#ffd166")


func _on_cell_pressed(row: int, col: int, btn: Button) -> void:
	var cell_number: int = card.grid[row][col]
	if tombola.has_been_drawn(cell_number):
		if card.mark_cell(row, col):
			_play_pencil_sfx()
			
			var tw := create_tween()
			tw.tween_property(btn, "scale", Vector2(1.15, 1.15), 0.1).set_trans(Tween.TRANS_BACK)
			tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)

			btn.disabled = true
			btn.text = "%d\n✔" % cell_number
			
			var marked_style := StyleBoxFlat.new()
			marked_style.bg_color = Color("#065f46")
			marked_style.corner_radius_top_left = 20
			marked_style.corner_radius_top_right = 20
			marked_style.corner_radius_bottom_left = 20
			marked_style.corner_radius_bottom_right = 20
			marked_style.border_width_top = 4
			marked_style.border_color = Color("#34d399")
			marked_style.shadow_color = Color(0, 0, 0, 0.4)
			marked_style.shadow_size = 8
			btn.add_theme_stylebox_override("disabled", marked_style)
			btn.add_theme_color_override("font_disabled_color", Color("#d1fae5"))

			GameManager.add_coins(10)
	else:
		_play_tone(220.0, 0.2)
		var tw := create_tween()
		tw.tween_property(btn, "position:x", btn.position.x + 8, 0.04)
		tw.tween_property(btn, "position:x", btn.position.x - 8, 0.04)
		tw.tween_property(btn, "position:x", btn.position.x, 0.04)
		GameManager.lose_life()


func _on_btn_bingo_pressed() -> void:
	var win_data: Dictionary = card.check_win_patterns()
	if win_data["has_won"]:
		is_auto_running = false
		GameManager.add_stars(5)
		GameManager.add_coins(200)
		if btn_bingo:
			btn_bingo.disabled = true
		if end_game_modal:
			end_game_modal.show_game_over(true, "¡Patrón completado: %s!" % win_data["pattern"])
	else:
		_play_tone(180.0, 0.3)
		GameManager.lose_life()


func _on_game_over() -> void:
	is_auto_running = false
	if end_game_modal:
		end_game_modal.show_game_over(false, "Te has quedado sin vidas.")


func _on_game_revived() -> void:
	is_auto_running = true
	draw_timer = 3.0
	_update_hud()


func _update_hud(_val: int = 0) -> void:
	if lbl_lives:
		lbl_lives.text = "❤  %d/%d" % [GameManager.lives, GameManager.MAX_LIVES]
	if lbl_coins:
		lbl_coins.text = "🪙  %d" % GameManager.coins
	if lbl_stars:
		lbl_stars.text = "⭐  %d" % GameManager.stars


func _setup_pro_styles() -> void:
	_style_hud_chip(lbl_lives)
	_style_hud_chip(lbl_coins)
	_style_hud_chip(lbl_stars)
	_style_hud_menu_button(btn_back_menu)

	if tombola_section:
		var panel_style := StyleBoxFlat.new()
		panel_style.bg_color = Color(0.08, 0.11, 0.16, 0.88)
		panel_style.corner_radius_top_left = 28
		panel_style.corner_radius_top_right = 28
		panel_style.corner_radius_bottom_left = 28
		panel_style.corner_radius_bottom_right = 28
		panel_style.border_width_left = 2
		panel_style.border_width_top = 2
		panel_style.border_width_right = 2
		panel_style.border_width_bottom = 2
		panel_style.border_color = Color(1.0, 1.0, 1.0, 0.18)
		panel_style.shadow_color = Color(0, 0, 0, 0.5)
		panel_style.shadow_size = 18
		panel_style.shadow_offset = Vector2(0, 8)
		tombola_section.add_theme_stylebox_override("panel", panel_style)

	if ball_circle:
		ball_circle.custom_minimum_size = Vector2(180, 180)
		ball_circle.pivot_offset = Vector2(90, 90)
		_style_ball(ball_circle, Color("#2b3340"), Color("#475569"))

	if lbl_ball_letter:
		lbl_ball_letter.text = "BINGO"
		lbl_ball_letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_ball_letter.add_theme_font_size_override("font_size", 22)

	if lbl_ball_number:
		lbl_ball_number.text = "--"
		lbl_ball_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_ball_number.add_theme_font_size_override("font_size", 66)

	if btn_draw_ball:
		var btn_draw_style := StyleBoxFlat.new()
		btn_draw_style.bg_color = Color("#10b981")
		btn_draw_style.corner_radius_top_left = 38
		btn_draw_style.corner_radius_top_right = 38
		btn_draw_style.corner_radius_bottom_left = 38
		btn_draw_style.corner_radius_bottom_right = 38
		btn_draw_style.border_width_top = 4
		btn_draw_style.border_color = Color("#6ee7b7")
		btn_draw_style.shadow_color = Color(0, 0, 0, 0.35)
		btn_draw_style.shadow_size = 8
		btn_draw_style.shadow_offset = Vector2(0, 5)
		btn_draw_ball.add_theme_stylebox_override("normal", btn_draw_style)
		btn_draw_ball.add_theme_font_size_override("font_size", 24)
		btn_draw_ball.custom_minimum_size = Vector2(0, 76)

	_style_pill_button(btn_bingo, Color("#e11d48"), Color("#fb7185"), 28)
	_style_pill_button(btn_change_env, Color("#1e293b"), Color("#475569"), 22)

	if recent_balls_rack:
		recent_balls_rack.alignment = BoxContainer.ALIGNMENT_CENTER


func _style_hud_menu_button(btn: Button) -> void:
	if not btn:
		return
	btn.add_theme_font_size_override("font_size", 20)
	var norm := StyleBoxFlat.new()
	norm.bg_color = Color(0.12, 0.16, 0.24, 0.9)
	norm.corner_radius_top_left = 20
	norm.corner_radius_top_right = 20
	norm.corner_radius_bottom_left = 20
	norm.corner_radius_bottom_right = 20
	norm.border_width_left = 2
	norm.border_width_top = 2
	norm.border_width_right = 2
	norm.border_width_bottom = 2
	norm.border_color = Color(1.0, 1.0, 1.0, 0.3)
	norm.content_margin_left = 20
	norm.content_margin_right = 20
	norm.content_margin_top = 8
	norm.content_margin_bottom = 8
	norm.shadow_color = Color(0, 0, 0, 0.4)
	norm.shadow_size = 6
	btn.add_theme_stylebox_override("normal", norm)

	var hov := norm.duplicate()
	hov.bg_color = Color(0.20, 0.26, 0.38, 0.95)
	hov.border_color = Color(1.0, 1.0, 1.0, 0.6)
	btn.add_theme_stylebox_override("hover", hov)

	var pres := norm.duplicate()
	pres.bg_color = Color(0.08, 0.10, 0.15, 1.0)
	btn.add_theme_stylebox_override("pressed", pres)

	btn.pivot_offset = Vector2(50, 20)
	btn.button_down.connect(func():
		var tw := create_tween()
		tw.tween_property(btn, "scale", Vector2(0.94, 0.94), 0.06)
	)
	btn.button_up.connect(func():
		var tw := create_tween()
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
	)


func _style_hud_chip(lbl: Label) -> void:
	if not lbl:
		return
	var chip := StyleBoxFlat.new()
	chip.bg_color = Color(0.06, 0.08, 0.12, 0.85)
	chip.corner_radius_top_left = 20
	chip.corner_radius_top_right = 20
	chip.corner_radius_bottom_left = 20
	chip.corner_radius_bottom_right = 20
	chip.border_width_left = 2
	chip.border_width_top = 2
	chip.border_width_right = 2
	chip.border_width_bottom = 2
	chip.border_color = Color(1.0, 1.0, 1.0, 0.22)
	chip.content_margin_left = 18
	chip.content_margin_right = 18
	chip.content_margin_top = 8
	chip.content_margin_bottom = 8
	chip.shadow_color = Color(0, 0, 0, 0.4)
	chip.shadow_size = 6
	lbl.add_theme_stylebox_override("normal", chip)
	lbl.add_theme_font_size_override("font_size", 22)


func _style_pill_button(btn: Button, fill: Color, border: Color, font_sz: int) -> void:
	if not btn:
		return
	btn.custom_minimum_size.y = 80
	btn.add_theme_font_size_override("font_size", font_sz)
	
	var norm := StyleBoxFlat.new()
	norm.bg_color = fill
	norm.corner_radius_top_left = 40
	norm.corner_radius_top_right = 40
	norm.corner_radius_bottom_left = 40
	norm.corner_radius_bottom_right = 40
	norm.border_width_top = 3
	norm.border_color = border
	norm.shadow_color = Color(0, 0, 0, 0.4)
	norm.shadow_size = 8
	norm.shadow_offset = Vector2(0, 4)
	btn.add_theme_stylebox_override("normal", norm)

	var pres := norm.duplicate()
	pres.bg_color = fill.darkened(0.2)
	pres.shadow_offset = Vector2(0, 1)
	btn.add_theme_stylebox_override("pressed", pres)


func _style_ball(panel: PanelContainer, fill_color: Color, border_color: Color) -> void:
	if not panel:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_width_left = 6
	style.border_width_top = 6
	style.border_width_right = 6
	style.border_width_bottom = 6
	style.border_color = border_color
	style.corner_radius_top_left = 100
	style.corner_radius_top_right = 100
	style.corner_radius_bottom_left = 100
	style.corner_radius_bottom_right = 100
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0, 6)
	panel.add_theme_stylebox_override("panel", style)


func _get_ball_info(num: int) -> Dictionary:
	if num <= 15:
		return {"letter": "B", "color": Color("#1d4ed8"), "border": Color("#60a5fa")}
	elif num <= 30:
		return {"letter": "I", "color": Color("#b91c1c"), "border": Color("#f87171")}
	elif num <= 45:
		return {"letter": "N", "color": Color("#c2410c"), "border": Color("#fb923c")}
	elif num <= 60:
		return {"letter": "G", "color": Color("#15803d"), "border": Color("#4ade80")}
	else:
		return {"letter": "O", "color": Color("#7e22ce"), "border": Color("#c084fc")}


func _update_recent_balls_rack() -> void:
	if not recent_balls_rack:
		return
	for c in recent_balls_rack.get_children():
		c.queue_free()

	for i in range(1, recent_balls.size()):
		var past_ball: int = recent_balls[i]
		var info: Dictionary = _get_ball_info(past_ball)

		var mini_ball := PanelContainer.new()
		mini_ball.custom_minimum_size = Vector2(52, 52)
		_style_ball(mini_ball, info["color"], info["border"])

		var lbl := Label.new()
		lbl.text = str(past_ball)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 18)

		mini_ball.add_child(lbl)
		recent_balls_rack.add_child(mini_ball)


func _build_visual_grid() -> void:
	if not card_grid:
		return
	for child in card_grid.get_children():
		child.queue_free()
	cell_buttons.clear()

	var letters: Array[String] = ["B", "I", "N", "G", "O"]
	var header_colors: Array[Color] = [
		Color("#1d4ed8"), Color("#b91c1c"), Color("#c2410c"), Color("#15803d"), Color("#7e22ce")
	]
	
	for i in range(5):
		var header_chip := PanelContainer.new()
		header_chip.custom_minimum_size = Vector2(170, 60)
		
		var chip_style := StyleBoxFlat.new()
		chip_style.bg_color = header_colors[i]
		chip_style.corner_radius_top_left = 16
		chip_style.corner_radius_top_right = 16
		chip_style.corner_radius_bottom_left = 8
		chip_style.corner_radius_bottom_right = 8
		chip_style.border_width_top = 3
		chip_style.border_color = header_colors[i].lightened(0.35)
		header_chip.add_theme_stylebox_override("panel", chip_style)

		var lbl := Label.new()
		lbl.text = letters[i]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 34)
		header_chip.add_child(lbl)
		card_grid.add_child(header_chip)

	for r in range(5):
		var row_btns: Array[Button] = []
		for c in range(5):
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(170, 170)
			btn.pivot_offset = Vector2(85, 85)
			btn.add_theme_font_size_override("font_size", 36)

			var num: int = card.grid[r][c]
			if r == 2 and c == 2:
				btn.text = "★\nLIBRE"
				btn.disabled = true
				_style_gold_free_tile(btn)
			else:
				btn.text = str(num)
				_style_normal_tile(btn)
				btn.pressed.connect(func(): _on_cell_pressed(r, c, btn))

			card_grid.add_child(btn)
			row_btns.append(btn)
		cell_buttons.append(row_btns)


func _style_normal_tile(btn: Button) -> void:
	var norm := StyleBoxFlat.new()
	norm.bg_color = Color(0.10, 0.14, 0.20, 0.88)
	norm.corner_radius_top_left = 20
	norm.corner_radius_top_right = 20
	norm.corner_radius_bottom_left = 20
	norm.corner_radius_bottom_right = 20
	norm.border_width_top = 3
	norm.border_width_left = 1
	norm.border_width_right = 1
	norm.border_width_bottom = 3
	norm.border_color = Color(1.0, 1.0, 1.0, 0.16)
	norm.shadow_color = Color(0, 0, 0, 0.45)
	norm.shadow_size = 8
	norm.shadow_offset = Vector2(0, 4)
	btn.add_theme_stylebox_override("normal", norm)

	var hov := norm.duplicate()
	hov.bg_color = Color(0.16, 0.22, 0.32, 0.95)
	hov.border_color = Color(1.0, 1.0, 1.0, 0.35)
	btn.add_theme_stylebox_override("hover", hov)

	var pres := norm.duplicate()
	pres.bg_color = Color(0.06, 0.08, 0.12, 1.0)
	pres.shadow_offset = Vector2(0, 1)
	btn.add_theme_stylebox_override("pressed", pres)


func _style_gold_free_tile(btn: Button) -> void:
	var gold := StyleBoxFlat.new()
	gold.bg_color = Color("#b45309")
	gold.corner_radius_top_left = 20
	gold.corner_radius_top_right = 20
	gold.corner_radius_bottom_left = 20
	gold.corner_radius_bottom_right = 20
	gold.border_width_top = 4
	gold.border_color = Color("#fcd34d")
	gold.shadow_color = Color(0, 0, 0, 0.45)
	gold.shadow_size = 10
	gold.shadow_offset = Vector2(0, 4)
	btn.add_theme_stylebox_override("disabled", gold)
	btn.add_theme_color_override("font_disabled_color", Color("#fef3c7"))


func _play_tone(freq: float, duration: float) -> void:
	var sample_hz: float = 22050.0
	var total_samples: int = int(sample_hz * duration)
	var pcm := PackedByteArray()
	pcm.resize(total_samples)

	for i in range(total_samples):
		var phase: float = (float(i) / sample_hz) * freq * TAU
		var sample_val: int = int(sin(phase) * 60.0 + 128.0)
		pcm.set(i, sample_val)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = int(sample_hz)
	stream.data = pcm
	if sfx_player:
		sfx_player.stream = stream
		sfx_player.play()
