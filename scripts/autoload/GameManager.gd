extends Node

enum GameEnvironment { LOGIC_ACADEMY, CYBER_CASINO }

const MAX_LIVES: int = 3
const SAVE_FILE_PATH: String = "user://save_data.json"
const BRICK_TOWN_STAR_REQUIREMENT: int = 20
const REVIVE_COIN_COST: int = 50

signal lives_changed(new_lives: int)
signal coins_changed(new_coins: int)
signal stars_changed(new_stars: int)
signal environment_changed(new_env: String)
signal game_over
signal game_revived

var lives: int = MAX_LIVES
var coins: int = 0
var stars: int = 0
var current_environment: GameEnvironment = GameEnvironment.LOGIC_ACADEMY

# Métricas de la partida en curso
var trivia_correct_count: int = 0
var trivia_total_count: int = 0


func _ready() -> void:
	load_game_data()


## Reinicia los valores de la sesión de juego (incluidas las monedas a 0)
func reset_game_session() -> void:
	lives = MAX_LIVES
	coins = 0
	trivia_correct_count = 0
	trivia_total_count = 0
	
	lives_changed.emit(lives)
	coins_changed.emit(coins)
	save_game_data()


func add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)
	save_game_data()


func add_stars(amount: int) -> void:
	stars += amount
	stars_changed.emit(stars)
	save_game_data()


func lose_life() -> void:
	lives = max(lives - 1, 0)
	lives_changed.emit(lives)
	if lives <= 0:
		game_over.emit()


func can_revive() -> bool:
	return coins >= REVIVE_COIN_COST and lives <= 0


func try_revive() -> bool:
	if can_revive():
		coins -= REVIVE_COIN_COST
		coins_changed.emit(coins)
		lives = 1
		lives_changed.emit(lives)
		save_game_data()
		game_revived.emit()
		return true
	return false


func is_environment_unlocked(env: GameEnvironment) -> bool:
	match env:
		GameEnvironment.LOGIC_ACADEMY:
			return true
		GameEnvironment.CYBER_CASINO:
			return stars >= BRICK_TOWN_STAR_REQUIREMENT
	return false


func set_environment(new_env: GameEnvironment) -> bool:
	if is_environment_unlocked(new_env):
		current_environment = new_env
		environment_changed.emit(get_environment_name())
		return true
	return false


func get_environment_name() -> String:
	match current_environment:
		GameEnvironment.LOGIC_ACADEMY:
			return "Resort Costero"
		GameEnvironment.CYBER_CASINO:
			return "Villa de Bloques"
	return "Desconocido"


func save_game_data() -> void:
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		var data: Dictionary = {
			"coins": coins,
			"stars": stars
		}
		file.store_string(JSON.stringify(data))


func load_game_data() -> void:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			coins = int(parsed.get("coins", 0))
			stars = int(parsed.get("stars", 0))
