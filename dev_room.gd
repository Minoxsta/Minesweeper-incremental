extends Node2D

var board_scene = preload("res://minesweeper_board.tscn")

@onready var board : MinesweeperBoard = $board_control/minesweeper_board


func _on_submit_button_pressed() -> void:
	$board_control.remove_child(board)
	
	board = MinesweeperBoard.new_board(
		$input_control/width_label/input_width.value, 
		$input_control/height_label/input_height.value, 
		$input_control/bombs_label/input_bombs.value)
	
	$board_control.add_child(board)
	get_tree().paused = false
	
