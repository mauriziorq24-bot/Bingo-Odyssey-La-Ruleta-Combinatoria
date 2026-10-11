extends Control

# Control de extracción continua (Tómbola automática)
const DRAW_INTERVAL: float = 7.0
var draw_timer: float = 3.0
var is_auto_running: bool = true

# Referencias UI - Fondos
@onready var background: TextureRect = $Background
@onready var blur_overlay: ColorRect = $BlurOverlay

# Referencias UI - HUD
@onready var hud: HBoxContainer = $SafeArea/MainLayout/HUD
@onready var lbl_lives: Label = $SafeArea/MainLayout/HUD/LblLives
@onready var lbl_coins: Label = $SafeArea/MainLayout/HUD/LblCoins
@onready var lbl_stars: Label = $SafeArea/MainLayout/HUD/LblStars

# Referencias UI - Tómbola
@onready var tombola_section: PanelContainer = $SafeArea/MainLayout/TombolaSection
@onready var ball_circle: PanelContainer = $SafeArea/MainLayout/TombolaSection/Margin/TombolaVBox/BallDisplay/BallCircle
@onready var lbl_ball_letter: Label = $SafeArea/MainLayout/TombolaSection/Margin/TombolaVBox/BallDisplay/BallCircle/BallVBox/LblBallLetter
@onready var lbl_ball_number: Label = $SafeArea/MainLayout/TombolaSection/Margin/TombolaVBox/BallDisplay/BallCircle/BallVBox/LblBallNumber
@onready var recent_balls_rack: HBoxContainer = $SafeArea/MainLayout/TombolaSection/Margin/TombolaVBox/RecentBallsRack
@onready var btn_draw_ball: Button = $SafeArea/MainLayout/TombolaSection/Margin/TombolaVBox/BtnDrawBall

# Referencias UI - Tablero y Acciones
@onready var card_grid: GridContainer = $SafeArea/MainLayout/BoardContainer/CardGrid
@onready var btn_bingo: Button = $SafeArea/MainLayout/Actions/BtnBingo
@onready var btn_change_env: Button = $SafeArea/MainLayout/Actions/BtnChangeEnv

# Modales y Audio
@onready var trivia_modal: Control = $UIOverlay/TriviaModal
@onready var end_game_modal: Control = $UIOverlay/EndGameModal
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

# Archivos de audio personalizados
const SFX_TRIVIA_CORRECT: AudioStream = preload("res://assets/audio/trivia_correct.mp3")
const SFX_TRIVIA_WRONG: AudioStream = preload("res://assets/audio/trivia_wrong.mp3")
const SFX_BALL_DRAW: AudioStream = preload("res://assets/audio/ball_draw.mp3")
const SFX_PENCIL: AudioStream = preload("res://assets/audio/pencil_mark.mp3")

# Instancias Lógicas
var tombola: BingoTombola
var card: BingoCard
var trivia_manager: TriviaManager

var cell_buttons: Array = []
var recent_balls: Array[int] = []


func _ready() -> void:
	tombola = BingoTombola.new()
	card = BingoCard.new()
	trivia_manager = TriviaManager.new()

	# Conexiones con el GameManager
	GameManager.lives_changed.connect(_update_hud)
	GameManager.coins_changed.connect(_update_hud)
	GameManager.stars_changed.connect(_update_hud)
	GameManager.game_over.connect(_on_game_over)
	GameManager.environment_changed.connect(_on_environment_changed)

	# Botones y eventos
	btn_draw_ball.pressed.connect(_on_toggle_auto_draw_pressed)
	btn_bingo.pressed.connect(_on_btn_bingo_pressed)
	btn_change_env.pressed.connect(_on_btn_change_env_pressed)
	trivia_modal.trivia_answered.connect(_on_trivia_answered)

	_setup_pro_styles()
	_build_visual_grid()
	_apply_environment(GameManager.current_environment)
	_update_hud()


## Bucle de extracción continua con temporizador
func _process(delta: float) -> void:
	if not is_auto_running:
		return
	
	draw_timer -= delta
	btn_draw_ball.text = "PAUSAR TÓMBOLA  (%.1fs)" % max(draw_timer, 0.0)

	if draw_timer <= 0.0:
		draw_timer = DRAW_INTERVAL
		_draw_next_ball()


func _on_toggle_auto_draw_pressed() -> void:
	is_auto_running = not is_auto_running
	if not is_auto_running:
		btn_draw_ball.text = "REANUDAR TÓMBOLA"
		btn_draw_ball.modulate = Color("#f39c12")
	else:
		btn_draw_ball.modulate = Color("#ffffff")


func _draw_next_ball() -> void:
	var ball: int = tombola.draw_next_ball()
	if ball == -1:
		lbl_ball_number.text = "FIN"
		is_auto_running = false
		btn_draw_ball.disabled = true
		btn_draw_ball.text = "TÓMBOLA VACÍA"
		end_game_modal.show_game_over(false, "Se agotaron todas las balotas disponibles.")
		return

	sfx_player.stream = SFX_BALL_DRAW
	sfx_player.play()

	var info: Dictionary = _get_ball_info(ball)
	lbl_ball_letter.text = info["letter"]
	lbl_ball_number.text = "%02d" % ball
	_style_ball(ball_circle, info["color"], info["border"])

	var tween := create_tween()
	ball_circle.scale = Vector2(0.4, 0.4)
	tween.tween_property(ball_circle, "scale", Vector2(1.18, 1.18), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(ball_circle, "scale", Vector2(1.0, 1.0), 0.12)

	recent_balls.push_front(ball)
	if recent_balls.size() > 5:
		recent_balls.pop_back()
	_update_recent_balls_rack()

	# 20% de probabilidad de pausar la tómbola y lanzar trivia
	if randf() <= 0.20:
		is_auto_running = false
		btn_draw_ball.text = "¡TRIVIA EN CURSO!"
		_trigger_trivia()


func _trigger_trivia() -> void:
	var question_data: Dictionary = trivia_manager.get_random_question()
	if not question_data.is_empty():
		trivia_modal.open_trivia(question_data)


func _on_trivia_answered(success: bool) -> void:
	is_auto_running = true
	draw_timer = DRAW_INTERVAL
	btn_draw_ball.modulate = Color("#ffffff")
	
	if success:
		sfx_player.volume_db = 0.0
		sfx_player.stream = SFX_TRIVIA_CORRECT
		sfx_player.play()
		lbl_ball_letter.text = "¡BONUS!"
	else:
		# Sube el volumen (+5 dB le da un realce notable y claro)
		sfx_player.volume_db = 6.0
		sfx_player.stream = SFX_TRIVIA_WRONG
		sfx_player.play()


## Reproduce 2.0 segundos de lápiz con desvanecimiento suave al final
func _play_pencil_sfx() -> void:
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = SFX_PENCIL
	player.volume_db = 0.0
	var start_pos: float = randf_range(0.0, 18.0)
	player.play(start_pos)
	
	var tw := create_tween()
	tw.tween_interval(1.7)
	tw.tween_property(player, "volume_db", -40.0, 0.3)
	tw.tween_callback(player.queue_free)


func _setup_pro_styles() -> void:
	_style_hud_chip(lbl_lives)
	_style_hud_chip(lbl_coins)
	_style_hud_chip(lbl_stars)

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

	ball_circle.custom_minimum_size = Vector2(180, 180)
	ball_circle.pivot_offset = Vector2(90, 90)
	_style_ball(ball_circle, Color("#2b3340"), Color("#475569"))

	lbl_ball_letter.text = "BINGO"
	lbl_ball_letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_ball_letter.add_theme_font_size_override("font_size", 22)

	lbl_ball_number.text = "--"
	lbl_ball_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_ball_number.add_theme_font_size_override("font_size", 66)

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

	_style_pill_button(btn_bingo, Color("#e11d48"), Color("#fb7185"), 26)
	_style_pill_button(btn_change_env, Color("#1e293b"), Color("#475569"), 20)

	recent_balls_rack.alignment = BoxContainer.ALIGNMENT_CENTER


func _style_hud_chip(lbl: Label) -> void:
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
		_play_tone(950.0, 0.4)
		GameManager.add_stars(5)
		GameManager.add_coins(200)
		btn_bingo.disabled = true
		end_game_modal.show_game_over(true, "¡Patrón completado: %s!" % win_data["pattern"])
	else:
		_play_tone(180.0, 0.3)
		GameManager.lose_life()


func _on_game_over() -> void:
	is_auto_running = false
	_play_tone(150.0, 0.5)
	end_game_modal.show_game_over(false, "Te has quedado sin vidas.")


func _on_btn_change_env_pressed() -> void:
	if GameManager.current_environment == GameManager.GameEnvironment.LOGIC_ACADEMY:
		GameManager.set_environment(GameManager.GameEnvironment.CYBER_CASINO)
	else:
		GameManager.set_environment(GameManager.GameEnvironment.LOGIC_ACADEMY)


func _on_environment_changed(_env_name: String) -> void:
	_apply_environment(GameManager.current_environment)


func _apply_environment(env: GameManager.GameEnvironment) -> void:
	match env:
		GameManager.GameEnvironment.LOGIC_ACADEMY:
			background.texture = load("res://assets/sprites/env_resort.jpeg")
			if blur_overlay and blur_overlay.material:
				blur_overlay.material.set_shader_parameter("tint_color", Color(0.06, 0.14, 0.10, 0.72))
			btn_bingo.modulate = Color("#e5c158")
			btn_change_env.modulate = Color("#ffffff")
		
		GameManager.GameEnvironment.CYBER_CASINO:
			background.texture = load("res://assets/sprites/env_brick_town.png")
			if blur_overlay and blur_overlay.material:
				blur_overlay.material.set_shader_parameter("tint_color", Color(0.12, 0.08, 0.04, 0.72))
			btn_bingo.modulate = Color("#ff9900")
			btn_change_env.modulate = Color("#ffd166")


func _update_hud(_val: int = 0) -> void:
	lbl_lives.text = "❤  %d/%d" % [GameManager.lives, GameManager.MAX_LIVES]
	lbl_coins.text = "🪙  %d" % GameManager.coins
	lbl_stars.text = "⭐  %d" % GameManager.stars


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
	sfx_player.stream = stream
	sfx_player.play()
