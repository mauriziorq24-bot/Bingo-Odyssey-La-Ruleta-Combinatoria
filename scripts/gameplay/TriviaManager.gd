class_name TriviaManager
extends RefCounted

## Carga y suministra preguntas aleatorias desde el archivo JSON

const QUESTIONS_PATH: String = "res://data/questions.json"

var questions: Array = []
var pending_questions: Array = []


func _init() -> void:
	load_questions()


## Lee y decodifica el JSON de preguntas
func load_questions() -> void:
	if not FileAccess.file_exists(QUESTIONS_PATH):
		push_error("TriviaManager: No se encontró el archivo en " + QUESTIONS_PATH)
		return
	
	var file := FileAccess.open(QUESTIONS_PATH, FileAccess.READ)
	var content := file.get_as_text()
	file.close()
	
	var parsed = JSON.parse_string(content)
	if parsed is Array:
		questions = parsed
		reset_pool()
	else:
		push_error("TriviaManager: El formato del JSON no es válido.")


## Reinicia y baraja la lista de preguntas disponibles
func reset_pool() -> void:
	pending_questions = questions.duplicate()
	pending_questions.shuffle()


## Obtiene una pregunta aleatoria sin repetir hasta agotar el banco
func get_random_question() -> Dictionary:
	if pending_questions.is_empty():
		reset_pool()
	
	if pending_questions.is_empty():
		return {}
	
	return pending_questions.pop_back()
