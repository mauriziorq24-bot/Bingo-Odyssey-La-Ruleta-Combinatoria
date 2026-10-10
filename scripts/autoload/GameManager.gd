extends Node

## GameManager: Administrador global de estado, economía y ambiente

# Señales para que la interfaz (HUD) se actualice automáticamente
signal lives_changed(current_lives: int)
signal coins_changed(current_coins: int)
signal stars_changed(current_stars: int)
signal game_over
signal environment_changed(new_env_name: String)

# Enumerador de los dos ambientes requeridos (renombrado para evitar conflicto con la clase nativa)
enum GameEnvironment {
	LOGIC_ACADEMY,   # Ambiente A: Pizarra, madera, estilo académico
	CYBER_CASINO     # Ambiente B: Neón, espacial, estilo futurista
}

# Configuración inicial del jugador
const MAX_LIVES: int = 3

var lives: int = MAX_LIVES:
	set(value):
		lives = clampi(value, 0, MAX_LIVES)
		lives_changed.emit(lives)
		if lives <= 0:
			game_over.emit()

var coins: int = 0:
	set(value):
		coins = maxi(0, value)
		coins_changed.emit(coins)

var stars: int = 0:
	set(value):
		stars = maxi(0, value)
		stars_changed.emit(stars)

# Bonus activos en la partida actual
var active_bonuses: Dictionary = {
	"double_coins": false,
	"shield": false,         # Protege contra 1 respuesta incorrecta o fallo
	"auto_mark": false       # Marca automáticamente una casilla al azar
}

# Ambiente actual por defecto
var current_environment: GameEnvironment = GameEnvironment.LOGIC_ACADEMY

# Registro de la partida actual
var current_score: int = 0
var trivia_correct_count: int = 0
var trivia_total_count: int = 0


func _ready() -> void:
	print("GameManager inicializado correctamente.")


## Métodos de gestión económica y vidas
func add_coins(amount: int) -> void:
	var multiplier: int = 2 if active_bonuses["double_coins"] else 1
	coins += amount * multiplier

func spend_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		return true
	return false

func add_stars(amount: int) -> void:
	stars += amount

func lose_life() -> void:
	if active_bonuses["shield"]:
		active_bonuses["shield"] = false
		print("¡Escudo consumido! No se perdió vida.")
		return
	lives -= 1

func heal_life(amount: int = 1) -> void:
	lives += amount

## Cambio dinámico de ambientes
func set_environment(env: GameEnvironment) -> void:
	current_environment = env
	var env_name: String = "LOGIC_ACADEMY" if env == GameEnvironment.LOGIC_ACADEMY else "CYBER_CASINO"
	environment_changed.emit(env_name)
	print("Ambiente cambiado a: ", env_name)

## Reiniciar estado para una nueva partida
func reset_game_session() -> void:
	lives = MAX_LIVES
	current_score = 0
	active_bonuses["double_coins"] = false
	active_bonuses["shield"] = false
	active_bonuses["auto_mark"] = false
