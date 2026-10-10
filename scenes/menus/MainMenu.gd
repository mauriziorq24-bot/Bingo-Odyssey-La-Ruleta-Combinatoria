extends Control

@onready var btn_play: Button = $Margin/MenuVBox/ButtonsVBox/BtnPlay
@onready var btn_select_env: Button = $Margin/MenuVBox/ButtonsVBox/BtnSelectEnv
@onready var btn_quit: Button = $Margin/MenuVBox/ButtonsVBox/BtnQuit
@onready var background: ColorRect = $Background

const GAMEPLAY_SCENE_PATH: String = "res://scenes/gameplay/MainGame.tscn"


func _ready() -> void:
	btn_play.pressed.connect(_on_btn_play_pressed)
	btn_select_env.pressed.connect(_on_btn_select_env_pressed)
	btn_quit.pressed.connect(_on_btn_quit_pressed)
	
	_update_env_button_text()


func _on_btn_play_pressed() -> void:
	# Reinicia las vidas y estadísticas globales antes de empezar la partida
	GameManager.reset_game_session()
	get_tree().change_scene_to_file(GAMEPLAY_SCENE_PATH)


func _on_btn_select_env_pressed() -> void:
	if GameManager.current_environment == GameManager.GameEnvironment.LOGIC_ACADEMY:
		GameManager.set_environment(GameManager.GameEnvironment.CYBER_CASINO)
	else:
		GameManager.set_environment(GameManager.GameEnvironment.LOGIC_ACADEMY)
	
	_update_env_button_text()


func _update_env_button_text() -> void:
	if GameManager.current_environment == GameManager.GameEnvironment.LOGIC_ACADEMY:
		btn_select_env.text = "AMBIENTE: ACADEMIA DE LÓGICA"
		background.color = Color("#122216")
		btn_play.modulate = Color("#e5c158")
	else:
		btn_select_env.text = "AMBIENTE: CIBER-CASINO ESTELAR"
		background.color = Color("#0b0c1b")
		btn_play.modulate = Color("#00ffff")


func _on_btn_quit_pressed() -> void:
	get_tree().quit()
