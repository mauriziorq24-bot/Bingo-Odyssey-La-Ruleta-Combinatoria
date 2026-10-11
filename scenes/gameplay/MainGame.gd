extends Control

# Control de extracción continua (Tómbola automática)
const DRAW_INTERVAL: float = 7.0
var draw_timer: float = 3.0
var is_auto_running: bool = true

# Referencias UI - Fondos
@onready var background: TextureRect = $Background
@onready var blur_overlay: ColorRect = $BlurOverlay

# Referencias UI - HUD
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


## Temporizador de la tómbola automática
func _process(delta: float) -> void:
	if not is_auto_running:
		return
	
	draw_timer -= delta
	btn_draw_ball.text = "PAUSAR TÓMBOLA (%.1fs)" % max(draw_timer, 0.0)

	if draw_timer <= 0.0:
		draw_timer = DRAW_INTERVAL
		_draw_next_ball()


## Alterna pausa y reanudación manual del giro
func _on_toggle_auto_draw_pressed() -> void:
	is_auto_running = not is_auto_running
	if not is_auto_running:
		btn_draw_ball.text = "REANUDAR TÓMBOLA"
		btn_draw_ball.modulate = Color("#f39c12")
	else:
		btn_draw_ball.modulate = Color("#ffffff")


## Extrae balota, ejecuta animación y calcula probabilidad de trivia
func _draw_next_ball() -> void:
	var ball: int = tombola.draw_next_ball()
	if ball == -1:
		lbl_ball_number.text = "FIN"
		is_auto_running = false
		btn_draw_ball.disabled = true
		btn_draw_ball.text = "TÓMBOLA VACÍA"
		end_game_modal.show_game_over(false, "Se agotaron todas las balotas disponibles.")
		return

	_play_tone(440.0, 0.08)
	var info: Dictionary = _get_ball_info(ball)
	lbl_ball_letter.text = info["letter"]
	lbl_ball_number.text = "%02d" % ball
	_style_ball(ball_circle, info["color"], info["border"])

	# Animación Juice de rebote
	var tween := create_tween()
	ball_circle.scale = Vector2(0.5, 0.5)
	tween.tween_property(ball_circle, "scale", Vector2(1.15, 1.15), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(ball_circle, "scale", Vector2(1.0, 1.0), 0.12)

	# Historial en bandeja
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
	# Al contestar se reanuda la marcha automática
	is_auto_running = true
	draw_timer = DRAW_INTERVAL
	btn_draw_ball.modulate = Color("#ffffff")
	if success:
		_play_tone(880.0, 0.15)
		lbl_ball_letter.text = "¡BONUS!"
	else:
		_play_tone(200.0, 0.25)


## Estilos vectoriales modernos para la tómbola
func _setup_pro_styles() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.12, 0.16, 0.85)
	panel_style.corner_radius_top_left = 24
	panel_style.corner_radius_top_right = 24
	panel_style.corner_radius_bottom_left = 24
	panel_style.corner_radius_bottom_right = 24
	panel_style.shadow_color = Color(0, 0, 0, 0.45)
	panel_style.shadow_size = 12
	panel_style.shadow_offset = Vector2(0, 6)
	tombola_section.add_theme_stylebox_override("panel", panel_style)

	ball_circle.custom_minimum_size = Vector2(180, 180)
	ball_circle.pivot_offset = Vector2(90, 90)
	_style_ball(ball_circle, Color("#3a4454"), Color("#5a6982"))

	lbl_ball_letter.text = "BINGO"
	lbl_ball_letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_ball_letter.add_theme_font_size_override("font_size", 22)

	lbl_ball_number.text = "--"
	lbl_ball_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_ball_number.add_theme_font_size_override("font_size", 64)

	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color("#2ecc71")
	btn_style.corner_radius_top_left = 30
	btn_style.corner_radius_top_right = 30
	btn_style.corner_radius_bottom_left = 30
	btn_style.corner_radius_bottom_right = 30
	btn_style.shadow_color = Color(0, 0, 0, 0.3)
	btn_style.shadow_size = 6
	btn_style.shadow_offset = Vector2(0, 4)
	btn_draw_ball.add_theme_stylebox_override("normal", btn_style)
	btn_draw_ball.add_theme_font_size_override("font_size", 24)
	btn_draw_ball.custom_minimum_size = Vector2(0, 75)

	recent_balls_rack.alignment = BoxContainer.ALIGNMENT_CENTER


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
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 5)
	panel.add_theme_stylebox_override("panel", style)


func _get_ball_info(num: int) -> Dictionary:
	if num <= 15:
		return {"letter": "B", "color": Color("#2980b9"), "border": Color("#5dade2")}
	elif num <= 30:
		return {"letter": "I", "color": Color("#c0392b"), "border": Color("#e74c3c")}
	elif num <= 45:
		return {"letter": "N", "color": Color("#d35400"), "border": Color("#f39c12")}
	elif num <= 60:
		return {"letter": "G", "color": Color("#27ae60"), "border": Color("#2ecc71")}
	else:
		return {"letter": "O", "color": Color("#8e44ad"), "border": Color("#bb8fce")}


func _update_recent_balls_rack() -> void:
	for c in recent_balls_rack.get_children():
		c.queue_free()

	for i in range(1, recent_balls.size()):
		var past_ball: int = recent_balls[i]
		var info: Dictionary = _get_ball_info(past_ball)

		var mini_ball := PanelContainer.new()
		mini_ball.custom_minimum_size = Vector2(50, 50)
		_style_ball(mini_ball, info["color"], info["border"])

		var lbl := Label.new()
		lbl.text = str(past_ball)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 18)

		mini_ball.add_child(lbl)
		recent_balls_rack.add_child(mini_ball)


## Construcción del cartón 5x5 con encabezado
func _build_visual_grid() -> void:
	for child in card_grid.get_children():
		child.queue_free()
	cell_buttons.clear()

	var letters: Array[String] = ["B", "I", "N", "G", "O"]
	for letter in letters:
		var lbl := Label.new()
		lbl.text = letter
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.custom_minimum_size = Vector2(170, 60)
		lbl.add_theme_font_size_override("font_size", 38)
		card_grid.add_child(lbl)

	for r in range(5):
		var row_btns: Array[Button] = []
		for c in range(5):
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(170, 170)
			btn.add_theme_font_size_override("font_size", 34)

			var num: int = card.grid[r][c]
			if r == 2 and c == 2:
				btn.text = "★\nLIBRE"
				btn.disabled = true
			else:
				btn.text = str(num)
				btn.pressed.connect(func(): _on_cell_pressed(r, c, btn))

			card_grid.add_child(btn)
			row_btns.append(btn)
		cell_buttons.append(row_btns)


func _on_cell_pressed(row: int, col: int, btn: Button) -> void:
	var cell_number: int = card.grid[row][col]
	if tombola.has_been_drawn(cell_number):
		if card.mark_cell(row, col):
			_play_tone(660.0, 0.12)
			btn.disabled = true
			btn.text = str(cell_number) + "\n✔"
			GameManager.add_coins(10)
	else:
		_play_tone(220.0, 0.2)
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


## Aplica las texturas y tintes difuminados según el ambiente
func _apply_environment(env: GameManager.GameEnvironment) -> void:
	match env:
		GameManager.GameEnvironment.LOGIC_ACADEMY:
			# Ambiente 1: Resort Costero
			background.texture = load("res://assets/sprites/env_resort.jpeg")
			if blur_overlay and blur_overlay.material:
				blur_overlay.material.set_shader_parameter("tint_color", Color(0.06, 0.14, 0.10, 0.72))
			btn_bingo.modulate = Color("#e5c158")
			btn_change_env.modulate = Color("#ffffff")
		
		GameManager.GameEnvironment.CYBER_CASINO:
			# Ambiente 2: Villa de Bloques
			background.texture = load("res://assets/sprites/env_brick_town.png")
			if blur_overlay and blur_overlay.material:
				blur_overlay.material.set_shader_parameter("tint_color", Color(0.12, 0.08, 0.04, 0.72))
			btn_bingo.modulate = Color("#ff9900")
			btn_change_env.modulate = Color("#ffd166")


func _update_hud(_val: int = 0) -> void:
	lbl_lives.text = "❤ %d/%d" % [GameManager.lives, GameManager.MAX_LIVES]
	lbl_coins.text = "🪙 %d" % GameManager.coins
	lbl_stars.text = "⭐ %d" % GameManager.stars


## Generación sintética procedural de audio para efectos
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
