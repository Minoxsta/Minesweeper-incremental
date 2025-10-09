class_name MinesweeperBoard
extends Node2D

signal game_won
signal game_lost

static var BOARD_SCENE = preload("res://minesweeper_board.tscn")

@export var game_width : int = 10
@export var game_height : int = 15
@export var bomb_count : int = 10

#@onready var mine_tileset : TileSet = $board_grid.tile_set 
var unopened_cell_tile = {"source": 2, "atlas_coords": Vector2i(0,11)}


var cell_array : Array
var bomb_list = []
var hold_list = [] # Should only contain Cell's

var opened_count : int = 0

static func new_board(width : int, height : int, bombs : int) -> MinesweeperBoard:
	var board : MinesweeperBoard = BOARD_SCENE.instantiate()
	board.game_width = width
	board.game_height = height
	board.bomb_count = bombs
	return board

func _init() -> void:
	pass

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	make_game_board()

func initialize_cell_array():
	cell_array = []
	for x in range(game_width):
		cell_array.append([])
		for y in range(game_height):
			var cell = Cell.new(Vector2i(x, y))
			cell_array[x].append(cell)

func make_game_board():
	initialize_cell_array()
	make_bomb_spots()
	find_numbers()
	update_tilemap()

# bomb_list stores the vector positions of the chosen bombs
func make_bomb_spots():
	while bomb_list.size() < bomb_count:
		add_bomb()

func find_numbers():
	for x in range(game_width):
		for y in range(game_height):
			find_number(cell_array[x][y])

func find_number(cell : Cell):
	if cell.bomb:
		return
	
	var neighbors = get_neighbors(cell.coords)
	var count = 0
	for neigbor : Cell in neighbors:
		if neigbor.bomb:
			count += 1
	
	#print(count)
	cell.bomb_neighbors = count

func add_bomb() -> Vector2i:
	var new_bomb_x = randi() % game_width
	var new_bomb_y = randi() % game_height
	while Vector2i(new_bomb_x, new_bomb_y) in bomb_list:
		new_bomb_x = randi() % game_width
		new_bomb_y = randi() % game_height
	
	var bomb_spot = Vector2i(new_bomb_x, new_bomb_y)
	
	cell_array[new_bomb_x][new_bomb_y].bomb = true
	bomb_list.append(bomb_spot)
	
	return bomb_spot

func update_tilemap():
	for x in range(game_width):
		for y in range(game_height):
			var cell : Cell = cell_array[x][y]
			$board_grid.set_cell(Vector2i(x,y), Cell.SOURCE, cell.get_atlas())


func get_cell_at_vector(vec : Vector2i):
	var width = cell_array.size()
	if vec.x < width and vec.x >= 0:
		var height = cell_array[vec.x].size()
		if vec.y < height and vec.y >= 0:
			return cell_array[vec.x][vec.y]
	
	return null

func get_cell_at(x : int, y : int):
	return cell_array[x][y]

func _process(_delta: float) -> void:
	if Input.is_action_pressed("main_action"):
		var board_grid_pos = grid_coord_at_mouse()
		var cell : Cell = get_cell_at_vector(board_grid_pos)
		release_all()
		if cell != null:
			hold(cell)


	if Input.is_action_just_released("main_action"):
		var board_grid_pos = grid_coord_at_mouse()
		var cell : Cell = get_cell_at_vector(board_grid_pos)
		if cell != null:
			open(cell)
		release_all()


	if Input.is_action_just_pressed("secondary_action"):
		var board_grid_pos = grid_coord_at_mouse()
		var cell : Cell = get_cell_at_vector(board_grid_pos)
		if cell != null:
			flag(cell)
		
	update_tilemap()

func grid_coord_at_mouse() -> Vector2i:
	var mouse_pos = get_global_mouse_position()
	return $board_grid.local_to_map($board_grid.to_local(mouse_pos))

func hold(cell : Cell):
	release_all()
	
	if cell.open:
		var neighbors = get_neighbors(cell.coords)
		for neighbor : Cell in neighbors:
			neighbor.hold()
			hold_list.push_back(neighbor)
	else:
		cell.hold()
		hold_list.push_back(cell)


func release_all():
	while not hold_list.is_empty():
		var old_cell : Cell = hold_list.pop_back()
		old_cell.release()

func open(cell : Cell):
	match cell.open_cell():
		Cell.CELL_OPEN_RESPONSE.OPEN_NUMBER:
			# Check if adjacent flags equals number
			var neighbors = get_neighbors(cell.coords)
			var flag_count = count_flags(neighbors)
			if flag_count == cell.bomb_neighbors:
				open_all_held()
			
			return
		Cell.CELL_OPEN_RESPONSE.FLAGGED:
			return
		Cell.CELL_OPEN_RESPONSE.OPEN_SAFE:
			# Safely opened a closed cell
			opened_count += 1
			if cell.bomb_neighbors == 0:
				for neighbor in get_neighbors(cell.coords):
					open(neighbor)
		Cell.CELL_OPEN_RESPONSE.BOMB:
			cell.set_reveal_state(true)
			lose()
			pass
	if opened_count >= win_count():
		win()

func count_flags(cell_list : Array) -> int:
	var flags = 0
	for cell : Cell in cell_list:
		if cell.flagged:
			flags += 1
	return flags

func open_all_held():
	for cell : Cell in hold_list:
		if not cell.open:
			open(cell)

func flag(cell : Cell):
	if cell.open:
		return
	
	cell.flag()
	# Decrease bomb counter

func win_count():
	return game_width * game_height - bomb_count

func win():
	# Reveal/flag all
	for col in cell_array:
		for cell : Cell in col:
			if cell.bomb and not cell.flagged:
				flag(cell)
			else:
				open(cell)
	
	var _3bv = calculate_3bv()
	
	get_tree().paused = true
	emit_signal("game_won")

func lose():
	for col in cell_array:
		for cell : Cell in col:
			cell.set_reveal_state()
	
	get_tree().paused = true
	emit_signal("game_lost")

# Iterates over -1, 0, 1 to add to x and y of the given coordinate 
# to generate all the neighbors in a square around the coord.
func get_neighbors(coords: Vector2i):
	var neighbors = []
	for i in range(-1, 2):
		for j in range(-1, 2):
			var x = coords.x + i
			var y = coords.y + j
			if i == 0 and j == 0:
				continue
			if 0 <= x and x < game_width and 0 <= y and y < game_height:
				neighbors.append(cell_array[x][y])
	
	return neighbors


func calculate_3bv() -> int:
	var count_3bv = 0
	for col in cell_array:
		for cell : Cell in col:
			if adds_to_3bv(cell):
				count_3bv += 1
	
	print(count_3bv)
	return count_3bv

func adds_to_3bv(cell : Cell) -> bool:
	if cell.bomb or cell.counted_3bv:
		return false
	
	cell.counted_3bv = true
	
	if cell.bomb_neighbors > 0:
		if not has_0_neighbor(cell):
			return true
	
	var queue = get_neighbors(cell.coords)
	while not queue.is_empty():
		var q_cell : Cell = queue.pop_back()
		if q_cell.counted_3bv:
			continue
		q_cell.counted_3bv = true
		if q_cell.bomb_neighbors == 0 and not q_cell.bomb:
			queue += get_neighbors(q_cell.coords)
		
	return true

func has_0_neighbor(cell : Cell):
	for neighbor : Cell in get_neighbors(cell.coords):
		if neighbor.bomb_neighbors == 0 and not neighbor.bomb:
			return true
	return false
