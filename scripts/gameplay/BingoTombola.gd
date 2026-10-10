class_name BingoTombola
extends RefCounted

## Administra la bolsa de balotas (1 al 75) y las extracciones

signal ball_drawn(number: int, remaining_count: int)
signal tombola_empty

const TOTAL_BALLS: int = 75

var available_balls: Array[int] = []
var drawn_balls: Array[int] = []


func _init() -> void:
	reset_tombola()


## Llena y baraja la bolsa con los números del 1 al 75
func reset_tombola() -> void:
	available_balls.clear()
	drawn_balls.clear()
	
	for i in range(1, TOTAL_BALLS + 1):
		available_balls.append(i)
	
	available_balls.shuffle()


## Extrae la siguiente balota de la bolsa
func draw_next_ball() -> int:
	if available_balls.is_empty():
		tombola_empty.emit()
		return -1
	
	var ball: int = available_balls.pop_back()
	drawn_balls.append(ball)
	ball_drawn.emit(ball, available_balls.size())
	return ball


## Verifica si un número ya ha salido en la partida
func has_been_drawn(number: int) -> bool:
	return number in drawn_balls
