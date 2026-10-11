extends Control

@onready var modal_vbox: VBoxContainer = $ModalContainer/Margin/VBox
@onready var lbl_result_title: Label = $ModalContainer/Margin/VBox/LblResultTitle
@onready var lbl_stats: Label = $ModalContainer/Margin/VBox/LblStats
@onready var btn_restart: Button = $ModalContainer/Margin/VBox/BtnRestart
@onready var btn_return_menu: Button = $ModalContainer/Margin/VBox/BtnReturnMenu

const MAIN_MENU_PATH: String = "res://scenes/menus/MainMenu.tscn"

const SFX_VICTORY: AudioStream = preload("res://assets/audio/victory_cheer.mp3")
const SFX_GAME_OVER: AudioStream = preload("res://assets/audio/game_over_fail.mp3")

var audio_player: AudioStreamPlayer
var btn_revive: Button


func _ready() -> void:
	visible = false
	btn_restart.pressed.connect(_on_btn_restart_pressed)
	btn_return_menu.pressed.connect(_on_btn_return_menu_pressed)

	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)

	_create_revive_button()


func _create_revive_button() -> void:
	btn_revive = Button.new()
	btn_revive.custom_minimum_size.y = 70
	btn_revive.add_theme_font_size_override("font_size", 22)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#f59e0b")
	style.corner_radius_top_left = 35
	style.corner_radius_top_right = 35
	style.corner_radius_bottom_left = 35
	style.corner_radius_bottom_right = 35
	style.border_width_top = 3
	style.border_color = Color("#fcd34d")
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 6
	btn_revive.add_theme_stylebox_override("normal", style)
	
	btn_revive.pressed.connect(_on_btn_revive_pressed)
	
	# Se inserta justo antes del botón de reiniciar
	modal_vbox.add_child(btn_revive)
	modal_vbox.move_child(btn_revive, btn_restart.get_index())


func show_game_over(won: bool, reason: String = "") -> void:
	if won:
		lbl_result_title.text = "¡BINGO COMPLETADO!"
		lbl_result_title.modulate = Color("#2ecc71")
		btn_revive.visible = false
		if audio_player:
			audio_player.stream = SFX_VICTORY
			audio_player.play()
	else:
		lbl_result_title.text = "FIN DEL JUEGO"
		lbl_result_title.modulate = Color("#e74c3c")
		_setup_revive_state()
		if audio_player:
			audio_player.stream = SFX_GAME_OVER
			audio_player.play()
	
	lbl_stats.text = "%s\n\n⭐ Estrellas totales: %d\n🪙 Saldo disponible: %d\n🧠 Preguntas acertadas: %d / %d" % [
		reason,
		GameManager.stars,
		GameManager.coins,
		GameManager.trivia_correct_count,
		GameManager.trivia_total_count
	]
	
	visible = true


func _setup_revive_state() -> void:
	btn_revive.visible = true
	if GameManager.coins >= GameManager.REVIVE_COIN_COST:
		btn_revive.disabled = false
		btn_revive.text = "REVIVIR (+1 ❤) — %d 🪙" % GameManager.REVIVE_COIN_COST
		btn_revive.modulate = Color("#ffffff")
	else:
		btn_revive.disabled = true
		btn_revive.text = "REVIVIR (%d/%d 🪙)" % [GameManager.coins, GameManager.REVIVE_COIN_COST]
		btn_revive.modulate = Color(1.0, 1.0, 1.0, 0.6)


func _on_btn_revive_pressed() -> void:
	if GameManager.try_revive():
		if audio_player and audio_player.is_playing():
			audio_player.stop()
		visible = false


func _on_btn_restart_pressed() -> void:
	GameManager.reset_game_session()
	get_tree().reload_current_scene()


func _on_btn_return_menu_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
