class_name BingoCard
extends RefCounted

## Representa una matriz 5x5 de Bingo y sus estados de marcado

# Rangos oficiales del Bingo de 75 balotas
const COLUMN_RANGES: Dictionary = {
	0: {"min": 1,  "max": 15},  # B
	1: {"min": 16, "max": 30},  # I
	2: {"min": 31, "max": 45},  # N
	3: {"min": 46, "max": 60},  # G
	4: {"min": 61, "max": 75}   # O
}

# Matriz 5x5 de números enteros
var grid: Array = []
# Matriz 5x5 de booleanos (true si la casilla está marcada)
var marked: Array = []


func _init() -> void:
	generate_new_card()


## Genera un cartón válido con números aleatorios no repetidos por columna
func generate_new_card() -> void:
	grid.clear()
	marked.clear()
	
	# Inicializamos la matriz vacía de 5x5
	for r in range(5):
		grid.append([0, 0, 0, 0, 0])
		marked.append([false, false, false, false, false])
	
	# Poblamos columna por columna asegurando valores únicos
	for col in range(5):
		var col_min: int = COLUMN_RANGES[col]["min"]
		var col_max: int = COLUMN_RANGES[col]["max"]
		
		var possible_numbers: Array[int] = []
		for n in range(col_min, col_max + 1):
			possible_numbers.append(n)
		possible_numbers.shuffle()
		
		for row in range(5):
			# La casilla central (fila 2, col 2) es LIBRE / GRATIS
			if row == 2 and col == 2:
				grid[row][col] = 0
				marked[row][col] = true
			else:
				grid[row][col] = possible_numbers.pop_back()


## Marca una casilla en (row, col) si el número coincide y no estaba marcada
func mark_cell(row: int, col: int) -> bool:
	if row < 0 or row >= 5 or col < 0 or col >= 5:
		return false
	
	if not marked[row][col]:
		marked[row][col] = true
		return true
	return false


## Comprueba si se ha formado un patrón ganador:
## Devuelve un Diccionario indicando el tipo de victoria lograda
func check_win_patterns() -> Dictionary:
	var result: Dictionary = {
		"has_won": false,
		"pattern": "",
		"completed_lines": 0
	}
	
	var lines_count: int = 0
	
	# 1. Comprobar Filas Horizontales
	for r in range(5):
		var row_complete: bool = true
		for c in range(5):
			if not marked[r][c]:
				row_complete = false
				break
		if row_complete:
			lines_count += 1

	# 2. Comprobar Columnas Verticales
	for c in range(5):
		var col_complete: bool = true
		for r in range(5):
			if not marked[r][c]:
				col_complete = false
				break
		if col_complete:
			lines_count += 1

	# 3. Comprobar Diagonal Principal (\)
	var diag1_complete: bool = true
	for i in range(5):
		if not marked[i][i]:
			diag1_complete = false
			break
	if diag1_complete:
		lines_count += 1

	# 4. Comprobar Diagonal Secundaria (/)
	var diag2_complete: bool = true
	for i in range(5):
		if not marked[i][4 - i]:
			diag2_complete = false
			break
	if diag2_complete:
		lines_count += 1

	# 5. Comprobar Cartón Lleno (Blackout)
	var all_marked: bool = true
	for r in range(5):
		for c in range(5):
			if not marked[r][c]:
				all_marked = false
				break
		if not all_marked:
			break

	if all_marked:
		result["has_won"] = true
		result["pattern"] = "FULL_CARD"
	elif lines_count > 0:
		result["has_won"] = true
		result["pattern"] = "LINE"
		result["completed_lines"] = lines_count

	return result
