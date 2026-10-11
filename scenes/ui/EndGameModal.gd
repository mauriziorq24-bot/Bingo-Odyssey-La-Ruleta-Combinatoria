extends Control

@onready var lbl_result_title: Label = $ModalContainer/Margin/VBox/LblResultTitle
@onready var lbl_stats: Label = $ModalContainer/Margin/VBox/LblStats
@onready var btn_restart: Button = $ModalContainer/Margin/VBox/BtnRestart
@onready var btn_return_menu: Button = $ModalContainer/Margin/VBox/BtnReturnMenu

const MAIN_MENU_PATH: String = "res://scenes/menus/MainMenu.tscn"

# Audios de fin de partida
const SFX_VICTORY: AudioStream = preload("res://assets/audio/victory_cheer.mp3")
const SFX_GAME_OVER: AudioStream = preload("res://assets/audio/game_over_fail.mp3")

var audio_player: AudioStreamPlayer


func _ready() -> void:
	visible = false
	btn_restart.pressed.connect(_on_btn_restart_pressed)
	btn_return_menu.pressed.connect(_on_btn_return_menu_pressed)

	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)


func show_game_over(won: bool, reason: String = "") -> void:
	if won:
		lbl_result_title.text = "¡BINGO COMPLETADO!"
		lbl_result_title.modulate = Color("#2ecc71")
		if audio_player:
			audio_player.stream = SFX_VICTORY
			audio_player.play()
	else:
		lbl_result_title.text = "FIN DEL JUEGO"
		lbl_result_title.modulate = Color("#e74c3c")
		if audio_player:
			audio_player.stream = SFX_GAME_OVER
			audio_player.play()
	
	lbl_stats.text = "%s\n\n⭐ Estrellas obtenidas: %d\n🪙 Monedas ganadas: %d\n🧠 Preguntas acertadas: %d / %d" % [
		reason,
		GameManager.stars,
		GameManager.coins,
		GameManager.trivia_correct_count,
		GameManager.trivia_total_count
	]
	
	visible = true


func _on_btn_restart_pressed() -> void:
	GameManager.reset_game_session()
	get_tree().reload_current_scene()


func _on_btn_return_menu_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
