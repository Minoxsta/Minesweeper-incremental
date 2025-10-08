class_name Cell


var ORIGIN = Vector2i(0,0)

static var SOURCE = 2

static var UNOPENED_ATLAS = Vector2i(0, 11)
static var UNOPENED_HELD_ATLAS = Vector2i(1, 11)
static var OPEN_ZERO_ATLAS = Vector2i(1, 11)

static var FLAG_ATLAS = Vector2i(2, 11)
static var QMARK_ATLAS = Vector2i(3, 11)
static var QMARK_HELD_ATLAS = Vector2i(4, 11)

static var BOMB_SHOWN_ATLAS = Vector2i(5, 11)
static var BOMB_CLICK_ATLAS = Vector2i(6, 11)
static var BOMB_WRONG_ATLAS = Vector2i(7, 11)

enum CELL_OPEN_RESPONSE {OPEN_SAFE, FLAGGED, BOMB, OPEN_NUMBER}

enum REVEAL_STATE {UNSET, NUMBER, BOMB, BOMB_CLICK, BOMB_WRONG}
var bomb_reveal_dict = {
	REVEAL_STATE.BOMB : BOMB_SHOWN_ATLAS,
	REVEAL_STATE.BOMB_CLICK : BOMB_CLICK_ATLAS,
	REVEAL_STATE.BOMB_WRONG : BOMB_WRONG_ATLAS
}

var coords : Vector2i

var open = false
var held = false
var flagged = false
var bomb = false
var bomb_neighbors = 0

var reveal = false
var reveal_state := REVEAL_STATE.UNSET

static func number_to_atlas(number : int) -> Vector2i:
	if number > 8:
		return Vector2i(-1, -1)
	if number == 0:
		return OPEN_ZERO_ATLAS
	return Vector2i(number-1, 12)

func get_atlas() -> Vector2i:
	if reveal and (flagged or bomb):
		return get_reveal_atlas()
	if open:
		if bomb:
			return BOMB_CLICK_ATLAS
		else:
			return number_to_atlas(bomb_neighbors)
	elif flagged:
		return FLAG_ATLAS
	elif held:
		# Case must be after open, as a cell might be held even if open.
		return UNOPENED_HELD_ATLAS
	else:
		return UNOPENED_ATLAS

# Reveal atlas for bombs and flags
# Assumes reveal_state is set to correct state
func get_reveal_atlas():
	if flagged and bomb:
		return FLAG_ATLAS
	elif flagged:
		return BOMB_WRONG_ATLAS
	
	return bomb_reveal_dict[reveal_state]

func _init(coords_in : Vector2i) -> void:
	coords = coords_in

func hold():
	if open or flagged:
		return
	held = true

func release():
	held = false

# Opens a cell if unopened and not flagged,
# by setting the open flag on the cell.
# Returns the appropriate CELL_OPEN_RESPONSE
func open_cell() -> CELL_OPEN_RESPONSE:
	if open:
		return CELL_OPEN_RESPONSE.OPEN_NUMBER
	if flagged:
		return CELL_OPEN_RESPONSE.FLAGGED
	
	open = true
	if bomb:
		return CELL_OPEN_RESPONSE.BOMB
	
	return CELL_OPEN_RESPONSE.OPEN_SAFE

func flag():
	if open:
		return
	flagged = not flagged

func set_reveal_state(clicked = false):
	if reveal:
		return
	reveal = true
	if bomb and clicked:
		reveal_state = REVEAL_STATE.BOMB_CLICK
	elif flagged and not bomb:
		reveal_state = REVEAL_STATE.BOMB_WRONG
	elif bomb:
		reveal_state = REVEAL_STATE.BOMB
	else:
		reveal_state = REVEAL_STATE.NUMBER

func set_bomb_neighbors(number : int):
	bomb_neighbors = number
