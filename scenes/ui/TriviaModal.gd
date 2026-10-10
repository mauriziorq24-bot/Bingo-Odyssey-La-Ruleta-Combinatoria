extends Control

signal trivia_answered(success: bool)

const TIME_LIMIT: float = 28.0

@onready var lbl_category: Label = $ModalContainer/MarginContainer/VBox/LblCategory
@onready var lbl_question: Label = $ModalContainer/MarginContainer/VBox/LblQuestion
@onready var timer_bar: ProgressBar = $ModalContainer/MarginContainer/VBox/TimerBar
@onready var option_buttons: Array[Button] = [
	$ModalContainer/MarginContainer/VBox/Option0,
	$ModalContainer/MarginContainer/VBox/Option1,
	$ModalContainer/MarginContainer/VBox/Option2,
	$ModalContainer/MarginContainer/VBox/Option3
]

var current_question_data: Dictionary = {}
var time_left: float = TIME_LIMIT
var is_active: bool = false


func _ready() -> void:
	visible = false
	for i in range(option_buttons.size()):
		var idx: int = i
		option_buttons[idx].pressed.connect(func(): _on_option_selected(idx))


func _process(delta: float) -> void:
	if not is_active:
		return
	
	time_left -= delta
	timer_bar.value = (time_left / TIME_LIMIT) * 100.0
	
	if time_left <= 0.0:
		_on_time_out()


## Abre el modal e inicializa la pregunta
func open_trivia(data: Dictionary) -> void:
	if data.is_empty():
		return
	
	current_question_data = data
	time_left = TIME_LIMIT
	timer_bar.value = 100.0
	is_active = true
	
	lbl_category.text = "CATEGORÍA: " + data.get("category", "General").to_upper()
	lbl_question.text = data.get("question", "")
	
	var options: Array = data.get("options", [])
	for i in range(option_buttons.size()):
		if i < options.size():
			option_buttons[i].visible = true
			option_buttons[i].text = options[i]
			option_buttons[i].disabled = false
		else:
			option_buttons[i].visible = false
	
	visible = true


func _on_option_selected(index: int) -> void:
	if not is_active:
		return
	
	is_active = false
	var correct_idx: int = current_question_data.get("correct_index", -1)
	
	if index == correct_idx:
		_handle_success()
	else:
		_handle_failure()


func _on_time_out() -> void:
	is_active = false
	_handle_failure()


func _handle_success() -> void:
	var coins: int = current_question_data.get("reward_coins", 25)
	var stars: int = current_question_data.get("reward_stars", 1)
	
	GameManager.add_coins(coins)
	GameManager.add_stars(stars)
	GameManager.trivia_correct_count += 1
	GameManager.trivia_total_count += 1
	
	visible = false
	trivia_answered.emit(true)


func _handle_failure() -> void:
	GameManager.lose_life()
	GameManager.trivia_total_count += 1
	
	visible = false
	trivia_answered.emit(false)
